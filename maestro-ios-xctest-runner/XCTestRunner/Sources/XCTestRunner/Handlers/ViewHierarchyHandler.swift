import FlyingFox
import XCTest
import os

@MainActor
struct ViewHierarchyHandler: JSONHandler {
    typealias RequestBody = ViewHierarchyRequest
    typealias ResponseBody = AXElement

    private static let springboardBundleId = "com.apple.springboard"
    private let springboardApplication = XCUIApplication(bundleIdentifier: Self.springboardBundleId)

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleJSONRequest(_ requestBody: ViewHierarchyRequest) async throws -> AXElement {
        let runningAppIds = requestBody.appIds
        let app = getForegroundApp(runningAppIds)

        guard let app = app else {
            let springboardHierarchy = try elementHierarchy(xcuiElement: springboardApplication)
            return springboardHierarchy
        }

        let viewHierarchy = try logger.measure(message: "View hierarchy snapshot for \(app)") {
            try getAppViewHierarchy(app: app)
        }

        return viewHierarchy
    }

    func getForegroundApp(_ runningAppIds: [String]) -> XCUIApplication? {
        runningAppIds
            .map { XCUIApplication(bundleIdentifier: $0) }
            .first { app in app.state == .runningForeground }
    }

    func getAppViewHierarchy(app: XCUIApplication) throws -> AXElement {
        SystemPermissionHelper.handleSystemPermissionAlertIfNeeded(springboardApplication: springboardApplication)

        // Fetch the view hierarchy of the springboard application
        // to make it possible to interact with the home screen.
        // Ignore any errors on fetching the springboard hierarchy.
        let springboardHierarchy: AXElement?
        do {
            springboardHierarchy = try elementHierarchy(xcuiElement: springboardApplication)
        } catch {
            logger.error("Springboard hierarchy failed to fetch: \(error)")
            springboardHierarchy = nil
        }

        let appHierarchy = try getHierarchyWithFallback(app)

        return AXElement(children: [
            springboardHierarchy,
            appHierarchy,
        ].compactMap { $0 })
    }

    func getHierarchyWithFallback(_ element: XCUIElement) throws -> AXElement {
        do {
            return try elementHierarchy(xcuiElement: element)
        } catch let error {
            guard isIllegalArgumentError(error) else {
                logger.error("Snapshot failure, cannot return view hierarchy due to \(error.localizedDescription)")
                throw AppError(message: error.localizedDescription)
            }

            logger.error("Snapshot failure, getting recovery element for fallback")
            // In apps with bigger view hierarchys, calling
            // `XCUIApplication().snapshot().dictionaryRepresentation` or `XCUIApplication().allElementsBoundByIndex`
            // throws "Error kAXErrorIllegalArgument getting snapshot for element <AXUIElementRef 0x6000025eb660>"
            // We recover by selecting the first child of the app element,
            // which should be the window, and continue from there.

            let recoveryElement = findRecoveryElement(element)
            let hierarchy = try getHierarchyWithFallback(recoveryElement)

            // When the application element is skipped, try to fetch
            // the keyboard and alert hierarchies separately.
            if let element = element as? XCUIApplication {
                let keyboard = logger.measure(message: "Fetch keyboard hierarchy") {
                    keyboardHierarchy(element)
                }

                let alerts = logger.measure(message: "Fetch alert hierarchy") {
                    fullScreenAlertHierarchy(element)
                }

                return AXElement(children: [
                    hierarchy,
                    keyboard,
                    alerts
                ].compactMap { $0 })
            }

            return hierarchy
        }
    }

    private func isIllegalArgumentError(_ error: Error) -> Bool {
        error.localizedDescription.contains("Error kAXErrorIllegalArgument getting snapshot for element")
    }

    private func keyboardHierarchy(_ element: XCUIApplication) -> AXElement? {
        guard element.keyboards.firstMatch.exists else {
            return nil
        }
        
        let keyboard = element.keyboards.firstMatch
        return try? elementHierarchy(xcuiElement: keyboard)
    }

    func fullScreenAlertHierarchy(_ element: XCUIApplication) -> AXElement? {
        guard element.alerts.firstMatch.exists else {
            return nil
        }
        
        let alert = element.alerts.firstMatch
        return try? elementHierarchy(xcuiElement: alert)
    }

    private func findRecoveryElement(_ element: XCUIElement) -> XCUIElement {
        return element
            .children(matching: .any)
            .firstMatch
    }

    private func elementHierarchy(xcuiElement: XCUIElement) throws -> AXElement {
        let snapshotDictionary = try xcuiElement.snapshot().dictionaryRepresentation
        return AXElement(snapshotDictionary)
    }
}