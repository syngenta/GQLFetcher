//
//  TestNetworker.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import Foundation
import GQLFetcher

class TestContext: GraphQLContext {
    var url: URL = URL(string: "http://localhost")!
    var networker: GraphQLNetworker
    
    init(networker: GraphQLNetworker) {
        self.networker = networker
    }
}

struct TestNetworker: GraphQLNetworker {
    
    enum ResultType {
        case normal
        case parseError
        case unnown
        case error
        case networkerError
        case graphQLErrors
        case customResult(result: String)
    }
    
    class Task: GraphQLCancaleble {
        
        var hundler: ((Data?, URLResponse?, Error?) -> Void)?
        let _sleep: UInt32
        let type: ResultType
        init(hundler:  @escaping (Data?, URLResponse?, Error?) -> Void, sleep _sleep: UInt32, type: ResultType) {
            self.hundler = hundler
            self._sleep = _sleep
            self.type = type
            self.main()
        }
        
        deinit {
            print("deinit \(self)")
        }
        
        func main() {
            DispatchQueue.global().async {
                sleep(self._sleep)
                switch self.type {
                    case .normal: do {
                        let string = "{\"data\" : {\"data\" : \"\"}}"
                        let data = string.data(using: .utf8)
                        self.hundler?(data, nil, nil)
                    }
                    case .parseError: self.hundler?(Data(), nil, nil)
                    case .unnown: self.hundler?(nil, nil, nil)
                    case .error: self.hundler?(nil, nil, URLError(.badURL))
                    case .networkerError: break
                    case .graphQLErrors: do {
                        let string = "{\"errors\": [{\"message\": \"Error message\",\"locations\": [{\"line\": 1,\"column\": 206}],\"fields\": [\"query\",\"getSome\"]}]}"
                        let data = string.data(using: .utf8)
                        self.hundler?(data, nil, nil)
                    }
                    case .customResult(let result): do {
                        let data = result.data(using: .utf8)
                        self.hundler?(data, nil, nil)
                    }
                }
            }
        }
        
        func cancel() {
            self.hundler?(nil, nil, URLError(.cancelled))
            self.hundler = nil
            print("cancel TestNetworker.Task")
        }
    }
    
    var _sleep: UInt32
    var type: ResultType
    init(sleep _sleep: UInt32 = 1, type: ResultType = .normal) {
        self._sleep = _sleep
        self.type = type
    }
    
    func perform(context: GraphQLContext, body: GraphQLBody, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> GraphQLCancaleble {
        switch self.type {
        case .networkerError:
            throw URLError(.cannotConnectToHost)
        default:
            return Task(hundler: completionHandler, sleep: self._sleep, type: self.type)
        }
    }
}
