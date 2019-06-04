//
//  GraphQLBodyTests.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import XCTest
@testable import GQLSchema
@testable import GQLFetcher

fileprivate class TestFragment: GraphQLFragment {

    static var typeName: String {
        return "TestType"
    }
    var field: GraphQLField
    var name: String
    
    required init(name: String, field: GraphQLField) {
        self.name = name
        self.field = field
    }
}

class GraphQLBodyTests: XCTestCase {

    private let cropsFragment = TestFragment { (field) in
        try! field._add(child: GraphQLField(name: "id"))
        try! field._add(child: GraphQLField(name: "name"))
        try! field._add(child: GraphQLField(name: "crop"))
    }
    
    private let fields = GraphQLQuery(name: "getFields", body: "getFields { id name }")
    private lazy var crops = GraphQLQuery(name: "getCrops", body: "getCrops { ...TestTypeFragment }", fragment: self.cropsFragment)
    private lazy var crops2 = GraphQLQuery(name: "getCrops1", body: "getCrops { ...TestTypeFragment }", fragment: self.cropsFragment)
    
    func testInit() {
        let body = GraphQLBody(operation: self.fields, self.crops)
        
        let string = "{ \"query\" : \"fragment TestTypeFragment on TestType{ id name crop }  query { getFields { id name } getCrops { ...TestTypeFragment }  }\" }"
        XCTAssertEqual(body.description, string)
    }
    
    func testBrokenInit() {
        #if os(macOS)
        expectFatalError(expectedMessage: "'operations' must containes 1 and more operations") {
            let array : [GraphQLQuery] = []
            _ = GraphQLBody(operations: array)
        }
        #endif
    }
    
    func testQueryNamesDuplicate() {
        #if os(macOS)
        expectFatalError(expectedMessage: "Two or more operations with equal name. Use 'alias' to resolve this problem") {
            _ = GraphQLBody(operation: self.fields, self.crops, self.crops, self.crops)
        }
        #endif
    }
    
    func testFragmentsDuplicate() {
        #if os(macOS)
        expectFatalError(expectedMessage: "Fragment dublicates. You have two or more fragments with equal name") {
            _ = GraphQLBody(operation: self.fields, self.crops, self.crops2)
        }
        #endif
    }
    
    static var allTests = [
        ("testInit", testInit),
        ("testBrokenInit", testBrokenInit),
        ("testFragmentsDuplicate", testFragmentsDuplicate),
    ]
}
