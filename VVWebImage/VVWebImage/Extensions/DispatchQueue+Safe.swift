//
//  DispatchQueue+Safe.swift
//  VVWebImage
//

import UIKit

extension DispatchQueue {
    // 在当前队列中执行任务，如果当前队列不是主队列，则异步执行任务
    func vv_safeAsync(_ work: @escaping () -> Void) {
        if label == String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) {
            work()
        } else {
            async(execute: work)
        }
    }

    // 在当前队列中执行任务，如果当前队列不是主队列，则同步执行任务
    func vv_safeSync(_ work: @escaping () -> Void) {
        if label == String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) {
            work()
        } else {
            sync(execute: work)
        }
    }
}