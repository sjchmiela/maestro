import Foundation
import os
import XCTest

@MainActor
struct PressButtonHandler: JSONHandler {
    typealias RequestBody = PressButtonRequest

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: PressButtonRequest) async throws {
        switch requestBody.button {
        case .home:
            XCUIDevice.shared.press(.home)
        case .lock:
            XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        }
    }
}
