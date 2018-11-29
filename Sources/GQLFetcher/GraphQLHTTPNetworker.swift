//
//  GraphQLHTTPNetworker.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

extension URLSessionDataTask: GraphQLCancaleble {}

/// Class for getting *Data* from network
public struct GraphQLHTTPNetworker: GraphQLNetworker {
    
    let configuration: URLSessionConfiguration
    let session: URLSession
    
    /// Initializer
    ///
    /// - Parameter configuration: Session configuration for spetify your own configurations, by default **URLSessionConfiguration.default**
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.configuration = configuration
        self.session = URLSession(configuration: configuration)
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
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
}


