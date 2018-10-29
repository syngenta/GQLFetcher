//
//  GraphQLResultTests.swift
//  GQLFetcherTests
//
//  Created by Evgeny Kalashnikov on 10/29/18.
//

import XCTest
@testable import GQLFetcher
@testable import GQLSchema

fileprivate struct TestlistResult: GraphQLResult {
    let responses: [GraphQLResponse<[GraphQLJSON]>]
    init<Context>(responses: [GraphQLResponse<[GraphQLJSON]>], context: Context) throws where Context : GraphQLContext {
        self.responses = responses
    }
}

class GraphQLResultTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGraphQLResponseInit() {
        let operation = GraphQLQuery(name: "getSome", body: "getSome { id name }")
        let responce = try! GraphQLResponse<[String]>(operation: operation, data: ["string"])
        XCTAssertEqual(responce.data, ["string"])
    }
    
    func testGraphQLResponseWrongInit() {
        let operation = GraphQLQuery(name: "getSome", body: "getSome { id name }")
        do {
            _ = try GraphQLResponse<[String : String]>(operation: operation, data: ["string"])
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    func testGraphQLResponseCreate() {
        let operations = [
            "getSome" : GraphQLQuery(name: "getSome", body: "getSome { id name }"),
            "getSome2" : GraphQLQuery(name: "getSome2", body: "getSome2 { id name }")
        ]
        let data : GraphQLJSON = ["getSome" : ["some"], "getSome2" : ["some2"]]
        
        do {
            let responses = try GraphQLResponse<[String]>.create(operations: operations, data: data)
            XCTAssertEqual(responses.count, 2)
            let getSome = responses.filter { $0.operation.name ==  "getSome"}.first
            let getSome2 = responses.filter { $0.operation.name ==  "getSome2"}.first
            
            XCTAssertEqual(getSome?.data, ["some"])
            XCTAssertEqual(getSome2?.data, ["some2"])
        } catch {
            XCTFail()
        }
    }
    
    func testGraphQLResponseWrongCreate() {
        let operations = [
            "getSome" : GraphQLQuery(name: "getSome", body: "getSome { id name }"),
        ]
        let data : GraphQLJSON = ["getSome1" : ["some"]]
        
        do {
            _ = try GraphQLResponse<[String]>.create(operations: operations, data: data)
            XCTFail()
        } catch let error {
            XCTAssertEqual(error.resultError?.code, 11)
        }
    }
    
    func testGraphQLResponseWrongCreate2() {
        let operations = [
            "getSome" : GraphQLQuery(name: "getSome", body: "getSome { id name }"),
            ]
        let data : GraphQLJSON = ["getSome" : ["some"]]
        
        do {
            _ = try GraphQLResponse<[String : String]>.create(operations: operations, data: data)
            XCTFail()
        } catch let error {
            XCTAssertEqual(error.resultError?.code, 10)
        }
    }
    
    fileprivate func response<Result: GraphQLResult>(operations: [String : GraphQLOperation], data: GraphQLJSON) throws -> Result {
        let context = TestContext(networker: TestNetworker())
        let responses = try GraphQLResponse<Result.Result>.create(operations: operations, data: data)
        return try Result(responses: responses, context: context)
    }
    
    func testGraphQLListResult() {
        let operations = [
            "getSome" : GraphQLQuery(name: "getSome", body: "getSome { id name }")
        ]
        let values = [["some" : "value"], ["some2" : "value"]]
        let data : GraphQLJSON = ["getSome" : values]
        do {
            let result : TestlistResult = try self.response(operations: operations, data: data)
            let _data = result.responses.first?.data as? [[String : String]]
            XCTAssertEqual(_data, values)
        } catch {
            XCTFail()
        }
    }
    
    func testGraphQLListResultWrong() {
        let operations = [
            "getSome" : GraphQLQuery(name: "getSome", body: "getSome { id name }")
        ]
        let values = [["some" : "value"], ["some2", "value"]] as [Any]
        let data : GraphQLJSON = ["getSome" : values]
        do {
            let _ : TestlistResult = try self.response(operations: operations, data: data)
            XCTFail()
        } catch let error {
            XCTAssertEqual(error.resultError!, .differentTypes)
        }
    }
    
    func testGraphQLListResultWrong2() {
        let operations = [
            "getSome" : GraphQLQuery(name: "getSome", body: "getSome { id name }")
        ]
        let values = [["some" : "value"], ["some2" : "value"]]
        let data : GraphQLJSON = ["getSome1" : values]
        do {
            let _ : TestlistResult = try self.response(operations: operations, data: data)
            XCTFail()
        } catch let error {
            XCTAssertEqual(error.resultError?.code, 11)
        }
    }
}
