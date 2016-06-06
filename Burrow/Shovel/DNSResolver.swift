//
//  DNSResolver.swift
//  Burrow
//
//  Created by Jaden Geller on 5/28/16.
//
//

import DNSServiceDiscovery
import Logger

extension Logger { public static let dnsResolverCategory = "DNSResolver" }
private let log = Logger.category(Logger.dnsResolverCategory)

private let timeoutDuration = 60.0 // seconds

enum DNSResolveError: ErrorType {
    case queryFailure(DNSServiceErrorCode)
    case parseFailure(NSData)
    case countParseFailure(String)
    case timeout
    case tooManyRetries
}

private struct QueryInfo {
    var service: DNSServiceRef
    var socket: CFSocketRef!
    var socketSource: CFRunLoopSourceRef!
    var records: Result<[TXTRecord]>
    var responseHandler: Result<[TXTRecord]> -> ()
    var totalPacketCount: Int?
    var timer: CFRunLoopTimer!
}

extension QueryInfo {
    func performCleanUp() {
        log.verbose("Cleaning up resources for query with socket: \(socket)")
        
        // Remove socket listener from run look, destory socket, and deallocate service
        CFRunLoopSourceInvalidate(socketSource)
        CFRunLoopTimerInvalidate(timer)
        CFSocketInvalidate(socket)
        DNSServiceRefDeallocate(service)
    }
}

private func queryCallback(
    sdref: DNSServiceRef,
    flags: DNSServiceFlags,
    interfaceIndex: UInt32,
    errorCode: DNSServiceErrorType,
    fullname: UnsafePointer<Int8>,
    rrtype: UInt16,
    rrclass: UInt16,
    rdlen: UInt16,
    rdata: UnsafePointer<Void>,
    ttl: UInt32,
    context: UnsafeMutablePointer<Void>
) {
    
    log.debug("Callback for query \(sdref)")
    let queryContext = UnsafeMutablePointer<QueryInfo>(context)
    
    do {
        if let errorCode = DNSServiceErrorCode(rawValue: Int(errorCode)) {
            throw DNSResolveError.queryFailure(errorCode)
        }
        
        // Parse the TXT record
        let txtBuffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(rdata), count: Int(rdlen))
        guard let txtRecord = TXTRecord(buffer: txtBuffer) else {
            throw DNSResolveError.parseFailure(NSData(bytes: rdata, length: Int(rdlen)))
        }
        
        log.info("Received TXT record \(txtRecord) from domain \(String(CString: UnsafePointer(fullname), encoding: NSUTF8StringEncoding))")

        // Check if this is a special "count" TXT record that indicates the total number of records
        // that we ought to receive for this query. Note that this is a workaround due to the limitations
        // of the DNS Service Discovery library, and it would be better if the library exposed the count
        // itself as this is in the answer.
        if case ("$count", let value)? = txtRecord.attribute {
            if let count = Int(value) {
                queryContext.memory.totalPacketCount = count
            } else {
                throw DNSResolveError.countParseFailure(value)
            }
        } else {
            log.precondition(queryContext.memory.records.error == nil)
            queryContext.memory.records.mutate { array in
                array.append(txtRecord)
            }
        }
    } catch let error {
        queryContext.memory.records = .Failure(error)
        queryContext.memory.performCleanUp()
    }
}

private func querySocketCallback(
    socket: CFSocket!,
    callbackType: CFSocketCallBackType,
    address: CFData!,
    data: UnsafePointer<Void>,
    info: UnsafeMutablePointer<Void>
) {
    log.debug("Socket callback for context with address \(info)")

    log.precondition(callbackType == .ReadCallBack)
    log.verbose("Callback of type \(callbackType) on socket: \(socket)")
    let queryContext = UnsafeMutablePointer<QueryInfo>(info)
    log.verbose("Current context is \(queryContext.memory)")
    log.precondition(socket === queryContext.memory.socket)
    
    // Process the result
    log.verbose("Processing result for socket: \(socket)")
    let status = DNSServiceProcessResult(queryContext.memory.service)
    
    queryContext.memory.records.mutate { _ in
        if let errorCode = DNSServiceErrorCode(rawValue: Int(status)) {
            queryContext.memory.performCleanUp()
            throw DNSResolveError.queryFailure(errorCode)
        }
    }
    
    // Ensure that we wait for all the records we expect to receive.
    if case .Success(let records) = queryContext.memory.records {
        guard records.count == queryContext.memory.totalPacketCount else { return }
        queryContext.memory.performCleanUp()
    }
    
    log.debug("Freeing context with address \(info)")
    queryContext.memory.responseHandler(queryContext.memory.records)
    queryContext.destroy()
    queryContext.dealloc(1)

}

