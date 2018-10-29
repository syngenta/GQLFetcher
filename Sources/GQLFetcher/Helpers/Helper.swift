//
//  Helper.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 02.10.2018.
//

public typealias GraphQLJSON = [String : Any?]

extension String {
    var jsonEscaped: String {
        return self.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "/", with: "\\/")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\u{8}", with: "\\b")
            .replacingOccurrences(of: "\u{12}", with: "\\f")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
