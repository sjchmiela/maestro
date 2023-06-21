//
//  AccessibilityInterfaceProxy.swift
//  maestro-driver-iosUITests
//
//  Created by Amanjeet Singh on 15/06/23.
//

import Foundation
import XCTest

class AccessibilityInterfaceProxy {

    private let accessibilityInterface: NSObject

    init() {
        let sharedDevice = XCUIDevice.shared
        accessibilityInterface = sharedDevice.perform(NSSelectorFromString("accessibilityInterface"))
            .takeUnretainedValue() as! NSObject
    }

    func configureMaxDepth() {
        let original = class_getInstanceMethod(objc_getClass("XCAXClient_iOS") as? AnyClass, Selector(("defaultParameters")))
        let replaced = class_getInstanceMethod(type(of: self),
                                               #selector(AccessibilityInterfaceProxy.replace_defaultParameters))
        guard let original = original, let replaced = replaced else { return }
        method_exchangeImplementations(original, replaced)
    }

    @objc func replace_defaultParameters() -> NSDictionary {
        return [
            "maxArrayCount": 2147483647,
            "maxChildren": 2147483647,
            "maxDepth": 60 /* This was int max by default */ ,
            "traverseFromParentsToChildren": 1,
            "snapshotKeyHonorModalViews": 0
        ]
    }
}
