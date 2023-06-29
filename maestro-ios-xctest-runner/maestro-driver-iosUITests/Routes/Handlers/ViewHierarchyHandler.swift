import FlyingFox
import XCTest
import os

@MainActor
struct ViewHierarchyHandler: HTTPHandler {

    let maxDepth = 60
    let springboardApplication = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )

    func handleRequest(_ request: FlyingFox.HTTPRequest) async throws -> HTTPResponse {
        guard let requestBody = try? JSONDecoder().decode(ViewHierarchyRequest.self, from: request.body) else {
            let errorInfo = [
                "errorMessage": "incorrect request body provided",
            ]
            let body = try? JSONEncoder().encode(errorInfo)
            return HTTPResponse(statusCode: .badRequest, body: body ?? Data())
        }

        let appId = requestBody.appId

        do {
            let viewHierarchy = try logger.measure(message: "View hierarchy snapshot for \(appId)") {
                try getViewHierarchy(appId: appId)
            }

            let body = try JSONEncoder().encode(viewHierarchy)

            // TODO: Remove debug print here
            print(String(data: body, encoding: .utf8)!)

            return HTTPResponse(statusCode: .ok, body: body)
        } catch {
            print(error)
            let errorInfo = [
                "errorMessage": "Snapshot failure while getting view hierarchy. Error: \(error)",
            ]
            let body = try? JSONEncoder().encode(errorInfo)
            return HTTPResponse(statusCode: .internalServerError, body: body ?? Data())
        }
    }

    func getViewHierarchy(appId: String) throws -> AXElement {
        SystemPermissionHelper.handleSystemPermissionAlertIfNeeded(springboardApplication: springboardApplication)

        // Fetch the view hierarchy of the springboard application
        // to make it possible to interact with the home screen.
        // Ignore any errors on fetching the springboard hierarchy.
        let springboardHierarchy: AXElement?
        do {
            springboardHierarchy = try elementHierarchy(xcuiElement: springboardApplication)
        } catch {
            print("Springboard hierarchy failed to fetch: \(error)")
            springboardHierarchy = nil
        }

        let appHierarchy = try appHierarchy(XCUIApplication(bundleIdentifier: appId))

        return AXElement(children: [
            springboardHierarchy,
            appHierarchy,
        ].compactMap { $0 })
    }

    func appHierarchy(_ xcuiApplication: XCUIApplication) throws -> AXElement {
        AXClientSwizzler.overwriteDefaultParameters["maxDepth"] = maxDepth
        return try elementHierarchyWithFallback(element: xcuiApplication)
    }

    func elementHierarchyWithFallback(element: XCUIElement) throws -> AXElement {
        do {
            var hierarchy = try elementHierarchy(xcuiElement: element)
            let hierarchyDepth = hierarchy.depth()

            if hierarchyDepth < maxDepth {
                logger.info("Hierarchy dept below maxdepth \(hierarchyDepth)")
                return hierarchy
            }

            // When the hierarchy depth is equal to maxDepth, it is unknown if
            // the hierarchy contains everything (it may be limited by the maxDepth).
            // To handle this case, for each child of the current node the hierarchy
            // is fetched again (recursively). This repeats until a hierarchy is found
            // smaller than maxDepth, the result will contain all nodes in the hierarchy.
            // Also if the hierarchy was deeper than maxDepth.

            let elementChildren = logger.measure(message: "Get element children") {
                element
                    .children(matching: .any)
                    .allElementsBoundByIndex
            }

            hierarchy.children = try elementChildren
                .map { try elementHierarchyWithFallback(element: $0) }

            return hierarchy

        } catch {
            // In apps with bigger view hierarchys, calling
            // `XCUIApplication().snapshot().dictionaryRepresentation` or `XCUIApplication().allElementsBoundByIndex`
            // throws "Error kAXErrorIllegalArgument getting snapshot for element <AXUIElementRef 0x6000025eb660>"
            // We recover by selecting the first child of the app element,
            // which should be the window, and continue from there.

            let recoveryElement = findRecoveryElement(element)
            let hierarchy = try elementHierarchyWithFallback(element: recoveryElement)
            return hierarchy
        }
    }

    let useFirstParentWithMultipleChildren = false
    func findRecoveryElement(_ element: XCUIElement) -> XCUIElement {
        if !useFirstParentWithMultipleChildren {
            return element
                .children(matching: .any)
                .firstMatch
        } else {
            if element.children(matching: .any).count > 1 {
                return element
            } else {
                return findRecoveryElement(element.children(matching: .any).firstMatch)
            }
        }
    }

    func elementHierarchy(xcuiElement: XCUIElement) throws -> AXElement {
        return try logger.measure(message: "Take element snapshot") {
            let snapshotDictionary = try xcuiElement.snapshot().dictionaryRepresentation
            return AXElement(snapshotDictionary)
        }
    }
}