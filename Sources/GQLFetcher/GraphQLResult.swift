//
//  GraphQLRequestResult.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

import GQLSchema

public struct GraphQLResponse<T> {
    public let operation: GraphQLOperation
    public let data: T
    
    public init (operation: GraphQLOperation, data: T, body: GraphQLBody) {
        self.operation = operation
        self.data = data
    }
    
    init(operation: GraphQLOperation, data: Any?, body: GraphQLBody) throws {
        guard let data = data as? T else {
            throw GraphQLResultError.differentTypes
        }
        self.init(operation: operation, data: data, body: body)
    }
    
    static func create(operations: [String: GraphQLOperation],
                       data: GraphQLJSON,
                       body: GraphQLBody) throws -> [String : GraphQLResponse<T>] {

        return try operations.mapValues { (operation) -> GraphQLResponse<T> in
            guard let _data = data[operation.name] else {
                throw GraphQLResultError.noOperationForData(operations: operations, data: data)
            }
            return try GraphQLResponse<T>(operation: operation, data: _data, body: body)
        }
    }
}

public protocol GraphQLResult {
    associatedtype Result
    /// responses key - 'Operation name'
    init(responses: [String : GraphQLResponse<Result>], context: GraphQLContext) throws
}

public protocol GraphQLAdditionalResult: GraphQLResult {
    associatedtype Additional
    /// responses key - 'Operation name'
    init(responses: [String : GraphQLResponse<Result>], context: GraphQLContext, additional: Additional) throws
}
