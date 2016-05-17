//
//  NetDBErrorCode.swift
//  Burrow
//
//  Created by Mimi Jiao on 5/17/16.
//
//

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
