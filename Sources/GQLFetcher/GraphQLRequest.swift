//
//  GraphQLRequest.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import PromiseKit
import GQLSchema

public class GraphQLRequest<Result: GraphQLRequestResult> {
    
    public let body: GraphQLBody
    
    private var isQueue = false
    private lazy var queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.lumyk.GQLFetcher.GraphQLRequest-\(self)"
        q.maxConcurrentOperationCount = 1
        self.isQueue = true
        return q
    }()
    private weak var task: GraphQLTask?
    
    public init<O: GraphQLOperation>(operations: [O]) {
        self.body = GraphQLBody(operations: operations)
    }
    
    public convenience init<O: GraphQLOperation>(operation operations: O...) {
        self.init(operations: operations)
    }
    
    deinit {
        Logger.deinit(self)
    }
    
    @discardableResult
    public func cancel() -> Bool {
        if self.isQueue {
            print( self.queue.operations)
            self.queue.cancelAllOperations()
            return true
        }
        if let task = self.task {
            task.cancel()
            return true
        }
        return false
    }
    
    public func perform<Context: GraphQLContext>(context: Context, queue: OperationQueue? = nil, success: @escaping (Result) -> Void, failure: @escaping (GraphQLRequestError) -> Void) {
        let queue = queue ?? self.queue
        
        let fetch = Promise<GraphQLJSON> { resolver in
            let operation = GraphQLTask(body: self.body, context: context, resolver: resolver)
            self.task = operation
            queue.addOperation(operation)
        }
        
        fetch.then { data -> Promise<Result> in
            if let errors = data["errors"] as? [GraphQLJSON] {
                let errors = errors.compactMap { GraphQLError(data: $0) }
                throw GraphQLResultError.graphQLErrors(errors: errors)
            }
            
            guard let _data = data["data"] as? GraphQLJSON else {
                throw GraphQLResultError.resultError(data: data)
            }
            do {
                return try Promise.value(Result(data: _data, context: context))
            } catch let error {
                throw GraphQLResultError.resultMappingError(data: _data, error: error)
            }
            }.done {
                success($0)
            }.catch {
                failure(GraphQLRequestError(error: $0, body: self.body))
        }
    }
    
    public func perform<Context: GraphQLContext>(context: Context, queue: OperationQueue? = nil) -> Promise<Result> {
        return Promise { resolver in
            self.perform(context: context, queue: queue, success: {
                resolver.fulfill($0)
            }, failure: {
                resolver.reject($0)
            })
        }
    }
}
