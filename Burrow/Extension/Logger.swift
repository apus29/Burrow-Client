//
//  Logger.swift
//  Burrow
//
//  Created by Jaden Geller on 5/17/16.
//
//

import Foundation

public struct AppleSystemLog: OutputStreamType {
    private init() { }
    public static var stream = AppleSystemLog()
    public func write(string: String) { NSLog(string) }
}

let verbose = true

func log(message: String, requiresVerbose: Bool = false) {
    guard verbose || !requiresVerbose else { return }
    print(message, toStream: &AppleSystemLog.stream)
}