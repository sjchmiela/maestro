import Foundation
import FlyingFox
import os

@MainActor
struct SetPermissionsHandler: JSONHandler {
    typealias RequestBody = SetPermissionsRequest

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: SetPermissionsRequest) async throws {
        guard let encoded = try? JSONEncoder().encode(requestBody.permissions) else {
            throw AppError(type: .precondition, message: "permissions data not json encodable")
        }

        UserDefaults.standard.set(encoded, forKey: "permissions")
    }
}