private func timerCallback(timer: CFRunLoopTimer!, info: UnsafeMutablePointer<Void>) {
    log.debug("Timer callback for context with address \(info)")
    let queryContext = UnsafeMutablePointer<QueryInfo>(info)

    log.debug("Freeing context with address \(info)")
    queryContext.memory.responseHandler(Result {
        throw DNSResolveError.timeout
    })
    queryContext.memory.performCleanUp()
    queryContext.destroy()
    queryContext.dealloc(1)
}

class DNSResolver {
    private init() { }
    
    /// Query a domain's TXT records asynchronously
    static func resolveTXT(domain: Domain, retryCount: Int = 3) throws -> Future<Result<[TXTRecord]>> {
        guard retryCount > 0 else { throw DNSResolveError.tooManyRetries }
        return try _resolveTXT(domain).recover { error in
            log.info("Retrying query with \(retryCount) tries left: \(domain)")
            return try resolveTXT(domain, retryCount: retryCount - 1)
        }
    }
    
    static func _resolveTXT(domain: Domain) throws -> Future<Result<[TXTRecord]>> {
        return try Future { resolve in
            log.debug("Will resolve domain `\(domain)`")
            
            // Create space on the heap for the context
            let queryContext = UnsafeMutablePointer<QueryInfo>.alloc(1)
            queryContext.initialize(QueryInfo(
                service: nil,
                socket: nil,
                socketSource: nil,
                records: .Success([]),
                responseHandler: resolve,
                totalPacketCount: nil,
                timer: nil
            ))
            
            // Create DNS Query
            var service: DNSServiceRef = nil
            let status = String(domain).withCString { fullname in
                DNSServiceQueryRecord(
                    /* serviceRef: */ &service,
                    /* flags: */ 0,
                    /* interfaceIndex: */ 0,
                    /* fullname: */ fullname,
                    /* rrtype: */ UInt16(kDNSServiceType_TXT),
                    /* rrclass: */ UInt16(kDNSServiceClass_IN),
                    /* callback: */ queryCallback,
                    /* context: */ queryContext
                )
            }
            if let errorCode = DNSServiceErrorCode(rawValue: Int(status)) {
                throw DNSResolveError.queryFailure(errorCode)
            }
            
            log.precondition(service != nil)
            queryContext.memory.service = service
            log.verbose("Created DNS query \(service) to domain `\(domain)`")
            
            // Create socket to query
            var socketContext = CFSocketContext(
                version: 0,
                info: queryContext,
                retain: nil,
                release: nil,
                copyDescription: nil
            )
            let socketIdentifier = DNSServiceRefSockFD(service)
            log.precondition(socketIdentifier >= 0)
            let socket = CFSocketCreateWithNative(
                /* allocator: */ nil,
                /* socket: */ socketIdentifier,
                /* callbackTypes: */ CFSocketCallBackType.ReadCallBack.rawValue,
                /* callout: */ querySocketCallback,
                /* context: */ &socketContext
            )

            queryContext.memory.socket = socket
            log.verbose("Created socket for query to domain `\(domain)`: \(socket)")
            
            // Add socket listener to run loop
            let socketSource = CFSocketCreateRunLoopSource(
                /* allocator: */ nil,
                /* socket: */ socket,
                /* order: */ 0
            )

            queryContext.memory.socketSource = socketSource
            CFRunLoopAddSource(CFRunLoopGetMain(), socketSource, kCFRunLoopDefaultMode)
            log.verbose("Added run loop source \(socketSource) for query to domain `\(domain)`")
            
            // Add timeout timer to run loop
            var timerContext = CFRunLoopTimerContext(
                version: 0,
                info: queryContext,
                retain: nil,
                release: nil,
                copyDescription: nil
            )
            let timer = CFRunLoopTimerCreate(
                /* allocator: */ nil,
                /* fireDate: */ CFAbsoluteTimeGetCurrent() + timeoutDuration,
                /* interval: */ 0,
                /* flags: */ 0,
                /* order: */ 0,
                /* callout: */ timerCallback,
                /* context: */ &timerContext
            )
            queryContext.memory.timer = timer
            CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopDefaultMode)
        }
    }
}