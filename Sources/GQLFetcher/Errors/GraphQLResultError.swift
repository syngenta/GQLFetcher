//
//  GraphQLResultError.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation

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
    
    public var code: Int {
        switch self {
        case .unnown: return 0
        case .canceled: return 1
        case .fetchError(_): return 2
        case .parsingFailure(_): return 3
        case .parsingError(_): return 4
        case .graphQLErrors(_): return 5
        case .resultError(_): return 6
        case .resultMappingError(_, _): return 7
        case .networkerError(_): return 8
        case .customResultError(_): return 9
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
        }
    }
    
    public var isCancelled: Bool {
        return self == .canceled
    }
}

public extension Error {
    public var resultError: GraphQLResultError? {
        return self as? GraphQLResultError
    }
}
