//
//  DispatchQueue+Safe.swift
//  VVWebImage
//

import UIKit

extension DispatchQueue {
    func vv_safeAsync(_ work: @escaping () -> Void) {
        if label == String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) {
            work()
        } else {
            async(execute: work)
        }
    }
    
    func vv_safeSync(_ work: @escaping () -> Void) {
        if label == String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) {
            work()
        } else {
            sync(execute: work)
        }
    }
}
