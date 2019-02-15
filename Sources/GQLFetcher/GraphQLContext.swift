//
//  GraphQLContext.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

import Foundation

public protocol GraphQLContext {
    /// Must contains GraphQL server URL
    var url: URL { get }
    var networker: GraphQLNetworker { get }
}
