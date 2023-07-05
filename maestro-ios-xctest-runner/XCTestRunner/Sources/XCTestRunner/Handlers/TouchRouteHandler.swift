import Foundation
import XCTest

@MainActor
struct TouchRouteHandler: JSONHandler {
    typealias RequestBody = TouchRequest

    private let logger = loggerFor(Self.self)

    func handleJSONRequest(_ requestBody: TouchRequest) async throws {
        if requestBody.duration != nil {
            logger.info("Long pressing \(requestBody.x), \(requestBody.y) for \(requestBody.duration!)s")
        } else {
            logger.info("Tapping \(requestBody.x), \(requestBody.y)")
        }

        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.addPointerTouchEvent(
            at: CGPoint(x: CGFloat(requestBody.x), y: CGFloat(requestBody.y)),
            touchUpAfter: requestBody.duration
        )

        do {
            try await logger.measureAsync(message: "Tapping element") {
                try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord)
            }
        } catch {
            logger.error("Error tapping: \(error)")
            throw AppError(message: "Error tapping: \(error)")
        }
    }
}
