//
//  GraphQLTask.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import PromiseKit

class GraphQLTask: AsyncOperation {
    
    private let body: GraphQLBody
    private var context: GraphQLContext
    private var resolver: Resolver<GraphQLJSON>
    private var task: GraphQLCancaleble?
    
    init(body: GraphQLBody, context: GraphQLContext, resolver: Resolver<GraphQLJSON>) {
        self.body = body
        self.context = context
        self.resolver = resolver
    }
    
    deinit {
        Logger.deinit(self)
    }
    
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

        let fetch = GraphQLTask.fetch(body: self.body, context: self.context, task: { self.task = $0 })
        fetch.then {
            GraphQLTask.parse(data: $0)
        }.done {
            self.resolver.fulfill($0)
        }.ensure {
            self.finish()
        }.catch {
            self.resolver.reject($0)
        }
    }
    
    override func cancel() {
        self.task?.cancel()
        self.task = nil
        super.cancel()
    }
}
