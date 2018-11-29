//
//  GraphQLNetworker.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

/// This protocol must realise functionality of request canceling
public protocol GraphQLCancaleble: class {
    func cancel()
}

/// Protocol for getting data from network, used in **GraphQLTask**
public protocol GraphQLNetworker {
    /// This function must realise functionality of getting **Data* from network or another place
    ///
    /// - Parameters:
    ///   - context: context that contains all information that you specify
    ///   - body: **GraphQLBody** object that contains GraphQL request body
    ///   - completionHandler: Handler that contains **URLResponse** and  **Data** or **Error** - if result not success
    /// - Returns: **GraphQLCancaleble** for canceling request
    /// - Throws: Any throws you specify
    func perform(context: GraphQLContext, body: GraphQLBody, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> GraphQLCancaleble
}
