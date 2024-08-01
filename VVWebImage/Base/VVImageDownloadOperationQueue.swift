//
//  VVImageDownloadOperationQueue.swift
//  VVWebImage
//

import UIKit

// 定义一个链表节点类，用于存储下载操作
private class VVImageDownloadNode {
    // 前一个节点的弱引用
    fileprivate weak var prev: VVImageDownloadNode?
    // 后一个节点的弱引用
    fileprivate weak var next: VVImageDownloadNode?
    // 节点的键，即URL
    fileprivate var key: URL
    // 节点的值，即下载操作
    fileprivate var value: VVImageDownloadOperationProtocol
    
    // 初始化方法，传入键和值
    fileprivate init(key: URL, value: VVImageDownloadOperationProtocol) {
        self.key = key
        self.value = value
    }
}

// 定义一个链表类，用于存储下载操作
private class VVImageDownloadLinkedMap {
    // 存储节点的字典
    fileprivate var map: [URL : VVImageDownloadNode]
    // 链表的头节点
    fileprivate var head: VVImageDownloadNode?
    // 链表的尾节点
    fileprivate var tail: VVImageDownloadNode?
    
    // 初始化方法b
    init() { map = [:] }
    
    // 入队方法，将节点添加到链表尾部
    fileprivate func enqueue(_ node: VVImageDownloadNode) {
        map[node.key] = node
        if head == nil {
            head = node
            tail = node
        } else {
            tail?.next = node
            node.prev = tail
            tail = node
        }
    }
    
    // 出队方法，将链表头部的节点移除并返回
    fileprivate func dequeue() -> VVImageDownloadNode? {
        if let node = head {
            remove(node)
            return node
        }
        return nil
    }
    
    // 移除节点方法，将节点从链表中移除
    fileprivate func remove(_ node: VVImageDownloadNode) {
        map[node.key] = nil
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if head === node { head = node.next }
        if tail === node { tail = node.prev }
    }
}

// 定义一个下载操作队列类
class VVImageDownloadOperationQueue {
    // 等待队列，存储普通下载操作
    private let waitingQueue: VVImageDownloadLinkedMap
    // 预加载等待队列，存储预加载下载操作
    private let preloadWaitingQueue: VVImageDownloadLinkedMap
    // 最大同时运行数
    var maxRunningCount: Int
    // 当前正在运行数
    private(set) var currentRunningCount: Int
    
    // 初始化方法
    init() {
        waitingQueue = VVImageDownloadLinkedMap()
        preloadWaitingQueue = VVImageDownloadLinkedMap()
        maxRunningCount = 1
        currentRunningCount = 0
    }
    
    // 添加下载操作方法
    func add(_ operation: VVImageDownloadOperationProtocol, preload: Bool) {
        // 如果当前正在运行数小于最大同时运行数，则直接开始下载操作
        if currentRunningCount < maxRunningCount {
            currentRunningCount += 1
            VVDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                operation.start()
            }
        } else {
            // 否则将下载操作添加到等待队列中
            let node = VVImageDownloadNode(key: operation.url, value: operation)
            if preload { preloadWaitingQueue.enqueue(node) }
            else { waitingQueue.enqueue(node) }
        }
    }
    
    // 移除下载操作方法
    func removeOperation(forKey key: URL) {
        // 如果等待队列中存在该下载操作，则将其移除
        if let node = waitingQueue.map[key] {
            waitingQueue.remove(node)
        } else if let node = preloadWaitingQueue.map[key] {
            // 如果预加载等待队列中存在该下载操作，则将其移除
            preloadWaitingQueue.remove(node)
        } else if let next = waitingQueue.dequeue()?.value {
            // 如果等待队列不为空，则从等待队列中取出一个下载操作开始下载
            VVDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                next.start()
            }
        } else if let next = preloadWaitingQueue.dequeue()?.value {
            // 如果预加载等待队列不为空，则从预加载等待队列中取出一个下载操作开始下载
            VVDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                next.start()
            }
        } else {
            // 如果等待队列和预加载等待队列都为空，则将当前正在运行数减一
            currentRunningCount -= 1
            assert(currentRunningCount >= 0, "currentRunningCount must >= 0")
        }
    }
    
    // 升级预加载下载操作方法
    func upgradePreloadOperation(for key: URL) {
        // 如果预加载等待队列中存在该下载操作，则将其从预加载等待队列中移除，并添加到等待队列中
        if let node = preloadWaitingQueue.map[key] {
            preloadWaitingQueue.remove(node)
            node.prev = nil
            node.next = nil
            waitingQueue.enqueue(node)
        }
    }
}
