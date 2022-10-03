//
//  GraphQLBody.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/22/18.
//

import Foundation
import GQLSchema

/// Struct that contains GraphQL request body
public struct GraphQLBody: CustomStringConvertible {

    let body: String
    let data: Data
    public let boundary: String? // boundary exist only for multipart request
    public var description: String { self.body }

    /// Initialiser **(Have some critical rules)**
    /// - Operations can't be with equal name. Use 'alias' for separating equal requests
    /// - Fragment can't duplicate. You must use fragments with different names
    ///
    /// - Parameters:
    ///   - operation: generic of **GraphQLOperation** from **GQLSchema** module, operation can be object of **GraphQLQuery** or **GraphQLMutation**
    ///   - variables: list of GraphQL variables that be in request body and  all this variables should be used in operations
    init(operation: GraphQLOperation..., variables: [GraphQLVariable] = []) throws {
        try self.init(operations: operation, variables: variables)
    }

    /// Initialiser **(Have some critical rules)**
    /// - 'operations' must contains 1 and more operations
    /// - Operations can't be with equal name. Use 'alias' for separating equal requests
    /// - Fragment can't duplicate. You must use fragments with different names
    ///
    /// - Parameters:
    ///   - operations: list of **GraphQLOperation** from **GQLSchema** module, operation can be object of **GraphQLQuery** or **GraphQLMutation**
    ///   - variables: list of GraphQL variables that be in request body and  all this variables should be used in operations
    ///   - boundary: boundary for multipart request, by default *UUID().uuidString*
    init(operations: [GraphQLOperation],
         variables: [GraphQLVariable] = [],
         boundary: String = UUID().uuidString) throws {

        guard let type = operations.first?.type else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "'operations' must contains 1 and more operations"
            )
        }

        let names = operations.map { $0.name }
        guard names.count == Set(names).count else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "Two or more operations with equal name. Use 'alias' to resolve this problem"
            )
        }

        let fragmentNames = operations.compactMap { $0.fragmentQuery?.name }
        guard fragmentNames.count == Set(fragmentNames).count else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "Fragment duplicates. You have two or more fragments with equal name"
            )
        }

        guard !variables.contains(where: { $0.value is [GraphQLFileType] }) else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "Library not support array of *GraphQLFileType*. You can upload by one file only"
            )
        }

        let declarations = variables.isEmpty ? "" : "(\(variables.map { $0.declaration }.joined(separator: ",")))"
        let fragments = operations.compactMap { $0.fragmentQuery?.body }.joined(separator: " ")
        let operation = operations.reduce("", { $0 + $1.body + " " })
        let query = "\(fragments) \(type)" + declarations + " { \(operation) }"
        guard let query = try? JSONEncoder().encode(query) else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "Failed to escape GraphQL query"
            )
        }
        guard let query = String(data: query, encoding: .utf8) else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "Failed to convert escaped query to String"
            )
        }

        let variablesBody = "{" + variables.map { $0.bodyValue }.joined(separator: ",") + "}"
        let body = #"{ "query" : \#(query), "variables": \#(variablesBody) }"#

        let files = variables.filter { $0.value is GraphQLFileType }
        if !files.isEmpty {
            do {
                var data = Data()
                try data.appendPart(body: body, name: "operations", boundary: boundary)
                let map = files.enumerated().map { #""\#($0.offset)": ["variables.\#($0.element.name)"]"# }
                try data.appendPart(
                    body: "{ \(map.joined(separator: ",")) }",
                    name: "map",
                    boundary: boundary
                )

                try files.enumerated().forEach {
                    guard let file = $0.element.value as? GraphQLFileType else { return }
                    try data.appendPart(
                        file: file,
                        name: "\($0.offset)",
                        boundary: boundary
                    )
                }
                try data.append("--\(boundary)--\r\n")

                self.body = body
                self.data = data
                self.boundary = boundary
            } catch {
                throw GraphQLResultError.bodyError(
                    operations: operations,
                    variables: variables,
                    error: "Multipart data error - \(error)"
                )
            }
        } else {
            guard let data = body.data(using: .utf8) else {
                throw GraphQLResultError.bodyError(
                    operations: operations,
                    variables: variables,
                    error: "Can't encode 'body' to 'data'"
                )
            }

            self.body = body
            self.data = data
            self.boundary = nil // should be nil for not multipart request
        }
    }
}
