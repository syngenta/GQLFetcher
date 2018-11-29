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
    
    class TestResult: GraphQLResult {
        let data: GraphQLJSON

        required init(responses: [String : GraphQLResponse<GraphQLJSON>], context: GraphQLContext) throws {
            self.data = responses.values.first!.data
            if self.data["mapping_error"] != nil {
                throw GraphQLResultError.unnown
            }
        }
    }
    
    class TestAdditionalResult: GraphQLAdditionalResult {
        typealias Additional = Int
        
        let data: GraphQLJSON
        let additional: Additional
        
        required init(responses: [String : GraphQLResponse<GraphQLJSON>], context: GraphQLContext) throws {
            self.data = responses.values.first!.data
            if self.data["mapping_error"] != nil {
                throw GraphQLResultError.unnown
            }
            self.additional = -1
        }
        
        required init(responses: [String : GraphQLResponse<GraphQLJSON>], context: GraphQLContext, additional: Additional) throws {
            self.data = responses.values.first!.data
            if self.data["mapping_error"] != nil {
                throw GraphQLResultError.unnown
            }
            self.additional = additional
        }
    }
    
    private var networker = TestNetworker()
    private lazy var context = TestContext(networker: self.networker)
    private lazy var query = GraphQLQuery(name: "getFields", body: "getFields { id name }")
    private lazy var body = GraphQLBody(operation: self.query)
    private weak var task: GraphQLTask?
    
    @discardableResult
    func perform<Result: GraphQLResult>(key: String = #function,
                                        type: TestNetworker.ResultType = .normal,
                                        queue: OperationQueue? = nil,
                                        timeout: TimeInterval = 1.5,
                                        done: @escaping (Result) -> Void,
                                        catch _catch: @escaping (GraphQLRequestError) -> Void,
                                        before: ((GraphQLRequest<Result>) -> Void)? = nil,
                                        beforePerform: ((GraphQLRequest<Result>) -> Void)? = nil) -> GraphQLRequest<Result> {
        
        let expectation = self.expectation(description: key)
        
        self.networker.type = type
        let request = GraphQLRequest<Result>(operation: self.query)
        
        beforePerform?(request)
        
        request.perform(context: self.context, queue: queue).done { (data) in
            done(data)
            expectation.fulfill()
        }.catch { error in
            print(error)
            _catch(error.requestError)
            expectation.fulfill()
        }
        
        before?(request)
        
        waitForExpectations(timeout: timeout, handler: nil)
        self.networker.type = .normal
        
        return request
    }

    func testInit() {
        
        let request : GraphQLRequest<TestResult> = self.perform(key: #function, done: { (result) in
            print(result.data)
            XCTAssertNotNil(result.data["data"]!)
        }, catch: { _ in
            XCTFail()
        })
        
        XCTAssertEqual(request.body.description, "{ \"query\" : \" query { getFields { id name }  }\" }")

    }
    
    func testFetchError() {
        let _ : GraphQLRequest<TestResult> = self.perform(type: .error, done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 2)
        })
    }
    
    func testGraphQLErrors() {
        let _ : GraphQLRequest<TestResult> = self.perform(type: .graphQLErrors, done: { _ in
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
        let _ : GraphQLRequest<TestResult> = self.perform(type: .customResult(result: "{\"data\" : {\"getFields\" : {\"mapping_error\" : \"\"}}}"), done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 7)
        })
    }
    
    func testResultError() {
        let _ : GraphQLRequest<TestResult> = self.perform(type: .customResult(result: "{\"data\" : [\"some\"]}"), done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.error.code, 6)
        })
    }
    
    func testRequestCancel() {
        let _ : GraphQLRequest<TestResult> = self.perform(done: { _ in
            XCTFail()
        }, catch: { error in
            XCTAssertEqual(error.isCancelled, true)
        }, before: { request in
            request.cancel()
        })
    }
    
    func testRequestCancel2() {
        self.networker._sleep = 2
        let _ : GraphQLRequest<TestResult> = self.perform(queue: OperationQueue(), timeout: 3, done: { _ in
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
    
    func testAdditionalResultPerform1() { // not add addition
        let _ : GraphQLRequest<TestAdditionalResult> = self.perform(done: { (result) in
            print(result.data)
            XCTAssertNotNil(result.data["data"]!)
            XCTAssertEqual(result.additional, -1)
        }, catch: { _ in
            XCTFail()
        })
    }
    
    func testAdditionalResultPerform2() { // add addition
        let _ : GraphQLRequest<TestAdditionalResult> = self.perform(done: { (result) in
            print(result.data)
            XCTAssertNotNil(result.data["data"]!)
            XCTAssertEqual(result.additional, 10)
        }, catch: { _ in
            XCTFail()
        }, beforePerform: { _ = $0.add(10) })
    }
    
    func testRecursivePerform() {
        let expectation = self.expectation(description: #function)
        
        let request = GraphQLRequest<TestResult>(operation: self.query)
        self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"123\"}}}")
        
        request.perform(context: self.context, again: { result -> GraphQLRequest<GraphQLRequestTests.TestResult>? in
            return nil
        })
        .done { (data) in
            XCTAssertEqual(data.count, 1)
            XCTAssertEqual(data.first!.data["data"] as! String, "123")
            expectation.fulfill()
            self.networker.type = .normal
            
            }.catch { error in
                XCTFail()
                print(error)
                expectation.fulfill()
                self.networker.type = .normal
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRecursivePerform2() {
        let expectation = self.expectation(description: #function)
        
        let request = GraphQLRequest<TestResult>(operation: self.query)
        self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"123\"}}}")
        
        request.perform(context: self.context, again: { result -> GraphQLRequest<GraphQLRequestTests.TestResult>? in
            if let data = result.data["data"] as? String, data == "1234" {
                return nil
            }
            self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"1234\"}}}")
            return GraphQLRequest<TestResult>(operation: self.query)
        })
            .done { (data) in
                XCTAssertEqual(data.count, 2)
                XCTAssertEqual(data.first!.data["data"] as! String, "123")
                XCTAssertEqual(data.last!.data["data"] as! String, "1234")

                expectation.fulfill()
                self.networker.type = .normal
                
            }.catch { error in
                XCTFail()
                print(error)
                expectation.fulfill()
                self.networker.type = .normal
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSecondResultPerform() {
        let expectation = self.expectation(description: #function)
        
        let request = GraphQLRequest<TestResult>(operation: self.query)
        self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"123\"}}}")

        request.perform(context: self.context, then: { (result) -> GraphQLRequest<TestResult> in
            self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"\(String(describing: result.data["data"]!!))\"}}}")
            let q = GraphQLQuery(name: "getFields", body: "getFields { id name }")
            return  GraphQLRequest(operation: q)
        }).done { (data) in
            XCTAssertEqual(data.data["data"] as! String, "123")
            expectation.fulfill()
            self.networker.type = .normal

        }.catch { error in
            XCTFail()
            print(error)
            expectation.fulfill()
            self.networker.type = .normal
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSecondResultsPerform() {
        let expectation = self.expectation(description: #function)
        
        let request = GraphQLRequest<TestResult>(operation: self.query)
        self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"123\"}}}")
        
        request.perform(context: self.context, then: { (result) -> [GraphQLRequest<TestResult>] in
            self.networker.type = .customResult(result: "{\"data\" : {\"getFields\" : {\"data\" : \"\(String(describing: result.data["data"]!!))\"}}}")
            let q = GraphQLQuery(name: "getFields", body: "getFields { id name }")
            return [GraphQLRequest(operation: q), GraphQLRequest(operation: q)]
        }).done { (data) in
            XCTAssertEqual(data.count, 2)
            XCTAssertEqual(data.first!.data["data"] as! String, "123")
            XCTAssertEqual(data.last!.data["data"] as! String, "123")
            expectation.fulfill()
            self.networker.type = .normal
            
            }.catch { error in
                XCTFail()
                print(error)
                expectation.fulfill()
                self.networker.type = .normal
        }
        
        waitForExpectations(timeout: 3, handler: nil)
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
