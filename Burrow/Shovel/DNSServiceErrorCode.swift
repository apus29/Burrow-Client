//
//  DNSServiceErrorCode.swift
//  Burrow
//
//  Created by Jaden Geller on 5/29/16.
//
//

import DNSServiceDiscovery

public let DNSServiceErrorDomain = "DNSServiceErrorDomain"

public enum DNSServiceErrorCode {
    case unknown
    case noSuchName
    case noMemory
    case badParam
    case badReference
    case badState
    case badFlags
    case unsupported
    case notInitialized
    case alreadyRegistered
    case nameConflict
    case invalid
    case firewall
    case incompatible
    case badInterfaceIndex
    case refused
    case noSuchRecord
    case noAuth
    case noSuchKey
    case natTraversal
    case doubleNat
    case badTime
    case badSig
    case badKey
    case transient
    case serviceNotRunning
    case natPortMappingUnsupported
    case natPortMapppingDisabled
    case noRouter
    case pollingMode
    case timeout
}

extension DNSServiceErrorCode: RawRepresentable {
    public init?(rawValue: Int) {
        switch rawValue {
        case kDNSServiceErr_Unknown:
            self = unknown
        case kDNSServiceErr_NoSuchName:
            self = noSuchName
        case kDNSServiceErr_NoMemory:
            self = noMemory
        case kDNSServiceErr_BadParam:
            self = badParam
        case kDNSServiceErr_BadReference:
            self = badReference
        case kDNSServiceErr_BadState:
            self = badState
        case kDNSServiceErr_BadFlags:
            self = badFlags
        case kDNSServiceErr_Unsupported:
            self = unsupported
        case kDNSServiceErr_NotInitialized:
            self = notInitialized
        case kDNSServiceErr_AlreadyRegistered:
            self = alreadyRegistered
        case kDNSServiceErr_NameConflict:
            self = nameConflict
        case kDNSServiceErr_Invalid:
            self = invalid
        case kDNSServiceErr_Firewall:
            self = firewall
        case kDNSServiceErr_Incompatible:
            self = incompatible
        case kDNSServiceErr_BadInterfaceIndex:
            self = badInterfaceIndex
        case kDNSServiceErr_Refused:
            self = refused
        case kDNSServiceErr_NoSuchRecord:
            self = noSuchRecord
        case kDNSServiceErr_NoAuth:
            self = noAuth
        case kDNSServiceErr_NoSuchKey:
            self = noSuchKey
        case kDNSServiceErr_NATTraversal:
            self = natTraversal
        case kDNSServiceErr_DoubleNAT:
            self = doubleNat
        case kDNSServiceErr_BadTime:
            self = badTime
        case kDNSServiceErr_BadSig:
            self = badSig
        case kDNSServiceErr_BadKey:
            self = badKey
        case kDNSServiceErr_Transient:
            self = transient
        case kDNSServiceErr_ServiceNotRunning:
            self = serviceNotRunning
        case kDNSServiceErr_NATPortMappingUnsupported:
            self = natPortMappingUnsupported
        case kDNSServiceErr_NATPortMappingDisabled:
            self = natPortMapppingDisabled
        case kDNSServiceErr_NoRouter:
            self = noRouter
        case kDNSServiceErr_PollingMode:
            self = pollingMode
        case kDNSServiceErr_Timeout:
            self = timeout
        default:
            return nil
        }
    }
    
    public var rawValue: Int {
        switch self {
        case unknown:
            return kDNSServiceErr_Unknown
        case noSuchName:
            return kDNSServiceErr_NoSuchName
        case noMemory:
            return kDNSServiceErr_NoMemory
        case badParam:
            return kDNSServiceErr_BadParam
        case badReference:
            return kDNSServiceErr_BadReference
        case badState:
            return kDNSServiceErr_BadState
        case badFlags:
            return kDNSServiceErr_BadFlags
        case unsupported:
            return kDNSServiceErr_Unsupported
        case notInitialized:
            return kDNSServiceErr_NotInitialized
        case alreadyRegistered:
            return kDNSServiceErr_AlreadyRegistered
        case nameConflict:
            return kDNSServiceErr_NameConflict
        case invalid:
            return kDNSServiceErr_Invalid
        case firewall:
            return kDNSServiceErr_Firewall
        case incompatible:
            return kDNSServiceErr_Incompatible
        case badInterfaceIndex:
            return kDNSServiceErr_BadInterfaceIndex
        case refused:
            return kDNSServiceErr_Refused
        case noSuchRecord:
            return kDNSServiceErr_NoSuchRecord
        case noAuth:
            return kDNSServiceErr_NoAuth
        case noSuchKey:
            return kDNSServiceErr_NoSuchKey
        case natTraversal:
            return kDNSServiceErr_NATTraversal
        case doubleNat:
            return kDNSServiceErr_DoubleNAT
        case badTime:
            return kDNSServiceErr_BadTime
        case badSig:
            return kDNSServiceErr_BadSig
        case badKey:
            return kDNSServiceErr_BadKey
        case transient:
            return kDNSServiceErr_Transient
        case serviceNotRunning:
            return kDNSServiceErr_ServiceNotRunning
        case natPortMappingUnsupported:
            return kDNSServiceErr_NATPortMappingUnsupported
        case natPortMapppingDisabled:
            return kDNSServiceErr_NATPortMappingDisabled
        case noRouter:
            return kDNSServiceErr_NoRouter
        case pollingMode:
            return kDNSServiceErr_PollingMode
        case timeout:
            return kDNSServiceErr_Timeout
        }
    }
}
