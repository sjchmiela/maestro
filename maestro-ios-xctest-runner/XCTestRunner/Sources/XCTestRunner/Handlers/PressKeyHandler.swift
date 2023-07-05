import Foundation

@MainActor
struct PressKeyHandler: JSONHandler {
    typealias RequestBody = PressKeyRequest

    private let logger = loggerFor(Self.self)
    private let typingFrequency = 30

    func handleJSONRequest(_ requestBody: PressKeyRequest) async throws {
        var eventPath = PointerEventPath.pathForTextInput()
        eventPath.type(text: requestBody.xctestKey, typingSpeed: typingFrequency)
        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.add(eventPath)
        try await RunnerDaemonProxy().synthesize(eventRecord: eventRecord)
    }
}
