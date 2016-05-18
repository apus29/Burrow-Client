//
//  NetDBErrorCode.swift
//  Burrow
//
//  Created by Mimi Jiao on 5/17/16.
//
//

public let NetDBErrorDomain = "NetDBErrorDomain"

extension NSError {
    static func posixError() -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
    }
    
    static func netDBError() -> NSError? {
        guard let code = NetDBErrorCode(rawValue: h_errno) else {
            return nil
        }
        guard code != .`internal` else {
            return NSError.posixError()
        }
        return NSError(domain: NetDBErrorDomain, code: Int(code.rawValue), userInfo: [
            NSLocalizedDescriptionKey : code.description
        ])
    }
}

public enum NetDBErrorCode {
    case `internal`
    case hostNotFound
    case tryAgain
    case noRecovery
    case noData
    case noAddress
}

extension NetDBErrorCode: RawRepresentable {
    public init?(rawValue: Int32) {
        switch rawValue {
        case NETDB_INTERNAL:
            self = .`internal`
        case HOST_NOT_FOUND:
            self = .hostNotFound
        case TRY_AGAIN:
            self = .tryAgain
        case NO_RECOVERY:
            self = .noRecovery
        case NO_DATA:
            self = .noData
        case NO_ADDRESS:
            self = .noAddress
        default:
            return nil
        }
    }
    
    public var rawValue: Int32 {
        switch self {
        case .`internal`:
            return NETDB_SUCCESS
        case .hostNotFound:
            return HOST_NOT_FOUND
        case .tryAgain:
            return TRY_AGAIN
        case .noRecovery:
            return NO_RECOVERY
        case .noData:
            return NO_RECOVERY
        case .noAddress:
            return NO_ADDRESS
        }
    }
}

extension NetDBErrorCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .`internal`:
            return "Internal"
        case .hostNotFound:
            return "HostNotFound"
        case .tryAgain:
            return "TryAgain"
        case .noRecovery:
            return "NoRecovery"
        case .noData:
            return "NoData"
        case .noAddress:
            return "NoAddress"
        }
    }
}
