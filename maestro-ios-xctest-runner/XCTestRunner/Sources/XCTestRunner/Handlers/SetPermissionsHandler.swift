import Foundation

@MainActor
struct SetPermissionsHandler: JSONHandler {
    typealias RequestBody = SetPermissionsRequest

    private let logger = loggerFor(Self.self)

    func handleJSONRequest(_ requestBody: SetPermissionsRequest) async throws {
        guard let encoded = try? JSONEncoder().encode(requestBody.permissions) else {
            throw AppError(type: .precondition, message: "permissions data not json encodable")
        }

        UserDefaults.standard.set(encoded, forKey: "permissions")
    }
}
