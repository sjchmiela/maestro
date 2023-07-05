import Foundation
import XCTest

@MainActor
struct RunningAppRouteHandler: JSONHandler {
    typealias RequestBody = RunningAppRequest

    private let springboardBundleId = "com.apple.springboard"
    private let logger = loggerFor(Self.self)

    func handleJSONRequest(_ requestBody: RunningAppRequest) async throws -> [String: String] {
        let runningAppId = requestBody.appIds.first { appId in
            let app = XCUIApplication(bundleIdentifier: appId)

            return app.state == .runningForeground
        }

        let response = ["runningAppBundleId": runningAppId ?? springboardBundleId]
        return response
    }
}
