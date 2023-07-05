import Foundation
import XCTest

@MainActor
struct PressButtonHandler: JSONHandler {
    typealias RequestBody = PressButtonRequest

    private let logger = loggerFor(Self.self)

    func handleJSONRequest(_ requestBody: PressButtonRequest) async throws {
        switch requestBody.button {
        case .home:
            XCUIDevice.shared.press(.home)
        case .lock:
            XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        }
    }
}
