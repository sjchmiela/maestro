import FlyingFox
import XCTest
import os

@MainActor
struct SubTreeRouteHandler: HTTPHandler {
    
    private static var shouldSwizzleMaxDepth = false
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    func handleRequest(_ request: FlyingFox.HTTPRequest) async throws -> FlyingFox.HTTPResponse {
        guard let appId = request.query["appId"] else {
            logger.error("Requested view hierarchy for an invalid appId")
            return HTTPResponse(statusCode: HTTPStatusCode.badRequest)
        }
        let xcuiApplication = XCUIApplication(bundleIdentifier: appId)
        
        do {
            let springboardBundleId = "com.apple.springboard"
            
            logger.info("Trying to capture hierarchy snapshot for \(appId)")
            let start = NSDate().timeIntervalSince1970 * 1000
            
            let springboardApplication = XCUIApplication(bundleIdentifier: springboardBundleId)
            
            SystemPermissionHelper.handleSystemPermissionAlertIfNeeded(springboardApplication: springboardApplication)
            
            let viewHierarchyDictionary = try getViewHieararchyDictionary(
                appId: appId,
                xcuiElement: xcuiApplication,
                includeKeyboard: false,
                xcuiApplication: xcuiApplication
            )
            
            let end = NSDate().timeIntervalSince1970 * 1000
            logger.info("Successfully got view hierarchy for \(appId) in \(end - start)")
            let hierarchyJsonData = try JSONSerialization.data(
                withJSONObject: viewHierarchyDictionary,
                options: .prettyPrinted
            )
            return HTTPResponse(statusCode: .ok, body: hierarchyJsonData)
        } catch let error {
            let message = error.localizedDescription
            logger.error("Snapshot failure, cannot return view hierarchy due to \(message)")
            let errorCode = getErrorCode(message: message)
            if errorCode == "illegal-argument-snapshot-failure" {
                if !SubTreeRouteHandler.shouldSwizzleMaxDepth {
                    AccessibilityInterfaceProxy().configureMaxDepth()
                    SubTreeRouteHandler.shouldSwizzleMaxDepth = true
                }
                let xcuiElement = try getDeepestRootElement(app: xcuiApplication)
                let viewHierarchyDictionary = try getViewHieararchyDictionary(
                    appId: appId,
                    xcuiElement: xcuiElement,
                    includeKeyboard: true,
                    xcuiApplication: xcuiApplication
                )
                let hierarchyJsonData = try JSONSerialization.data(
                    withJSONObject: viewHierarchyDictionary,
                    options: .prettyPrinted
                )
                return HTTPResponse(statusCode: .ok, body: hierarchyJsonData)
            } else {
                let errorJson = """
                     { "errorMessage" : "Snapshot failure while getting view hierarchy", "errorCode": "\(errorCode)" }
                    """
                return HTTPResponse(statusCode: .badRequest, body:  Data(errorJson.utf8))
            }
        }
    }
    
    func getDeepestRootElement(app: XCUIApplication) throws ->  XCUIElement {
        var element: XCUIElement
        let windowElement = app.children(matching: XCUIElement.ElementType.any).firstMatch
        element = windowElement
        while(try isDeepestWindowRoot(element: element, window: windowElement)) {
            element = element.children(matching: XCUIElement.ElementType.other).firstMatch
        }

        return element
    }
    
    func isDeepestWindowRoot(element: XCUIElement, window: XCUIElement) throws -> Bool {
        return try element.snapshot().children.count == 1 && element.children(matching: XCUIElement.ElementType.other).firstMatch.exists
            && element.children(matching: XCUIElement.ElementType.other).firstMatch.frame == window.frame
    }
    
    private func getViewHieararchyDictionary(
        appId: String,
        xcuiElement: XCUIElement,
        includeKeyboard: Bool,
        xcuiApplication: XCUIApplication
    ) throws -> [XCUIElement.AttributeName: Any] {
        let springboardBundleId = "com.apple.springboard"
        
        let springboardApplication = XCUIApplication(bundleIdentifier: springboardBundleId)
        
        logger.info("[Start] Now trying hierarchy for: \(appId)")
        var viewHierarchyDictionary = try xcuiElement.snapshot().dictionaryRepresentation
        logger.info("[Done] Now trying hierarchy for: \(appId)")
        logger.info("[Start] Now trying hierarchy for: \(springboardBundleId)")
        let springboardHierarchyDictionary = try springboardApplication.snapshot().dictionaryRepresentation
        logger.info("[Done] Now trying hierarchy for: \(springboardBundleId)")
        
        let children = viewHierarchyDictionary[XCUIElement.AttributeName(rawValue: "children")] as? Array<[XCUIElement.AttributeName: Any]>
        let springChildren = springboardHierarchyDictionary[XCUIElement.AttributeName(rawValue: "children")] as? Array<[XCUIElement.AttributeName: Any]>
        let unifiedChildren = (children ?? [[XCUIElement.AttributeName: Any]]()) + (springChildren ?? [[XCUIElement.AttributeName: Any]]())
        viewHierarchyDictionary.updateValue(unifiedChildren as Any, forKey: XCUIElement.AttributeName.children)
        
        if includeKeyboard && xcuiApplication.keyboards.firstMatch.exists {
            let keyboardHierarchyDictionary = try xcuiApplication.keyboards.firstMatch.snapshot().dictionaryRepresentation
            let keyboardChildren = keyboardHierarchyDictionary[XCUIElement.AttributeName(rawValue: "children")] as? Array<[XCUIElement.AttributeName: Any]>
            let unifiedChildren = (children ?? [[XCUIElement.AttributeName: Any]]()) + (springChildren ?? [[XCUIElement.AttributeName: Any]]())
                + (keyboardChildren ?? [[XCUIElement.AttributeName: Any]]())
            viewHierarchyDictionary.updateValue(unifiedChildren as Any, forKey: XCUIElement.AttributeName.children)
        }
        
        return viewHierarchyDictionary
    }
    
    
    private func getErrorCode(message: String) -> String {
        if message.contains("Error kAXErrorIllegalArgument getting snapshot for element") {
            return "illegal-argument-snapshot-failure"
        } else {
            return "unknown-snapshot-failure"
        }
    }
}
