//
//  GraphQLHTTPNetworker.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

extension URLSessionDataTask: GraphQLCancaleble {}

/// Class for getting *Data* from network
public class GraphQLHTTPNetworker: GraphQLNetworker {
    
    let configuration: URLSessionConfiguration
    let session: URLSession
    
    /// Initializer
    ///
    /// - Parameters
    ///     - configuration: Session configuration for spetify your own configurations, by default **URLSessionConfiguration.default**
    ///     - delegate: A session delegate object that handles requests for authentication and other session-related events.
    ///     - delegateQueue: An operation queue for scheduling the delegate calls and completion handlers.
    ///     The queue should be a serial queue, in order to ensure the correct ordering of callbacks.
    ///     If nil, the session creates a serial operation queue for performing all delegate method
    ///     calls and completion handler calls.
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default, delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) {
        self.configuration = configuration
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    
    @discardableResult
    /// Function for getting *Data* from network
    ///
    /// - Parameters:
    ///   - context: context that contains all information that you specify
    ///   - body: **GraphQLBody** object that contains GraphQL request body
    ///   - completionHandler: Handler that contains **URLResponse** and  **Data** or **Error** - if result not success
    /// - Returns: **GraphQLCancaleble** for canceling request
    /// - Throws: No throws
    public func perform(context: GraphQLContext, body: GraphQLBody, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> GraphQLCancaleble {
        let request =  self.request(to: context.url, for: body)
        let task = self.session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
    /// Function for creating **URLRequest** from **GraphQLBody**
    ///
    /// - Parameters:
    ///   - url: Your GraphQL url
    ///   - body: **GraphQLBody** object that contains GraphQL request body
    /// - Returns: **URLRequest**
    func request(to url: URL, for body: GraphQLBody) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpBody = body.data
        if let parameters = body.parameters {
            request.allHTTPHeaderFields = parameters.httpHeaders
            request.timeoutInterval = parameters.timeoutInterval
        }

        if let boundary = body.boundary { // if boundary exist — multipart
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        } else {
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}
