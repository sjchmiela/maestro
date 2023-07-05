import Foundation
import os
import XCTest

@MainActor
struct DeviceInfoHandler: JSONHandler {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: Void) async throws -> DeviceInfoResponse {
        let springboardBundleId = "com.apple.springboard"
        let springboardApp = XCUIApplication(bundleIdentifier: springboardBundleId)
        let screenSize = springboardApp.frame.size

        let deviceInfo = DeviceInfoResponse(
            widthPoints: Int(screenSize.width),
            heightPoints: Int(screenSize.height),
            widthPixels: Int(screenSize.width * UIScreen.main.scale),
            heightPixels: Int(screenSize.height * UIScreen.main.scale)
        )

        return deviceInfo
    }
}