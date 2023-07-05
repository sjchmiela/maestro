import FlyingFox
import XCTest
import os

@MainActor
struct SwipeRouteHandlerV2: JSONHandler {
    typealias RequestBody = SwipeRequest

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: SwipeRequest) async throws {
        let description = "Swipe from \(requestBody.start) to \(requestBody.end) with \(requestBody.duration) duration"
        logger.info("\(description)")

        let eventTarget = EventTarget(bundleId: requestBody.appId)
        try await eventTarget.dispatchEvent(description: description) {
            EventRecord(orientation: .portrait)
                .addSwipeEvent(
                    start: requestBody.start,
                    end: requestBody.end,
                    duration: requestBody.duration)
        }
    }
}
