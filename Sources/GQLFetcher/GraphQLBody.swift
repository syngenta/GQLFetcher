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
    init(operations: [GraphQLOperation], variables: [GraphQLVariable] = []) throws {
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

        guard let data = body.data(using: .utf8) else {
            throw GraphQLResultError.bodyError(
                operations: operations,
                variables: variables,
                error: "Can't encode 'body' to 'data'"
            )
        }

        self.body = body
        self.data = data
    }
}
