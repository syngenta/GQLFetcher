//
//  GraphQLTaskTests.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import XCTest
@testable import GQLFetcher
@testable import PromiseKit
@testable import GQLSchema

class GraphQLTaskTests: XCTestCase {
    
    private var networker = TestNetworker()
    private lazy var testContext = TestContext(networker: self.networker)
    private lazy var query = GraphQLQuery(name: "getFields", body: "getFields { id name }")
    private lazy var body = GraphQLBody(operation: self.query)
    private weak var task: GraphQLTask?
    
    lazy var promise = Promise<GraphQLJSON> {
        let task = GraphQLTask(body: self.body, context: self.testContext, resolver: $0)
        self.task = task
        task.start()
    }

    func testInit() {
        
        let expectation = self.expectation(description: #function)
        
        self.promise.done { data in
            XCTAssertNotNil(data["data"]!)
            expectation.fulfill()
        }.catch {_ in
            XCTFail()
        }
        
        waitForExpectations(timeout: 1.5, handler: nil)
    }
    
    func testCancel() {
        let expectation = self.expectation(description: #function)
        
        self.promise.done { data in
            expectation.fulfill()
            XCTFail()
        }.catch { error in
            expectation.fulfill()
            XCTAssert(error.resultError?.isCancelled ?? false)
        }
        self.task?.cancel()
        
        waitForExpectations(timeout: 1.5, handler: nil)
    }
    
    func testParseError() {
        let promise = GraphQLTask.parse(data: Data())
        promise.done { (data) in
            XCTFail()
        }.catch { (error) in
            XCTAssert((error.resultError?.code ?? -1) == 4)
        }
    }
    
    func testParseErrorType() {
        let data = "[{ \"some\" : \"value\"}]".data(using: .utf8)!
        let promise = GraphQLTask.parse(data: data)
        promise.done { (data) in
            XCTFail()
        }.catch { (error) in
            XCTAssert((error.resultError?.code ?? -1) == 3)
        }
    }
    
    func testParseError2() {
        let expectation = self.expectation(description: #function)
        self.networker.type = .parseError
        self.promise.done { data in
            XCTFail()
            expectation.fulfill()
        }.catch { error in
            XCTAssert((error.resultError?.code ?? -1) == 4)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.5, handler: nil)
        self.networker.type = .normal
    }
    
    func testFetchUnnownError() {
        let expectation = self.expectation(description: #function)
        self.networker.type = .unnown
        self.promise.done { data in
            XCTFail()
            expectation.fulfill()
        }.catch { error in
            XCTAssert((error.resultError?.code ?? -1) == 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.5, handler: nil)
        self.networker.type = .normal
    }
    
    func testFetchError() {
        
        let expectation = self.expectation(description: #function)
        self.networker.type = .error
        self.promise.done { data in
            XCTFail()
            expectation.fulfill()
        }.catch { _ in
            XCTAssert(true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.5, handler: nil)
        self.networker.type = .normal
    }
    
    func testNetworkerError() {
        
        let expectation = self.expectation(description: #function)
        self.networker.type = .networkerError
        self.promise.done { data in
            XCTFail()
            expectation.fulfill()
        }.catch { _ in
            XCTAssert(true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.5, handler: nil)
        self.networker.type = .normal
    }
    
    static var allTests = [
        ("testInit", testInit),
        ("testCancel", testCancel),
        ("testParseError", testParseError),
        ("testParseErrorType", testParseErrorType),
        ("testParseError2", testParseError2),
        ("testFetchUnnownError", testFetchUnnownError),
        ("testFetchError", testFetchError),
        ("testNetworkerError", testNetworkerError),
    ]
}
