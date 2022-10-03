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

struct File: GraphQLFileType {
    let binary: Data
    let contentType: String
    let filename: String
    var _graphQLFormat: String { "null" }
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
        do {
            let body = try GraphQLBody(operation: self.fields, self.crops)

            let string = "{ \"query\" : \"fragment TestTypeFragment on TestType{ id name crop }  query { getFields { id name } getCrops { ...TestTypeFragment }  }\", \"variables\": {} }"
            XCTAssertEqual(body.description, string)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testInitWithVariables() {
        do {
            let var1 = GraphQLVariable(type: "Int", name: "some_int", value: 10)
            let var2 = GraphQLVariable(type: "String", name: "some_string", value: "20")
            let body = try GraphQLBody(operation: self.fields, self.crops, variables: [var1, var2])

            let string = #"{ "query" : "fragment TestTypeFragment on TestType{ id name crop }  query($some_int: Int,$some_string: String) { getFields { id name } getCrops { ...TestTypeFragment }  }", "variables": {"some_int": 10,"some_string": "20"} }"#
    
            XCTAssertEqual(body.description, string)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBrokenInit() {
        do {
            let array : [GraphQLQuery] = []
            _ = try GraphQLBody(operations: array)
        } catch let error as GraphQLResultError {
            if case let GraphQLResultError.bodyError(_, _, error) = error {
                XCTAssertEqual(error, "'operations' must contains 1 and more operations")
            } else {
                XCTFail("\(error)")
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testQueryNamesDuplicate() {
        do {
            _ = try GraphQLBody(operation: self.fields, self.crops, self.crops, self.crops)
        } catch let error as GraphQLResultError {
            if case let GraphQLResultError.bodyError(_, _, error) = error {
                XCTAssertEqual(error, "Two or more operations with equal name. Use 'alias' to resolve this problem")
            } else {
                XCTFail("\(error)")
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testFragmentsDuplicate() {
        do {
            _ = try GraphQLBody(operation: self.fields, self.crops, self.crops2)
        } catch let error as GraphQLResultError {
            if case let GraphQLResultError.bodyError(_, _, error) = error {
                XCTAssertEqual(error, "Fragment duplicates. You have two or more fragments with equal name")
            } else {
                XCTFail("\(error)")
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testArrayOfFiles() {
        do {
            let file1 = File(binary: Data(), contentType: "image/png", filename: "file1")
            let file2 = File(binary: Data(), contentType: "image/png", filename: "file2")
            let variable = GraphQLVariable(type: "Upload", name: "files", value: [file1, file2])
            _ = try GraphQLBody(operation: self.fields, variables: [variable])
        } catch let error as GraphQLResultError {
            if case let GraphQLResultError.bodyError(_, _, error) = error {
                XCTAssertEqual(error, "Library not support array of *GraphQLFileType*. You can upload by one file only")
            } else {
                XCTFail("\(error)")
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFileVariables() {
        do {
            let file = File(binary: Data(), contentType: "image/png", filename: "file")
            let variable = GraphQLVariable(type: "Upload", name: "files", value: file)
            let body = try GraphQLBody(operations: [self.fields], variables: [variable], boundary: "38F41F3F5ACA")
            XCTAssertEqual(String(data: body.data, encoding: .utf8), "--38F41F3F5ACA\r\nContent-Disposition: form-data; name=\"operations\"\r\n\r\n{ \"query\" : \" query($files: Upload) { getFields { id name }  }\", \"variables\": {\"files\": null} }\r\n--38F41F3F5ACA\r\nContent-Disposition: form-data; name=\"map\"\r\n\r\n{ \"0\": [\"variables.files\"] }\r\n--38F41F3F5ACA\r\nContent-Disposition: form-data; name=\"0\"; filename=\"file\"\r\nContent-Type: image/png\r\n\r\n\r\n--38F41F3F5ACA--\r\n")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    static var allTests = [
        ("testInit", testInit),
        ("testInitWithVariables", testInitWithVariables),
        ("testBrokenInit", testBrokenInit),
        ("testFragmentsDuplicate", testFragmentsDuplicate),
        ("testArrayOfFiles", testArrayOfFiles),
        ("testFileVariables", testFileVariables)
    ]
}
