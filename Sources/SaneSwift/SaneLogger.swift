//
//  SaneLogger.swift
//  Backlit
//
//  Created by Stanislas Chevallier on 30/01/19.
//  Copyright (c) 2019 Syan. All rights reserved.
//

import Foundation

public struct SaneLogger {
    private init() {}

    // MARK: Level
    public enum Level: Int, Comparable, CustomStringConvertible {
        case debug = 0, info = 1, warning = 2, error = 3
        
        public var description: String {
            switch self {
            case .debug:    return "Debug"
            case .info:     return "Info"
            case .warning:  return "Warning"
            case .error:    return "Error"
            }
        }

        public static func < (lhs: SaneLogger.Level, rhs: SaneLogger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: External logging
    public static var externalLoggingMethod: ((Level, String) -> ())?
    
    // MARK: Internal methods
    internal static func log(level: Level, _ message: String) {
        if let externalLoggingMethod {
            externalLoggingMethod(level, message)
        }
        else {
            print("[SANE/\(level.description)] \(message)")
        }
    }
    
    internal static func d(_ message: String) {
        log(level: .debug, message)
    }

    internal static func i(_ message: String) {
        log(level: .info, message)
    }
    
    internal static func w(_ message: String) {
        log(level: .warning, message)
    }

    internal static func e(_ message: String) {
        log(level: .error, message)
    }
}

