//
//  Logger.swift
//  Burrow
//
//  Created by Jaden Geller on 5/17/16.
//
//

import Foundation

let verbose = true

protocol Loggable {
    var logText: String { get }
    var requiresVerbose: Bool { get }
}

extension String: Loggable {
    var logText: String {
        return self
    }
    
    var requiresVerbose: Bool {
        return false
    }
}

func verbose(_ string: String) -> Loggable {
    return LogMessage.verbose(string)
}

enum LogMessage: Loggable {
    case normal(String)
    case verbose(String)
    
    var logText: String {
        switch self {
        case let .normal(text):  return text
        case let .verbose(text): return text
        }
    }
    
    var requiresVerbose: Bool {
        switch self {
        case .normal:  return false
        case .verbose: return true
        }
    }
}

func log(messages: Loggable..., separator: String = " ", terminator: String = "\n") {
    var fullMessage = ""
    var first = true
    for messageSegment in messages {
        guard verbose || !messageSegment.requiresVerbose else { continue }
        if first { first = false }
        else { fullMessage += separator }
        fullMessage += messageSegment.logText
    }
    fullMessage += terminator
    NSLog(fullMessage)
}


