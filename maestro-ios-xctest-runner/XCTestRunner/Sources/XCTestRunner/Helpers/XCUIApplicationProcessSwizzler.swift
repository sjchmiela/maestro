
import Foundation

struct XCUIApplicationProcessSwizzler {
    private init() {}

    // static let closures will only execute once, upon usage of the type
    static let setup: Void = {
        let clazz: AnyClass = objc_getClass("XCUIApplicationProcess") as! AnyClass
        let original = class_getInstanceMethod(clazz, Selector(("waitForQuiescenceIncludingAnimationsIdle:")))!
        let selector = #selector(Proxy.replace_waitForQuiescenceIncludingAnimationsIdle)
        let replaced = class_getInstanceMethod(Proxy.self, selector)!
        method_exchangeImplementations(original, replaced)
    }()
}

private class Proxy {
    @objc func replace_waitForQuiescenceIncludingAnimationsIdle() {
        // Swizzle waitForQuiescenceIncludingAnimationsIdle: with an
        // empty method.
        return
    }
}
