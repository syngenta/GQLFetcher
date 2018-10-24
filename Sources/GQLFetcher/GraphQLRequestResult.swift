//
//  GraphQLRequestResult.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

public protocol GraphQLRequestResult {
    init<Context: GraphQLContext>(data: [String : Any?], context: Context) throws
}
