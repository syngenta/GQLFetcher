//
//  File.swift
//  GQLFetcher
//
//  Created by Evegeny Kalashnikov on 03.10.2022.
//

import Foundation
import GQLSchema

/// Data extension for multipart request
internal extension Data {

    mutating func append(_ string: String) throws {
        enum E: Error { case errorDataAppending(string: String) }
        guard let data = string.data(using: .utf8) else { throw E.errorDataAppending(string: string) }
        self.append(data)
    }

    mutating func appendPart(body: String, name: String, boundary: String) throws {
        try append("--\(boundary)\r\n")
        try append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        try append("\r\n")
        try append(body)
        try append("\r\n")
    }

    mutating func appendPart(file: GraphQLFileType, name: String, boundary: String) throws {
        try append("--\(boundary)\r\n")
        try append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\r\n")
        try append("Content-Type: \(file.contentType)\r\n")
        try append("\r\n")
        append(file.binary)
        try append("\r\n")
    }
}
