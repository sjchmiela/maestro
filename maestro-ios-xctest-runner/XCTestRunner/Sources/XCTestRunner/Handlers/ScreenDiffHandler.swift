import Foundation
import XCTest
import CryptoKit
import FlyingFox
import os

@MainActor
struct IsScreenStaticHandler: JSONHandler {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: Void) async throws -> [String: Bool] {
        let screenshot1 = XCUIScreen.main.screenshot()
        let screenshot2 = XCUIScreen.main.screenshot()
        let hash1 = SHA256.hash(data: screenshot1.pngRepresentation)
        let hash2 = SHA256.hash(data: screenshot2.pngRepresentation)

        let isScreenStatic = hash1 == hash2

        let response = ["isScreenStatic" : isScreenStatic]
        return response
    }
}
