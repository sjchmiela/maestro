import Foundation
import XCTest

@MainActor
struct DeviceInfoHandler: JSONHandler {
    private let logger = loggerFor(Self.self)

    func handleJSONRequest(_ requestBody: Void) async throws -> DeviceInfoResponse {
        let screenSize = XCUIApplication.springboard.frame.size

        let deviceInfo = DeviceInfoResponse(
            widthPoints: Int(screenSize.width),
            heightPoints: Int(screenSize.height),
            widthPixels: Int(screenSize.width * UIScreen.main.scale),
            heightPixels: Int(screenSize.height * UIScreen.main.scale)
        )

        return deviceInfo
    }
}
