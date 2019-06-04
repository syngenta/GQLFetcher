//
//  EnvironmentTests.swift
//  GQLFetcherTests
//
//  Created by Evegeny Kalashnikov on 5/31/19.
//

import XCTest
@testable import GQLFetcher

class EnvironmentTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testEnvironment() {
        XCTAssertNil(Environment.shared[Environment.Key.debugLoging])
        Environment.shared[Environment.Key.debugLoging] = "1"
        
        XCTAssertEqual(Environment.shared[Environment.Key.debugLoging], "1")
        
        XCTAssert(Environment.debugLoging)
        
        Environment.shared[Environment.Key.debugLoging] = nil
        XCTAssertNil(Environment.shared[Environment.Key.debugLoging])
        
        Environment.shared[Environment.Key.debugLoging] = "1"
    }
    
    static var allTests = [
        ("testEnvironment", testEnvironment)
    ]
}
