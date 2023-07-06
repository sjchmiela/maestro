
import Foundation
import FlyingFox

enum AppErrorType: String {
    case `internal`
    case precondition
}

struct AppError: Error {
    let type: AppErrorType
    let message: String

    private var statusCode: HTTPStatusCode {
        switch type {
        case .internal: return .internalServerError
        case .precondition: return .badRequest
        }
    }

    var httpResponse: HTTPResponse {
        let body = try? JSONEncoder().encode(["errorMessage": message])
        return HTTPResponse(statusCode: statusCode, body: body ?? Data())
    }

    init(type: AppErrorType = .internal, message: String) {
        self.type = type
        self.message = message
    }

    init(_ error: Error) {
        self.type = .internal
        self.message = error.localizedDescription
    }

    var localizedDescription: String { message }
}
