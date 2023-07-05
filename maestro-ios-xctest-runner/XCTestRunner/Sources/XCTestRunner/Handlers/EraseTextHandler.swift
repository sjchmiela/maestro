import Foundation
import os
import XCTest

@MainActor
struct EraseTextHandler: JSONHandler {
    typealias RequestBody = EraseTextRequest

    private let typingFrequency = 30

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: EraseTextRequest) async throws {
        let deleteText = String(repeating: XCUIKeyboardKey.delete.rawValue, count: requestBody.charactersToErase)
        var eventPath = PointerEventPath.pathForTextInput()
        eventPath.type(text: deleteText, typingSpeed: typingFrequency)
        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.add(eventPath)
        try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord)
    }
}
