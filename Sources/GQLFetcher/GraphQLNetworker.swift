//
//  GraphQLNetworker.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

public protocol GraphQLCancaleble: class {
    func cancel()
}

public protocol GraphQLNetworker {
    func perform(context: GraphQLContext, body: GraphQLBody, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> GraphQLCancaleble
}
