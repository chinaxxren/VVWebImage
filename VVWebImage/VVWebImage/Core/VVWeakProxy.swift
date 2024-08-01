//
//  VVWeakProxy.swift
//  VVWebImage
//

import UIKit

public class VVWeakProxy: NSObject {
    private weak var target: NSObjectProtocol?
    
    public init(target: NSObjectProtocol) {
        self.target = target
    }
    
    public override func responds(to aSelector: Selector!) -> Bool {
        return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}
