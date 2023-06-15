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
            if SubTreeRouteHandler.shouldSwizzleMaxDepth {
                AccessibilityInterfaceProxy(maxDepth: 2147483647).configureMaxDepth()
                SubTreeRouteHandler.shouldSwizzleMaxDepth = false
            }
            let springboardBundleId = "com.apple.springboard"
            
            logger.info("Trying to capture hierarchy snapshot for \(appId)")
            let start = NSDate().timeIntervalSince1970 * 1000
            
            let springboardApplication = XCUIApplication(bundleIdentifier: springboardBundleId)
            
            SystemPermissionHelper.handleSystemPermissionAlertIfNeeded(springboardApplication: springboardApplication)
            
            let viewHierarchyDictionary = try getViewHieararchyDictionary(appId: appId, xcuiElement: xcuiApplication)
            
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
            let errorJson = """
                 { "errorMessage" : "Snapshot failure while getting view hierarchy", "errorCode": "\(errorCode)" }
                """
            return HTTPResponse(statusCode: .badRequest, body:  Data(errorJson.utf8))
        }
    }
    
    private func getViewHieararchyDictionary(appId: String, xcuiElement: XCUIElement) throws -> [XCUIElement.AttributeName: Any] {
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
