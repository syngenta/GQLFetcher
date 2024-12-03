//
//  GraphQLErrorTests.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/23/18.
//

import XCTest
@testable import GQLFetcher

class GraphQLErrorTests: XCTestCase {

    func testInit() {
        let _error : GraphQLJSON = [
            "message": "Fragment CropFragment3 was used, but not defined",
            "locations": [
                [
                    "line": 1,
                    "column": 206
                ]
            ],
            "fields": [
                "query",
                "getCrops",
                "... CropFragment3"
            ]
        ]
        
        let error = GraphQLError(data: _error)
        XCTAssertEqual(error.message, "Fragment CropFragment3 was used, but not defined")
        XCTAssertEqual(error.fields, [
            "query",
            "getCrops",
            "... CropFragment3"
        ])
        XCTAssertEqual(error.locations?.first?.line, 1)
        XCTAssertEqual(error.locations?.first?.column, 206)
    }
    
    func testUnnownError() {
        let error = GraphQLError(data: [:])
        XCTAssertEqual(error.message, "Unknown error")
        XCTAssertNil(error.fields)
        XCTAssertNil(error.locations)
    }
    
    func testBodyLocation() {
        let _error : GraphQLJSON = [
            "message": "Error message",
            "line": 2,
            "column": 56,
            "fields": [
                10
            ]
        ]
        let error = GraphQLError(data: _error)
        XCTAssertEqual(error.message, "Error message")
        XCTAssertNil(error.fields)
        XCTAssertEqual(error.locations?.first?.line, 2)
        XCTAssertEqual(error.locations?.first?.column, 56)
    }

    func testIncompatibkeErrorMessage() {
        let _error : GraphQLJSON = [
            "message": ["Errors": ["invalidargument": -333]],
            "line": 2,
            "column": 56,
            "fields": [
                10
            ]
        ]
        let error = GraphQLError(data: _error)
        XCTAssertEqual(error.message, "{\"Errors\":{\"invalidargument\":-333}}")
        XCTAssertNil(error.fields)
        XCTAssertEqual(error.locations?.first?.line, 2)
        XCTAssertEqual(error.locations?.first?.column, 56)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testUnnownError", testUnnownError),
        ("testBodyLocation", testBodyLocation),
    ]
}
