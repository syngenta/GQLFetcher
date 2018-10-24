//
//  GraphQLHTTPNetworkerTests.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/24/18.
//

import XCTest
@testable import GQLFetcher
@testable import PromiseKit
@testable import GQLSchema

class GraphQLHTTPNetworkerTests: XCTestCase {

    private let configuration : URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 1
        config.timeoutIntervalForResource = 1
        return config
    }()
    private lazy var networker = GraphQLHTTPNetworker(configuration: self.configuration)
    private lazy var query = GraphQLQuery(body: "getFields { id name }")
    private lazy var body = GraphQLBody(operation: self.query)
    

    func testPerform() {
        let testContext = TestContext(networker: self.networker)

        let expectation = self.expectation(description: #function)
        try! self.networker.perform(context: testContext, body: self.body) { (data, responce, error) in
            XCTAssertNil(data)
            XCTAssertNil(responce)
            XCTAssertEqual((error as! URLError).code, URLError.cannotConnectToHost)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRequestFromBody() {

        let request = self.networker.request(to: URL(string: "http://localhost")!, for: self.body)
        
        XCTAssertEqual(request.url?.absoluteString, "http://localhost")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpShouldHandleCookies, false)
        XCTAssertEqual(request.httpBody, self.body.body.data(using: .utf8))
        XCTAssertEqual(request.allHTTPHeaderFields, ["Accept": "application/json", "Content-Type": "application/json"])
    }
    
    static var allTests = [
        ("testPerform", testPerform),
        ("testRequestFromBody", testRequestFromBody),
    ]
}
