
import Foundation
import os

func loggerFor(_ type: some Any) -> Logger {
    Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: type.self)
    )
}

extension Logger {
    func measure<T>(message: String, _ block: () throws -> T) rethrows -> T {
        let start = Date()
        info("\(message) - start")

        let result = try block()

        let duration = Date().timeIntervalSince(start)
        info("\(message) - duration \(duration)")

        return result
    }

    // Unfortunately reasync is not yet implemented in swift..
    func measureAsync<T>(message: String, _ block: () async throws -> T) async rethrows -> T {
        let start = Date()
        info("\(message) - start")

        let result = try await block()

        let duration = Date().timeIntervalSince(start)
        info("\(message) - duration \(duration)")

        return result
    }

}
