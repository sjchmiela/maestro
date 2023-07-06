
import Foundation
import FlyingFox

protocol JSONHandler: HTTPHandler {
    associatedtype RequestBody = Void
    associatedtype ResponseBody = Void
    func handleJSONRequest(_ requestBody: RequestBody) async throws -> ResponseBody
    func requestBody(from request: HTTPRequest) throws -> RequestBody
    func responseData(from responseBody: ResponseBody) throws -> Data
}

extension JSONHandler where RequestBody == Void {
    func requestBody(from request: HTTPRequest) { }
}

extension JSONHandler where RequestBody: Decodable {
    func requestBody(from request: HTTPRequest) throws -> RequestBody {
        guard let requestBody = try? JSONDecoder().decode(RequestBody.self, from: request.body) else {
            let type = type(of: RequestBody.self)
            throw AppError(type: .precondition, message: "Incorrect request body provided for \(type)")
        }
        return requestBody
    }
}

extension JSONHandler where ResponseBody == Void {
    func responseData(from responseBody: ResponseBody) -> Data { Data() }
}

extension JSONHandler where ResponseBody: Encodable {
    func responseData(from responseBody: ResponseBody) throws -> Data {
        try JSONEncoder().encode(responseBody)
    }
}

extension JSONHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let requestBody = try requestBody(from: request)
            let response = try await handleJSONRequest(requestBody)
            let responseData = try responseData(from: response)
            return HTTPResponse(statusCode: .ok, body: responseData)
        } catch let error as AppError {
            return error.httpResponse
        } catch {
            return AppError(error).httpResponse
        }
    }
}
