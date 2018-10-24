//
//  GraphQLHTTPNetworker.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

extension URLSessionDataTask: GraphQLCancaleble {}

public struct GraphQLHTTPNetworker: GraphQLNetworker {
    
    let configuration: URLSessionConfiguration
    let session: URLSession
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.configuration = configuration
        self.session = URLSession(configuration: configuration)
    }
    
    @discardableResult
    public func perform(context: GraphQLContext, body: GraphQLBody, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> GraphQLCancaleble {
        let request =  self.request(to: context.url, for: body)
        let task = self.session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
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


