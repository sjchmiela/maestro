import Foundation
import FlyingFox

public struct XCTestHTTPServer {
    public init() {}
    
    public func start() async throws {
        let port = ProcessInfo.processInfo.environment["PORT"]?.toUInt16()
        let server = HTTPServer(address: .loopback(port: port ?? 22087))

        XCUIApplicationProcessSwizzler.setup

        let routes: [(route: HTTPRoute, handler: HTTPHandler)] = await [
            ("subTree", SubTreeRouteHandler()),
            ("runningApp", RunningAppRouteHandler()),
            ("swipe", SwipeRouteHandler()),
            ("swipeV2", SwipeRouteHandlerV2()),
            ("inputText", InputTextRouteHandler()),
            ("touch", TouchRouteHandler()),
            ("screenshot", ScreenshotHandler()),
            ("isScreenStatic", IsScreenStaticHandler()),
            ("pressKey", PressKeyHandler()),
            ("pressButton", PressButtonHandler()),
            ("eraseText", EraseTextHandler()),
            ("deviceInfo", DeviceInfoHandler()),
            ("setPermissions", SetPermissionsHandler()),
            ("viewHierarchy", ViewHierarchyHandler()),
        ]

        for route in routes {
            await server.appendRoute(route.route, to: route.handler)
        }

        try await server.start()
    }
}
