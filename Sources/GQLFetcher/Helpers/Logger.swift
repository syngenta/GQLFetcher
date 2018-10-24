//
//  Logger.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

import Foundation

struct Logger {
    static func `deinit`(file: String = #file, _ any: Any) {
        if Environment.debugLoging {
            let file = URL(fileURLWithPath: file).lastPathComponent
            print("🔵 Deinit \(file) - \(any)")
        }
    }
}
