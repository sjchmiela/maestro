import FlyingFox
import XCTest
import os

@MainActor
struct SwipeRouteHandler: JSONHandler {
    typealias RequestBody = SwipeRequest

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: SwipeRequest) async throws {
        try await swipePrivateAPI(
            start: requestBody.start,
            end: requestBody.end,
            duration: requestBody.duration)
    }

    func swipePrivateAPI(start: CGPoint, end: CGPoint, duration: Double) async throws {
        logger.info("Swiping from \(start.debugDescription) to \(end.debugDescription) with \(duration) duration")

        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.addSwipeEvent(start: start, end: end, duration: duration)

        try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord)
    }
}
