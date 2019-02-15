//
//  GraphQLRequest.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import PromiseKit
import GQLSchema

/// - Class for describing and getting GraphQL data
/// - Use generic **Result**, protocol of **GraphQLResult**
public class GraphQLRequest<Result: GraphQLResult> {
    
    public let body: GraphQLBody
    
    private var isQueue = false
    private lazy var queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.lumyk.GQLFetcher.GraphQLRequest-\(self)"
        q.maxConcurrentOperationCount = 1
        self.isQueue = true
        return q
    }()
    private var task: GraphQLTask?
    
    /// Dictionary where key - operation *name*, value - **GraphQLOperation** object
    private var operations: [String : GraphQLOperation]
    
    /// Initializer of **GraphQLRequest**
    ///
    /// - Parameter operation: list of operations (generic protocol of **GraphQLOperation**)
    public init<O: GraphQLOperation>(operations: [O]) {
        self.body = GraphQLBody(operations: operations)
        self.operations = Dictionary(uniqueKeysWithValues: operations.map { ($0.name, $0) })
    }
    
    /// Initializer of **GraphQLRequest**
    ///
    /// - Parameter operation: operations (generic protocol of **GraphQLOperation**)
    public convenience init<O: GraphQLOperation>(operation operations: O...) {
        self.init(operations: operations)
    }
    
    /// Closure with default **Result** initializer (Can be changed for another **Result** protocols, like **GraphQLAdditionalResult**)
    var result: ([String : GraphQLResponse<Result.Result>], GraphQLContext) throws -> Result = {
        try Result(responses: $0, context: $1)
    }
    
    deinit {
        Logger.deinit(self)
    }
    
    /// Function for canceling operation after running
    ///
    /// - Returns: Returns *true* — if possible to stop operations, and *false* — if not
    @discardableResult
    public func cancel() -> Bool {
        if self.isQueue {
            self.queue.cancelAllOperations()
            return true
        }
        if let task = self.task {
            task.cancel()
            return true
        }
        return false
    }
}

// MARK: - Additional Result extension
public extension GraphQLRequest where Result: GraphQLAdditionalResult {
    
    /// Function for adding additional to request result
    ///
    /// - Parameter value: Additional value (You can use any type you want, for this you must specify Additional typedef in your result)
    /// - Returns: Returns request(self)
    public func add(_ value: Result.Additional) -> Self {
        self.result = { try Result(responses: $0, context: $1, additional: value) }
        return self
    }
}

// MARK: - Performs
public extension GraphQLRequest {
    
    ///  Will run performation with closure result
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///   - success: Closure with success result(generic protocol of **GraphQLResult**)
    ///   - failure: Closure with failure result(error struct **GraphQLRequestError**)
    public func perform(context: GraphQLContext, queue: OperationQueue? = nil, success: @escaping (Result) -> Void, failure: @escaping (GraphQLRequestError) -> Void) {
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
            
            let responses = try GraphQLResponse<Result.Result>.create(operations: self.operations, data: _data)
            do {
                return try Promise.value(self.result(responses, context))
            } catch let error {
                throw GraphQLResultError.resultMappingError(data: _data, error: error)
            }
            }
            .done { success($0) }
            .catch {
                failure(GraphQLRequestError(error: $0, body: self.body))
        }
    }
    
    /// Will run performation with **Promise** result
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (you can use your *queue*, for stoping operations)
    /// - Returns: Function return **Promise** with generic protocol of **GraphQLResult**
    public func perform(context: GraphQLContext, queue: OperationQueue? = nil) -> Promise<Result> {
        return Promise { resolver in
            self.perform(context: context, queue: queue, success: {
                resolver.fulfill($0)
            }, failure: {
                resolver.reject($0)
            })
        }
    }
    
    /// Run sicling(**Recursive**) performations until *request* not be nil
    /// from the given components.
    ///
    /// - Parameters:
    ///     - context: The **Context** protocol of **GraphQLContext**
    ///     - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///     - again: Closure for creating requests (Calls until return nil)
    ///     - result: Can be nil only first time, next time it will be *result* of previus operation
    /// - Returns:
    ///     - Closure get Request for next operation, if nil — all done
    ///     - Function return Promise with array af all results
    public static func perform(context: GraphQLContext,
                               queue: OperationQueue? = nil,
                               again: @escaping (_ result: Result?) -> GraphQLRequest<Result>?) -> Promise<[Result]> {
        
        func _perform(values: [Result] = [], result: Result? = nil) -> Promise<[Result]> {
            let _request = again(result)
            let _result = _request?.perform(context: context, queue: queue)
                .then { _perform(values: values + [$0], result: $0) }
            return _result ?? Promise.value(values)
        }
        
        return _perform()
    }
    
    /// Run sicling(**Recursive**) performations until *request* not be nil
    /// from the given components.
    ///
    /// - Parameters:
    ///     - context: The **Context** protocol of **GraphQLContext**
    ///     - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///     - again: Closure for creating requests (Calls until return nil)
    ///     - result: *result* of previus operation
    /// - Returns:
    ///     - Closure get Request for next operation, if nil — all done
    ///     - Function return Promise with array af all results
    public func perform(context: GraphQLContext,
                        queue: OperationQueue? = nil,
                        again: @escaping (_ result: Result) -> GraphQLRequest<Result>?) -> Promise<[Result]> {
        return GraphQLRequest.perform(context: context, queue: queue) { result -> GraphQLRequest<Result>? in
            if let result = result {
                return again(result)
            }
            return self
        }
    }
    
    /// Run two performations by order (You can use when second request based on data from first)
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///   - then: Closure that give *first* result and get *second* request (You must return *second* request)
    ///     - result: Result of *first* operation (generic protocol of **GraphQLResult**)
    /// - Returns: Function return **Promise** with generic protocol of **GraphQLResult** for *second* result
    public func perform<SecondResult: GraphQLResult>(context: GraphQLContext,
                                                     queue: OperationQueue? = nil,
                                                     then: @escaping (_ result: Result) -> GraphQLRequest<SecondResult>) -> Promise<SecondResult> {
        return self.perform(context: context, queue: queue).then {
            then($0).perform(context: context, queue: queue)
        }
    }
    
    /// Run two or more performations by order (You can use when second requests based on data from first)
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///   - then: Closure that give *first* result and get *second* requests (You must return *second* requests **Array**)
    ///     - result: Result of *first* operation (generic protocol of **GraphQLResult**)
    /// - Returns: Function return **Promise** with generic protocol of **GraphQLResult** for *second* results **Array**
    public func perform<SecondResult: GraphQLResult>(context: GraphQLContext,
                                                     queue: OperationQueue? = nil,
                                                     then: @escaping (_ result: Result) -> [GraphQLRequest<SecondResult>]) -> Promise<[SecondResult]> {
        return self.perform(context: context, queue: queue).then {
            when(fulfilled: then($0).map { $0.perform(context: context, queue: queue) })
        }
    }
}
