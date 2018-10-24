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
        guard let type = operations.first?.queryType else {
            fatalError("'operations' must containes 1 and more operations")
        }
        
        let fragments_ = operations.reduce([String : String]()) { (dictionary, operation) -> [String : String] in
            var dictionary = dictionary
            if let fragment = operation.fragmentQuery {
                if dictionary[fragment.name] == nil {
                    dictionary[fragment.name] = fragment.body
                } else {
                    fatalError("Fragment dublicates. You have two or more fragments with equal name")
                }
            }
            return dictionary
        }
        let fragments = fragments_.values.reduce("", { $0 + $1 + " " })
        let query = operations.reduce("", { $0 + $1.body + " " })
        
        self.body = "\(fragments) \(type) { \(query) }"
        
        guard let data = self.body.data(using: .utf8) else {
            fatalError("Can't encode 'body' to 'data'")
        }
        
        self.data = data
    }
}
