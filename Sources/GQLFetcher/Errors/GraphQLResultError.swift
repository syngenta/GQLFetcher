//
//  GraphQLResultError.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import GQLSchema

public enum GraphQLResultError: Error, Equatable {
    
    public static func == (lhs: GraphQLResultError, rhs: GraphQLResultError) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    case unnown
    case canceled
    case fetchError(error: Error)
    case parsingFailure(data: Any?)
    case parsingError(error: Error)
    case graphQLErrors(errors: [GraphQLError])
    case resultError(data: GraphQLJSON)
    case resultMappingError(data: GraphQLJSON, error: Error)
    case networkerError(error: Error)
    case customResultError(error: String)
    case differentTypes
    case noOperationForData(operations: [String : GraphQLOperation], data: Any?)
    case bodyError(operations: [GraphQLOperation], variables: [GraphQLVariable], error: String)
    case unauthorizedError(error: GraphQLError)

    public var code: Int {
        switch self {
        case .unnown: return 0
        case .canceled: return 1
        case .fetchError: return 2
        case .parsingFailure: return 3
        case .parsingError: return 4
        case .graphQLErrors: return 5
        case .resultError: return 6
        case .resultMappingError: return 7
        case .networkerError: return 8
        case .customResultError: return 9
        case .differentTypes: return 10
        case .noOperationForData: return 11
        case .bodyError: return 12
        case .unauthorizedError: return 13
        }
    }
    
    private var hashValue: String {
        switch self {
        case .unnown: return "unnown"
        case .canceled: return "canceled"
        case .fetchError(let error): return "fetchError - \(error)"
        case .parsingFailure(let data): return "parsingFailure \(String(describing: data))"
        case .parsingError(let error): return "parsingError \(error)"
        case .graphQLErrors(let errors): return "graphQLErrors - \(errors)"
        case .resultError(let data): return "resultError - \(data)"
        case .resultMappingError(let data, let error): return "resultMappingError - \(data) \(error)"
        case .networkerError(let error): return "networkerError - \(error)"
        case .customResultError(let error): return "customResultError - \(error)"
        case .differentTypes: return "differentTypes"
        case .noOperationForData(let operations, let data):
            return "noOperationForData - \(operations) \(String(describing: data))"
        case .bodyError(operations: let operations, let variables, let error):
            return "bodyError - \(operations), variables - \(variables), \(error)"
        case .unauthorizedError(let error): return "unauthorizedError - \(error)"
        }
    }
    
    public var isCancelled: Bool {
        return self == .canceled
    }
}

public extension Error {
    var resultError: GraphQLResultError? {
        return self as? GraphQLResultError
    }
}
