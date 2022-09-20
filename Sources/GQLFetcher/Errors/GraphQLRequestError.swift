//
//  GraphQLRequestError.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

public struct GraphQLRequestError: Error {
    public let error: GraphQLResultError
    public let body: GraphQLBody?
    
    init(error: Error, body: GraphQLBody? = nil) {
        self.error = error as! GraphQLResultError
        self.body = body
    }
    
    public var isCancelled: Bool {
        return self.error == GraphQLResultError.canceled
    }
}

public extension Error {
    var requestError: GraphQLRequestError {
        return self as! GraphQLRequestError
    }
}
