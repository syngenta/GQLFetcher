//
//  GraphQLRequest.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import PromiseKit
import GQLSchema

public struct GraphQLRequestParameters {
    let timeoutInterval: TimeInterval
    let httpHeaders: [String: String]

    public init(timeoutInterval: TimeInterval, httpHeaders: [String : String]) {
        self.timeoutInterval = timeoutInterval
        self.httpHeaders = httpHeaders
    }

    public static func timeoutInterval(_ timeoutInterval: TimeInterval) -> GraphQLRequestParameters {
        GraphQLRequestParameters(timeoutInterval: timeoutInterval, httpHeaders: [:])
    }
}

/// - Class for describing and getting GraphQL data
/// - Use generic **Result**, protocol of **GraphQLResult**
public final class GraphQLRequest<Result: GraphQLResult> {

    private var isQueue = false
    private lazy var queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.lumyk.GQLFetcher.GraphQLRequest-\(self)"
        q.maxConcurrentOperationCount = 1
        self.isQueue = true
        return q
    }()
    private var task: GraphQLTask?
    private let operations: [GraphQLOperation]
    private let variables: [GraphQLVariable]

    /// Initialiser of **GraphQLRequest**
    ///
    /// - Parameter operations: list of operations (protocol of **GraphQLOperation**)
    /// - Parameter variables: GraphQL variables used for request
    public init(operations: [GraphQLOperation], variables: [GraphQLVariable] = []) {
        self.operations = operations
        self.variables = variables
    }

    /// Initialiser of **GraphQLRequest**
    ///
    /// - Parameter operations: list of operations (generic protocol of **GraphQLOperation**)
    /// - Parameter variable: GraphQL variables used for request
    public convenience init(operations: [GraphQLOperation], variable variables: GraphQLVariable...) {
        self.init(operations: operations, variables: variables)
    }

    /// Initialiser of **GraphQLRequest**
    ///
    /// - Parameter operation: operations (generic protocol of **GraphQLOperation**)
    /// - Parameter variable: GraphQL variables used for request
    public convenience init(operation operations: GraphQLOperation..., variable variables: GraphQLVariable...) {
        self.init(operations: operations, variables: variables)
    }

    /// Initialiser of **GraphQLRequest**
    ///
    /// - Parameter operation: operations (generic protocol of **GraphQLOperation**)
    public convenience init(operation operations: GraphQLOperation...) {
        self.init(operations: operations, variables: [])
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
    func add(_ value: Result.Additional) -> Self {
        self.result = { try Result(responses: $0, context: $1, additional: value) }
        return self
    }
}

// MARK: - Performs
public extension GraphQLRequest {

    func body(parameters: GraphQLRequestParameters?) throws -> GraphQLBody {
        try GraphQLBody(operations: self.operations, variables: self.variables, parameters: parameters)
    }

    ///  Will run performation with closure result
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///   - parameters: Additional parameters for request (like timeoutInterval, httpHeaders, etc.)
    ///   - success: Closure with success result(generic protocol of **GraphQLResult**)
    ///   - failure: Closure with failure result(error struct **GraphQLRequestError**)
    func perform(context: GraphQLContext,
                 queue: OperationQueue? = nil,
                 parameters: GraphQLRequestParameters? = nil,
                 success: @escaping (Result) -> Void, failure: @escaping (GraphQLRequestError) -> Void) {
        let queue = queue ?? self.queue

        let body: GraphQLBody
        do {
            body = try self.body(parameters: parameters)
        } catch {
            failure(GraphQLRequestError(error: error))
            return
        }

        let fetch = Promise<GraphQLJSON> { resolver in
            let operation = GraphQLTask(body: body, context: context, resolver: resolver)
            self.task = operation
            queue.addOperation(operation)
        }

        fetch.then { data -> Promise<Result> in
            if let errors = data["errors"] as? [GraphQLJSON] {
                let errors = errors.compactMap { GraphQLError(data: $0) }
                if let unauthorizedError = errors.first(where: { $0.message == "Not authenticated" }) {
                    throw GraphQLResultError.unauthorizedError(error: unauthorizedError)
                } else {
                    throw GraphQLResultError.graphQLErrors(errors: errors)
                }
            }

            guard let _data = data["data"] as? GraphQLJSON else {
                throw GraphQLResultError.resultError(data: data)
            }

            let operations = Dictionary(uniqueKeysWithValues: self.operations.map { ($0.name, $0) })
            let responses = try GraphQLResponse<Result.Result>.create(operations: operations, data: _data, body: body)
            do {
                return try Promise.value(self.result(responses, context))
            } catch let error {
                throw GraphQLResultError.resultMappingError(data: _data, error: error)
            }
        }
        .done { success($0) }
        .catch {
            failure(GraphQLRequestError(error: $0, body: body))
        }
    }

