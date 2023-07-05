
import XCTest
import XCTestRunner

class maestro_driver_iosUITests: XCTestCase {
    func testHttpServer() async throws {
        let server = XCTestHTTPServer()
        try await server.start()
    }
}
