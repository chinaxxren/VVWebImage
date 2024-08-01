//
//  VVWeakProxy.swift
//  VVWebImage
//

import UIKit

public class VVWeakProxy: NSObject {
    // 定义一个弱引用的target属性
    private weak var target: NSObjectProtocol?
    
    // 初始化方法，传入一个NSObjectProtocol类型的target
    public init(target: NSObjectProtocol) {
        self.target = target
    }
    
    // 重写responds(to:)方法，判断target是否响应aSelector
    public override func responds(to aSelector: Selector!) -> Bool {
        return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }
    
    // 重写forwardingTarget(for:)方法，返回target
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}