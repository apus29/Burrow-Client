//
//  DNSResolver.swift
//  Burrow
//
//  Created by Jaden Geller on 5/28/16.
//
//

import DNSServiceDiscovery

enum DNSResolveError: ErrorType {
    case queryFailure(DNSServiceErrorType)
    case parseFailure(NSData)
}

private struct QueryInfo {
    var service: DNSServiceRef
    var socket: CFSocketRef!
    var runLoopSource: CFRunLoopSourceRef!
    var records: [Result<TXTRecord>]
    var responseHandler: Result<[TXTRecord]> -> ()
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
    let queryContext = UnsafeMutablePointer<QueryInfo>(context)
    
    // Append record rresult
    queryContext.memory.records.append(Result {
        
        // Parse the TXT record
        let txtBuffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(rdata), count: Int(rdlen))
        guard let txtRecord = TXTRecord(buffer: txtBuffer) else {
            throw DNSResolveError.parseFailure(NSData(bytes: rdata, length: Int(rdlen)))
        }
        return txtRecord
    })
}

private func querySocketCallback(
    socket: CFSocket!,
    callbackTime: CFSocketCallBackType,
    address: CFData!,
    data: UnsafePointer<Void>,
    info: UnsafeMutablePointer<Void>
) {
    let queryContext = UnsafeMutablePointer<QueryInfo>(info)
    defer {
        // Clean up resources
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), queryContext.memory.runLoopSource, kCFRunLoopDefaultMode)
        CFSocketInvalidate(queryContext.memory.socket)
        DNSServiceRefDeallocate(queryContext.memory.service)
        queryContext.destroy()
        queryContext.dealloc(1)
        // TODO: Is stuff leaking?
    }
    
    // Close the socket
    assert(socket === queryContext.memory.socket)
    CFSocketInvalidate(socket)
    
    // Process the result
    let serviceRef = DNSServiceRef(info)
    let error = DNSServiceProcessResult(serviceRef)
    
    // Respond to the caller
    queryContext.memory.responseHandler(Result {
        if error != DNSServiceErrorType(kDNSServiceErr_NoError) {
            throw DNSResolveError.queryFailure(error)
        } else {
            return try queryContext.memory.records.map { try $0.unwrap() }
        }
    })
}

class DNSResolver {
    private init() { }
    
    /// Query a domain's TXT records asynchronously
    static func resolveTXT(domain: Domain, responseHandler: Result<[TXTRecord]> -> ()) {
        let domainData = String(domain).dataUsingEncoding(NSUTF8StringEncoding)!
        
        // Create space on the heap for the context
        let queryContext = UnsafeMutablePointer<QueryInfo>.alloc(1)
        queryContext.initialize(QueryInfo(
            service: nil,
            socket: nil,
            runLoopSource: nil,
            records: [],
            responseHandler: responseHandler
        ))
        
        // Create DNS Query
        var service: DNSServiceRef = nil
        DNSServiceQueryRecord(
            /* serviceRef: */ &service,
            /* flags: */ 0,
            /* interfaceIndex: */ 0,
            /* fullname: */ UnsafePointer<Int8>(domainData.bytes),
            /* rrtype: */ UInt16(kDNSServiceType_TXT),
            /* rrclass: */ UInt16(kDNSServiceClass_IN),
            /* callback: */ queryCallback,
            /* context: */ queryContext
        )
        queryContext.memory.service = service
        
        // Create socket to query
        var socketContext = CFSocketContext(
            version: 0,
            info: queryContext,
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let socket = CFSocketCreateWithNative(
            /* allocator: */ nil,
            /* socket: */ DNSServiceRefSockFD(service),
            /* callbackTypes: */ CFSocketCallBackType.ReadCallBack.rawValue,
            /* callout: */ querySocketCallback,
            /* context: */ &socketContext
        )
        // TODO: Is this socket retained here? If not, it crashes. If so, it leaks.
        queryContext.memory.socket = socket
        
        // Add socket listener to run loop
        let runLoopSource = CFSocketCreateRunLoopSource(
            /* allocator: */ nil,
            /* socket: */ socket,
            /* order: */ 0
        )
        // TODO: Is this run loop retained here? If not, it crashes. If so, it leaks.
        queryContext.memory.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopDefaultMode)
    }
}