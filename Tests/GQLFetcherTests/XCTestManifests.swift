#if !os(macOS) && !os(iOS)
import XCTest

public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GraphQLBodyTests.allTests),
        testCase(GraphQLErrorTests.allTests),
        testCase(GraphQLTaskTests.allTests),
        testCase(GraphQLRequestTests.allTests),
        testCase(GraphQLHTTPNetworkerTests.allTests),
    ]
}
#endif
