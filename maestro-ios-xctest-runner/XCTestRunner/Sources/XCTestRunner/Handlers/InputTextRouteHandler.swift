import Foundation
import XCTest
import os

@MainActor
struct InputTextRouteHandler: JSONHandler {
    typealias RequestBody = InputTextRequest

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    private enum Constants {
        static let typingFrequency = 30
        static let slowInputCharactersCount = 1
    }

    func handleJSONRequest(_ requestBody: InputTextRequest) async throws {
        let start = Date()

        // due to different keyboard input listener events (i.e. autocorrection or hardware keyboard connection)
        // characters after the first on are often skipped, so we'll input it with lower typing frequency
        let firstCharacter = String(requestBody.text.prefix(Constants.slowInputCharactersCount))
        logger.info("first character: \(firstCharacter)")
        var eventPath = PointerEventPath.pathForTextInput()
        eventPath.type(text: firstCharacter, typingSpeed: 1)
        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.add(eventPath)
        try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord)

        if (requestBody.text.count > Constants.slowInputCharactersCount) {
            let remainingText = String(requestBody.text.suffix(requestBody.text.count - Constants.slowInputCharactersCount))
            logger.info("remaining text: \(remainingText)")
            var eventPath2 = PointerEventPath.pathForTextInput()
            eventPath2.type(text: remainingText, typingSpeed: Constants.typingFrequency)
            let eventRecord2 = EventRecord(orientation: .portrait)
            _ = eventRecord2.add(eventPath2)
            try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord2)
        }

        let duration = Date().timeIntervalSince(start)
        logger.info("Text input duration took \(duration)")
    }
}
