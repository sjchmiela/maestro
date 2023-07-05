import XCTest
@testable import XCTestRunner

final class XCTestRunnerTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(XCTestRunner().text, "Hello, World!")
    }
}
