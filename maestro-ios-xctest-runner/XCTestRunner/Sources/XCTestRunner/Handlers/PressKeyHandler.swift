import Foundation
import os
import XCTest

@MainActor
struct PressKeyHandler: JSONHandler {
    typealias RequestBody = PressKeyRequest

    private let typingFrequency = 30

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: PressKeyRequest) async throws {
        var eventPath = PointerEventPath.pathForTextInput()
        eventPath.type(text: requestBody.xctestKey, typingSpeed: typingFrequency)
        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.add(eventPath)
        try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord)
    }
}
