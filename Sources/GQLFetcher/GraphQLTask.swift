//
//  GraphQLTask.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import PromiseKit

/// Operation class for getting data from network
class GraphQLTask: Operation {
    
    private let body: GraphQLBody
    private var context: GraphQLContext
    private var resolver: Resolver<GraphQLJSON>
    private var task: GraphQLCancaleble?
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - body: **GraphQLBody** object that contains GraphQL request body
    ///   - context: context object, protocol of **GraphQLContext**
    ///   - resolver:  **Resolver** for geting result
    init(body: GraphQLBody, context: GraphQLContext, resolver: Resolver<GraphQLJSON>) {
        self.body = body
        self.context = context
        self.resolver = resolver
    }
    
    deinit {
        Logger.deinit(self)
    }
    
    /// Function for getting **Data** from network
    ///
    /// - Parameters:
    ///   - body: **GraphQLBody** object that contains GraphQL request body
    ///   - context: context object, protocol of **GraphQLContext**
    ///   - task: Closure that give **GraphQLCancaleble** object, for cancelling task
    /// - Returns: Returns **Promise** with result **Data**
    static func fetch(body: GraphQLBody, context: GraphQLContext, task: (GraphQLCancaleble) -> Void) -> Promise<Data> {
        return Promise { resolver in
            do {
                let _task = try context.networker.perform(context: context, body: body, completionHandler: { (data, response, error) in
                    if let error = error {
                        if error.isCancelled {
                            resolver.reject(GraphQLResultError.canceled)
                        } else {
                            let _error = GraphQLResultError.fetchError(error: error)
                            resolver.reject(_error)
                        }
                    } else if let data = data {
                        resolver.fulfill(data)
                    } else {
                        let _error = GraphQLResultError.unnown
                        resolver.reject(_error)
                    }
                })
                task(_task)
            } catch let error {
                resolver.reject(GraphQLResultError.networkerError(error: error))
            }
        }
    }
    
    /// Function for parsing **Data** to **GraphQLJSON**
    ///
    /// - Parameter data: **Data** from network
    /// - Returns: Returns **Promise** with parsed result **GraphQLJSON**
    static func parse(data: Data) -> Promise<GraphQLJSON> {
        return Promise { resolver in
            do {
                let _parsed = try JSONSerialization.jsonObject(with: data)
                if let parsed = _parsed as? GraphQLJSON {
                    resolver.fulfill(parsed)
                } else {
                    let error = GraphQLResultError.parsingFailure(data: _parsed)
                    resolver.reject(error)
                }
            } catch let error {
                let _error = GraphQLResultError.parsingError(error: error)
                resolver.reject(_error)
            }
        }
    }
    
    override func main() {
        
        let group = DispatchGroup()
        
        group.enter()
        let fetch = GraphQLTask.fetch(body: self.body, context: self.context, task: { self.task = $0 })
        
        fetch.then { GraphQLTask.parse(data: $0) }
            
            .done { self.resolver.fulfill($0) }
            .ensure { group.leave() }
            .catch { self.resolver.reject($0) }
        
        group.wait()
    }
    
    override func cancel() {
        if let task = self.task {
            task.cancel()
        } else {
            self.resolver.reject(GraphQLResultError.canceled)
        }
        super.cancel()
    }
}
