
import Foundation
import os

func loggerFor(_ type: some Any) -> Logger {
    Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: type.self)
    )
}
