//
//  GraphQLBody.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/22/18.
//

import Foundation
import GQLSchema

public struct GraphQLBody: CustomStringConvertible {
    
    let body: String
    let data: Data
    
    public var description: String {
        return self.body
    }
    
    init<O: GraphQLOperation>(operation: O...) {
        self.init(operations: operation)
    }
    
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
        let query = "\(fragments) \(type) { \(operation) }".jsonEscaped
        self.body = "{ \"query\" : \"\(query)\" }"
        
        guard let data = self.body.data(using: .utf8) else {
            fatalError("Can't encode 'body' to 'data'")
        }
        
        self.data = data
    }
}
