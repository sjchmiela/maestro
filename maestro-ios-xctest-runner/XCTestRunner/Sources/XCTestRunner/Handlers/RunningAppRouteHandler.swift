import Foundation
import XCTest
import os

@MainActor
struct RunningAppRouteHandler: JSONHandler {
    typealias RequestBody = RunningAppRequest

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    private static let springboardBundleId = "com.apple.springboard"

    func handleJSONRequest(_ requestBody: RunningAppRequest) async throws -> [String: String] {
        let runningAppId = requestBody.appIds.first { appId in
            let app = XCUIApplication(bundleIdentifier: appId)

            return app.state == .runningForeground
        }

        let response = ["runningAppBundleId": runningAppId ?? RunningAppRouteHandler.springboardBundleId]
        return response
    }
}
