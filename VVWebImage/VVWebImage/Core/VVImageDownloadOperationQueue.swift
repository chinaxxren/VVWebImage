//
//  VVImageDownloadOperationQueue.swift
//  VVWebImage
//
//  Created by waqu on 2/1/19.
//  Copyright © 2019 waqu. All rights reserved.
//

import UIKit

private class VVImageDownloadLinkedMapNode {
    fileprivate weak var prev: VVImageDownloadLinkedMapNode?
    fileprivate weak var next: VVImageDownloadLinkedMapNode?
    fileprivate var key: URL
    fileprivate var value: VVImageDownloadOperationProtocol
    
    fileprivate init(key: URL, value: VVImageDownloadOperationProtocol) {
        self.key = key
        self.value = value
    }
}

private class VVImageDownloadLinkedMap {
    fileprivate var dic: [URL : VVImageDownloadLinkedMapNode]
    fileprivate var head: VVImageDownloadLinkedMapNode?
    fileprivate var tail: VVImageDownloadLinkedMapNode?
    
    init() { dic = [:] }
    
    fileprivate func enqueue(_ node: VVImageDownloadLinkedMapNode) {
        dic[node.key] = node
        if head == nil {
            head = node
            tail = node
        } else {
            tail?.next = node
            node.prev = tail
            tail = node
        }
    }
    
    fileprivate func dequeue() -> VVImageDownloadLinkedMapNode? {
        if let node = head {
            remove(node)
            return node
        }
        return nil
    }
    
    fileprivate func remove(_ node: VVImageDownloadLinkedMapNode) {
        dic[node.key] = nil
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if head === node { head = node.next }
        if tail === node { tail = node.prev }
    }
}

class VVImageDownloadOperationQueue {
    private let waitingQueue: VVImageDownloadLinkedMap
    private let preloadWaitingQueue: VVImageDownloadLinkedMap
    var maxRunningCount: Int
    private(set) var currentRunningCount: Int
    
    init() {
        waitingQueue = VVImageDownloadLinkedMap()
        preloadWaitingQueue = VVImageDownloadLinkedMap()
        maxRunningCount = 1
        currentRunningCount = 0
    }
    
    func add(_ operation: VVImageDownloadOperationProtocol, preload: Bool) {
        if currentRunningCount < maxRunningCount {
            currentRunningCount += 1
            VVDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                operation.start()
            }
        } else {
            let node = VVImageDownloadLinkedMapNode(key: operation.url, value: operation)
            if preload { preloadWaitingQueue.enqueue(node) }
            else { waitingQueue.enqueue(node) }
        }
    }
    
    func removeOperation(forKey key: URL) {
        if let node = waitingQueue.dic[key] {
            waitingQueue.remove(node)
        } else if let node = preloadWaitingQueue.dic[key] {
            preloadWaitingQueue.remove(node)
        } else if let next = waitingQueue.dequeue()?.value {
            VVDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                next.start()
            }
        } else if let next = preloadWaitingQueue.dequeue()?.value {
            VVDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                next.start()
            }
        } else {
            currentRunningCount -= 1
            assert(currentRunningCount >= 0, "currentRunningCount must >= 0")
        }
    }
    
    func upgradePreloadOperation(for key: URL) {
        if let node = preloadWaitingQueue.dic[key] {
            preloadWaitingQueue.remove(node)
            node.prev = nil
            node.next = nil
            waitingQueue.enqueue(node)
        }
    }
}
