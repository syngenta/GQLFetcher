//
//  GraphQLRequestResult.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

import GQLSchema

public struct GraphQLResponse<T> {
    let operation: GraphQLOperation
    let data: T
    
    init(operation: GraphQLOperation, data: Any?) throws {
        guard let data = data as? T else {
            throw GraphQLResultError.differentTypes
        }
        self.operation = operation
        self.data = data
    }
    
    static func create(operations: [String : GraphQLOperation], data: GraphQLJSON) throws -> [GraphQLResponse<T>] {
        return try data.compactMap { (key, value) -> GraphQLResponse<T>? in
            guard let operation = operations[key] else {
                throw GraphQLResultError.noOperationForData(operations: operations, data: value)
            }
            return try GraphQLResponse<T>(operation: operation, data: value)
        }
    }
}

public protocol GraphQLResult {
    associatedtype Result
    init<Context: GraphQLContext>(responses: [GraphQLResponse<Result>], context: Context) throws
}
