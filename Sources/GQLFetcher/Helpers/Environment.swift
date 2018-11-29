//
//  Environment.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

class Environment {
    
    enum Key: String {
        case debugLoging = "GQL_FETCHER_DEBUG_LOGING"
    }
    
    static var debugLoging: Bool {
        return Environment.shared[.debugLoging] != nil
    }

    static let shared = Environment()
    
    subscript(key: Key) -> String? {
        set {
            if let newValue = newValue {
                setenv(key.rawValue, newValue, 1)
            } else {
                unsetenv(key.rawValue)
            }
        }
        get {
            if let cString = getenv(key.rawValue) {
                return String(cString: cString)
            }
            return nil
        }
    }
}
