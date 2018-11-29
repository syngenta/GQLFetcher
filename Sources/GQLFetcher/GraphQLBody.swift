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
    
    public var description: String {
        return self.body
    }
    
    /// Initializer **(Have some critical rulest)**
    /// - Operations can't be with equal name. Use 'alias' for separating equal requests
    /// - Fragment can't duplicate. You must use fragments with different names
    ///
    /// - Parameters:
    ///   - operation: generic of **GraphQLOperation** from **GQLSchema** module, operation can be object of **GraphQLQuery** or **GraphQLMutation**
    init<O: GraphQLOperation>(operation: O...) {
        self.init(operations: operation)
    }
    
    /// Initializer **(Have some critical rulest)**
    /// - 'operations' must containes 1 and more operations
    /// - Operations can't be with equal name. Use 'alias' for separating equal requests
    /// - Fragment can't duplicate. You must use fragments with different names
    ///
    /// - Parameters:
    ///   - operations: generic of **GraphQLOperation** from **GQLSchema** module, operation can be object of **GraphQLQuery** or **GraphQLMutation**
    init<O: GraphQLOperation>(operations: [O]) {
        guard let type = operations.first?.type else {
            fatalError("'operations' must containes 1 and more operations")
        }
        
        let names = operations.map { $0.name }
        guard names.count == Set(names).count else {
            fatalError("Two or more operations with equal name. Use 'alias' to resolve this problem")
        }
        
        let fragmentNames = operations.compactMap { $0.fragmentQuery?.name }
        guard fragmentNames.count == Set(fragmentNames).count else {
            fatalError("Fragment dublicates. You have two or more fragments with equal name")
        }
        
        let fragments = operations.compactMap { $0.fragmentQuery?.body }.joined(separator: " ")
        let operation = operations.reduce("", { $0 + $1.body + " " })
        let query = "\(fragments) \(type) { \(operation) }"
        self.body = "{ \"query\" : \"\(query)\" }"
        guard let data = try? JSONSerialization.data(withJSONObject: ["query" : query]) else {
            fatalError("Can't encode 'body' to 'data'")
        }
        self.data = data
    }
}
