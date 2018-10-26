//
//  GraphQLRequestTests.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

import XCTest
@testable import GQLFetcher
@testable import PromiseKit
@testable import GQLSchema

class GraphQLRequestTests: XCTestCase {
    
    class TestResult: GraphQLRequestResult {
        let data: [String : Any?]
        required init<Context>(data: [String : Any?], context: Context) throws where Context : GraphQLContext {
            self.data = data
            if data["mapping_error"] != nil {
                throw GraphQLResultError.unnown
            }
        }
    }
    
    private var networker = TestNetworker()
    private lazy var context = TestContext(networker: self.networker)
    private lazy var query = GraphQLQuery(body: "getFields { id name }")
    private lazy var body = GraphQLBody(operation: self.query)
    private weak var task: GraphQLTask?
    
    @discardableResult
    func perform(key: String = #function, type: TestNetworker.ResultType = .normal, queue: OperationQueue? = nil, timeout: TimeInterval = 1.5,  done: @escaping (TestResult) -> Void, catch _catch: @escaping (GraphQLRequestError) -> Void, before: ((GraphQLRequest<TestResult>) -> Void)? = nil) -> GraphQLRequest<TestResult> {
        
        let expectation = self.expectation(description: key)
        
        self.networker.type = type
        let request = GraphQLRequest<TestResult>(operation: self.query)
        
        request.perform(context: self.context, queue: queue).done { (data) in
            done(data)
            expectation.fulfill()
        }.catch { error in
            _catch(error.requestError)
            expectation.fulfill()
        }
        
        before?(request)
        
        waitForExpectations(timeout: timeout, handler: nil)
        self.networker.type = .normal
        
        return request
    }

    func testInit() {
        
        let request = self.perform(key: #function, done: { (result) in
            print(result.data)
            XCTAssertNotNil(result.data["data"]!)
        }, catch: { _ in
            XCTFail()
        })
        
        XCTAssertEqual(request.body.description, "{ \"query\" : \" query { getFields { id name }  }\" }")

    }
    
    func testFetchError() {
        self.perform(type: .error, done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 2)
        })
    }
    
    func testGraphQLErrors() {
        self.perform(type: .graphQLErrors, done: { _ in
            XCTFail()
        }, catch: { error in
            switch error.error {
                case .graphQLErrors(let errors): do {
                    let error = errors.first!
                    
                    let string = "message - Error message\nfields - [\"query\", \"getSome\"]\nlocations - [line - 1, column - 206]"
                    XCTAssertEqual(error.description, string)
                }
                default: XCTFail()
            }
        })
    }
    
    func testMappingError() {
        self.perform(type: .customResult(result: "{\"data\" : {\"mapping_error\" : \"\"}}"), done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 7)
        })
    }
    
    func testResultError() {
        self.perform(type: .customResult(result: "{\"data\" : [\"some\"]}"), done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 6)
        })
    }
    
    func testRequestCancel() {
        self.perform(done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.isCancelled, true)
        }, before: { request in
            request.cancel()
        })
    }
    
    func testRequestCancel2() {
        self.networker._sleep = 2
        self.perform(queue: OperationQueue(), timeout: 3, done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 1)
        }, before: { request in
            request.cancel()
        })
        self.networker._sleep = 1
    }
    
    func testRequestCancel3() {
        let request = GraphQLRequest<TestResult>(operation: self.query)
        XCTAssertEqual(request.cancel(), false)
    }
    
    static var allTests = [
        ("testInit", testInit),
        ("testFetchError", testFetchError),
        ("testGraphQLErrors", testGraphQLErrors),
        ("testMappingError", testMappingError),
        ("testResultError", testResultError),
        ("testRequestCancel", testRequestCancel),
        ("testRequestCancel2", testRequestCancel2),
        ("testRequestCancel3", testRequestCancel3),
    ]
}
