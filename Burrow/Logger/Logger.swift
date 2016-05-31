//
//  Logger.swift
//  Burrow
//
//  Created by Jaden Geller on 5/20/16.
//
//

import Foundation

public final class Logger {
    public let name: String?
    private var minimumSeverity: Severity?
    
    private func post(message: String) {
        NSLog((name ?? "Global") + ": " + message)
    }
    
    public func error(@autoclosure message: () -> String) {
        guard minimumSeverity >= .error else { return }
        post(message())
    }
    public func warning(@autoclosure message: () -> String) {
        guard minimumSeverity >= .warning else { return }
        post(message())
    }
    public func info(@autoclosure message: () -> String) {
        guard minimumSeverity >= .info else { return }
        post(message())
    }
    public func debug(@autoclosure message: () -> String) {
        guard minimumSeverity >= .debug else { return }
        post(message())
    }
    public func verbose(@autoclosure message: () -> String) {
        guard minimumSeverity >= .verbose else { return }
        post(message())
    }
    
    private init(named name: String?) {
        self.name = name
        self.minimumSeverity = Logger.defaultMinimumSeverity
    }
}

extension Logger {
    public enum Severity: Int, Comparable {
        case error
        case warning
        case info
        case debug
        case verbose
    }
}

public func ==(lhs: Logger.Severity, rhs: Logger.Severity) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func <(lhs: Logger.Severity, rhs: Logger.Severity) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

extension Logger {
    public typealias Channel = String -> ()
    private static let ignore: Channel = { _ in }
    private static let output: Channel = { message in NSLog(message) }
}

extension Logger {
    public func disable() {
        self.minimumSeverity = nil
    }
    
    public func enable(minimumSeverity severity: Severity) {
        self.minimumSeverity = severity
    }
}

public let log = Logger(named: nil)

extension Logger {
    public private(set) static var loggers: [String : Logger] = [:]
    public static func category(name: String) -> Logger {
        if let logger = loggers[name] {
            return logger
        } else {
            let logger = Logger(named: name)
            loggers[name] = logger
            if let severity = defaultMinimumSeverity {
                logger.enable(minimumSeverity: severity)
            }
            return logger
        }
    }
    
    public static var defaultMinimumSeverity: Severity? = .warning
    public static func enable(minimumSeverity severity: Severity) {
        defaultMinimumSeverity = severity
        log.enable(minimumSeverity: severity)
        loggers.values.forEach { $0.enable(minimumSeverity: severity) }
    }
    
    public static func disable() {
        defaultMinimumSeverity = nil
        log.disable()
        loggers.values.forEach { $0.disable() }
    }
}

extension Logger {
    public func caught<T>(fatal: Bool = true, @noescape block: () throws -> T) -> T {
        do {
            return try block()
        } catch let error {
            log.error("Unrecoverable error: \(error)")
            fatalError()
        }
    }
}
