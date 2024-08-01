//
//  VVDispatchQueuePool.swift
//  VVWebImage
//

import UIKit

/// VVDispatchQueuePool holds mutiple serial queues.
/// To prevent concurrent queue increasing thread count, use this class to control thread count.
public class VVDispatchQueuePool {
    public static let userInteractive = VVDispatchQueuePool(label: "com.waqu.VVWebImage.QueuePool.userInteractive", qos: .userInteractive)
    public static let userInitiated = VVDispatchQueuePool(label: "com.waqu.VVWebImage.QueuePool.userInitiated", qos: .userInitiated)
    public static let utility = VVDispatchQueuePool(label: "com.waqu.VVWebImage.QueuePool.utility", qos: .utility)
    public static let `default` = VVDispatchQueuePool(label: "com.waqu.VVWebImage.QueuePool.default", qos: .default)
    public static let background = VVDispatchQueuePool(label: "com.waqu.VVWebImage.QueuePool.background", qos: .background)
    
    private let queues: [DispatchQueue]
    private var index: Int32
    
    /// Gets a dispatch queue from pool
    public var currentQueue: DispatchQueue {
        var currentIndex = OSAtomicIncrement32(&index)
        if currentIndex < 0 { currentIndex = -currentIndex }
        return queues[Int(currentIndex) % queues.count]
    }
    
    /// Creates a VVDispatchQueuePool object
    ///
    /// - Parameters:
    ///   - label: dispatch queue label
    ///   - qos: quality of service for dispatch queue
    ///   - queueCount: dispatch queue count
    public init(label: String, qos: DispatchQoS, queueCount: Int = 0) {
        let count = queueCount > 0 ? queueCount : min(16, max(1, ProcessInfo.processInfo.activeProcessorCount))
        var pool: [DispatchQueue] = []
        for i in 0..<count {
            let queue = DispatchQueue(label: "\(label).\(i)", qos: qos, target: DispatchQueue.global(qos: qos.qosClass))
            pool.append(queue)
        }
        queues = pool
        index = -1
    }
    
    /// Dispatches an asynchronous work to a dispatch queue from pool
    ///
    /// - Parameter work: work to dispatch
    public func async(work: @escaping () -> Void) {
        currentQueue.async(execute: work)
    }
}