    /// Will run performation with **Promise** result
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (you can use your *queue*, for stoping operations)
    ///   - parameters: Additional parameters for request (like timeoutInterval, httpHeaders, etc.)
    /// - Returns: Function return **Promise** with generic protocol of **GraphQLResult**
    func perform(context: GraphQLContext,
                 queue: OperationQueue? = nil,
                 parameters: GraphQLRequestParameters? = nil) -> Promise<Result> {

        return Promise { resolver in
            self.perform(context: context, queue: queue, parameters: parameters, success: {
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
    ///     - parameters: Additional parameters for request (like timeoutInterval, httpHeaders, etc.)
    ///     - again: Closure for creating requests (Calls until return nil)
    ///     - result: Can be nil only first time, next time it will be *result* of previus operation
    /// - Returns:
    ///     - Closure get Request for next operation, if nil — all done
    ///     - Function return Promise with array af all results
    static func perform(context: GraphQLContext,
                        queue: OperationQueue? = nil,
                        parameters: GraphQLRequestParameters? = nil,
                        again: @escaping (_ result: Result?) -> GraphQLRequest<Result>?) -> Promise<[Result]> {

        func _perform(values: [Result] = [], result: Result? = nil) -> Promise<[Result]> {
            let _request = again(result)
            let _result = _request?.perform(context: context, queue: queue, parameters: parameters)
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
    ///     - parameters: Additional parameters for request (like timeoutInterval, httpHeaders, etc.)
    ///     - again: Closure for creating requests (Calls until return nil)
    ///     - result: *result* of previus operation
    /// - Returns:
    ///     - Closure get Request for next operation, if nil — all done
    ///     - Function return Promise with array af all results
    func perform(context: GraphQLContext,
                 queue: OperationQueue? = nil,
                 parameters: GraphQLRequestParameters? = nil,
                 again: @escaping (_ result: Result) -> GraphQLRequest<Result>?) -> Promise<[Result]> {

        GraphQLRequest.perform(context: context, queue: queue, parameters: parameters) { result -> GraphQLRequest<Result>? in
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
    ///   - parameters: Additional parameters for request (like timeoutInterval, httpHeaders, etc.)
    ///   - then: Closure that give *first* result and get *second* request (You must return *second* request)
    ///     - result: Result of *first* operation (generic protocol of **GraphQLResult**)
    /// - Returns: Function return **Promise** with generic protocol of **GraphQLResult** for *second* result
    func perform<SecondResult: GraphQLResult>(context: GraphQLContext,
                                              queue: OperationQueue? = nil,
                                              parameters: GraphQLRequestParameters? = nil,
                                              then: @escaping (_ result: Result) -> GraphQLRequest<SecondResult>) -> Promise<SecondResult> {
        return self.perform(context: context, queue: queue, parameters: parameters).then {
            then($0).perform(context: context, queue: queue, parameters: parameters)
        }
    }

    /// Run two or more performations by order (You can use when second requests based on data from first)
    ///
    /// - Parameters:
    ///   - context: The **Context** protocol of **GraphQLContext**
    ///   - queue: **OperationQueue** can't be nil (for stoping operations you can use your *queue*)
    ///   - parameters: Additional parameters for request (like timeoutInterval, httpHeaders, etc.)
    ///   - then: Closure that give *first* result and get *second* requests (You must return *second* requests **Array**)
    ///     - result: Result of *first* operation (generic protocol of **GraphQLResult**)
    /// - Returns: Function return **Promise** with generic protocol of **GraphQLResult** for *second* results **Array**
    func perform<SecondResult: GraphQLResult>(context: GraphQLContext,
                                              queue: OperationQueue? = nil,
                                              parameters: GraphQLRequestParameters? = nil,
                                              then: @escaping (_ result: Result) -> [GraphQLRequest<SecondResult>]) -> Promise<[SecondResult]> {
        return self.perform(context: context, queue: queue, parameters: parameters).then {
            when(fulfilled: then($0).map { $0.perform(context: context, queue: queue, parameters: parameters) })
        }
    }
}

extension GraphQLRequest: Codable where Result: Codable {

    enum CodingKeys: CodingKey {
        case operations
        case variables
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let operationsBox = self.operations.map { GraphQLOperationCodableBox(operation: $0) }
        try container.encode(operationsBox, forKey: .operations)
        try container.encode(self.variables, forKey: .variables)
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let operationsBox = try container.decode([GraphQLOperationCodableBox].self, forKey: .operations)
        let operations = operationsBox.map(\.operation)
        let variables = try container.decode([GraphQLVariable].self, forKey: .variables)
        self.init(operations: operations, variables: variables)
    }
}
