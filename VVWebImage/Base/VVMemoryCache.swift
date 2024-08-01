//
//  VVMemoryCache.swift
//  VVWebImage
//

import UIKit

/// VVMemoryCacheNode is a node in the linked list used by VVMemoryCache
private class VVMemoryCacheNode {
    // Weak var will slow down speed. So use strong var. Set all notes prev/next to nil when removing all nodes
    fileprivate var prev: VVMemoryCacheNode?
    fileprivate var next: VVMemoryCacheNode?
    
    /// The key of the node
    fileprivate var key: String
    /// The value of the node
    fileprivate var value: Any
    /// The cost of the node
    fileprivate var cost: Int
    /// The last access time of the node
    fileprivate var lastAccessTime: TimeInterval
    
    /// Initializes a new node with a key and value
    fileprivate init(key: String, value: Any) {
        self.key = key
        self.value = value
        self.cost = 0
        self.lastAccessTime = CACurrentMediaTime()
    }
}

/// VVMemoryCacheLinkedMap is a linked map used by VVMemoryCache to store nodes
private class VVMemoryCacheLinkedMap {
    /// The map of keys to nodes
    fileprivate var map: [String : VVMemoryCacheNode]
    /// The head of the linked list
    fileprivate var head: VVMemoryCacheNode?
    /// The tail of the linked list
    fileprivate var tail: VVMemoryCacheNode?
    /// The total cost of all nodes
    fileprivate var totalCost: Int
    /// The total count of all nodes
    fileprivate var totalCount: Int
    
    /// Deinitializes the linked map and breaks the retain cycle
    deinit { breakRetainCycle() }
    
    /// Initializes a new linked map
    init() {
        map = [:]
        totalCost = 0
        totalCount = 0
    }
    
    /// Brings a node to the head of the linked list
    ///
    /// - Parameter node: The node to bring to the head
    fileprivate func bringNodeToHead(_ node: VVMemoryCacheNode) {
        if head === node { return }
        if tail === node {
            tail = node.prev
            tail?.next = nil
        } else {
            node.prev?.next = node.next
            node.next?.prev = node.prev
        }
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
    }
    
    /// Inserts a node at the head of the linked list
    ///
    /// - Parameter node: The node to insert
    fileprivate func insertNodeAtHead(_ node: VVMemoryCacheNode) {
        map[node.key] = node
        if head == nil {
            head = node
            tail = node
        } else {
            node.next = head
            head?.prev = node
            head = node
        }
        totalCost += node.cost
        totalCount += 1
    }
    
    /// Removes a node from the linked list
    ///
    /// - Parameter node: The node to remove
    fileprivate func remove(_ node: VVMemoryCacheNode) {
        map[node.key] = nil
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if head === node { head = node.next }
        if tail === node { tail = node.prev }
        totalCost -= node.cost
        totalCount -= 1
    }
    
    /// Removes all nodes from the linked list
    fileprivate func removeAll() {
        map.removeAll()
        breakRetainCycle()
        head = nil
        tail = nil
        totalCost = 0
        totalCount = 0
    }
    
    /// Breaks the retain cycle of the linked list
    private func breakRetainCycle() {
        var node = head
        while let next = node?.next {
            next.prev = nil
            node = next
        }
    }
}

/// VVMemoryCache is a thread safe memory cache using least recently used algorithm
public class VVMemoryCache {
    /// The linked map used by the cache
    private let linkedMap: VVMemoryCacheLinkedMap
    /// The cost limit of the cache
    private var costLimit: Int
    /// The count limit of the cache
    private var countLimit: Int
    /// The age limit of the cache
    private var ageLimit: TimeInterval
    /// The lock used to ensure thread safety
    private var lock: pthread_mutex_t
    /// The queue used to perform background tasks
    private var queue: DispatchQueue
    
    /// Initializes a new memory cache
    init() {
        linkedMap = VVMemoryCacheLinkedMap()
        costLimit = .max
        countLimit = .max
        ageLimit = .greatestFiniteMagnitude
        lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
        queue = DispatchQueue(label: "com.waqu.VVWebImage.MemoryCache.queue", qos: .background)
        
        NotificationCenter.default.addObserver(self, selector: #selector(clear), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clear), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        trimRecursively()
    }
    
    /// Deinitializes the memory cache and removes all observers
    deinit {
        NotificationCenter.default.removeObserver(self)
        pthread_mutex_destroy(&lock)
    }
    
    /// Gets an image from the cache with a given key
    ///
    /// - Parameter key: The key of the image
    /// - Returns: The image if found, otherwise nil
    public func image(forKey key: String) -> UIImage? {
        pthread_mutex_lock(&lock)
        var value: UIImage?
        if let node = linkedMap.map[key] {
            value = node.value as? UIImage
            node.lastAccessTime = CACurrentMediaTime()
            linkedMap.bringNodeToHead(node)
        }
        pthread_mutex_unlock(&lock)
        return value
    }
    
    /// Stores an image in the cache with a given key and cost
    ///
    /// - Parameters:
    ///   - image: The image to store
    ///   - key: The key of the image
    ///   - cost: The cost of the image
    public func store(_ image: UIImage, forKey key: String, cost: Int = 0) {
        pthread_mutex_lock(&lock)
        let realCost: Int = cost > 0 ? cost : Int(image.size.width * image.size.height * image.scale)
        if let node = linkedMap.map[key] {
            linkedMap.totalCost += realCost - node.cost
            node.value = image
            node.cost = realCost
            node.lastAccessTime = CACurrentMediaTime()
            linkedMap.bringNodeToHead(node)
        } else {
            let node = VVMemoryCacheNode(key: key, value: image)
            node.cost = realCost
            linkedMap.insertNodeAtHead(node)
            
            if linkedMap.totalCount > countLimit,
                let tail = linkedMap.tail {
                linkedMap.remove(tail)
            }
        }
        if linkedMap.totalCost > costLimit {
            queue.async { [weak self] in
                guard let self = self else { return }
                self.trim(toCost: self.costLimit)
            }
        }
        pthread_mutex_unlock(&lock)
    }
    
    /// Removes an image from the cache with a given key
    ///
    /// - Parameter key: The key of the image
    public func removeImage(forKey key: String) {
        pthread_mutex_lock(&lock)
        if let node = linkedMap.map[key] {
            linkedMap.remove(node)
        }
        pthread_mutex_unlock(&lock)
    }
    
    /// Removes all images from the cache
    @objc public func clear() {
        pthread_mutex_lock(&lock)
        linkedMap.removeAll()
        pthread_mutex_unlock(&lock)
    }
    
    /// Sets the cost limit of the cache
    ///
    /// - Parameter cost: The cost limit
    public func setCostLimit(_ cost: Int) {
        pthread_mutex_lock(&lock)
        costLimit = cost
        queue.async { [weak self] in
            guard let self = self else { return }
            self.trim(toCost: cost)
        }
        pthread_mutex_unlock(&lock)
    }
    
    /// Sets the count limit of the cache
    ///
    /// - Parameter count: The count limit
    public func setCountLimit(_ count: Int) {
        pthread_mutex_lock(&lock)
        countLimit = count
        queue.async { [weak self] in
            guard let self = self else { return }
            self.trim(toCount: count)
        }
        pthread_mutex_unlock(&lock)
    }
    
    /// Sets the age limit of the cache
    ///
    /// - Parameter age: The age limit
    public func setAgeLimit(_ age: TimeInterval) {
        pthread_mutex_lock(&lock)
        ageLimit = age
        queue.async { [weak self] in
            guard let self = self else { return }
            self.trim(toAge: age)
        }
        pthread_mutex_unlock(&lock)
    }
    
    /// Trims the cache to a given cost
    ///
    /// - Parameter cost: The cost to trim to
    private func trim(toCost cost: Int) {
        pthread_mutex_lock(&lock)
        let unlock: () -> Void = { pthread_mutex_unlock(&self.lock) }
        if cost <= 0 {
            linkedMap.removeAll()
            return unlock()
        } else if linkedMap.totalCost <= cost {
            return unlock()
        }
        unlock()
        
        while true {
            if pthread_mutex_trylock(&lock) == 0 {
                if linkedMap.totalCost > cost,
                    let tail = linkedMap.tail {
                    linkedMap.remove(tail)
                } else {
                    return unlock()
                }
                unlock()
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
    }
    
    /// Trims the cache to a given count
    ///
    /// - Parameter count: The count to trim to
    private func trim(toCount count: Int) {
        pthread_mutex_lock(&lock)
        let unlock: () -> Void = { pthread_mutex_unlock(&self.lock) }
        if count <= 0 {
            linkedMap.removeAll()
            return unlock()
        } else if linkedMap.totalCount <= count {
            return unlock()
        }
        unlock()
        
        while true {
            if pthread_mutex_trylock(&lock) == 0 {
                if linkedMap.totalCount > count,
                    let tail = linkedMap.tail {
                    linkedMap.remove(tail)
                } else {
                    return unlock()
                }
                unlock()
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
    }
    
    /// Trims the cache to a given age
    ///
    /// - Parameter age: The age to trim to
    private func trim(toAge age: TimeInterval) {
        pthread_mutex_lock(&lock)
        let unlock: () -> Void = { pthread_mutex_unlock(&self.lock) }
        let now = CACurrentMediaTime()
        if age <= 0 {
            linkedMap.removeAll()
            return unlock()
        } else if linkedMap.tail == nil || now - linkedMap.tail!.lastAccessTime <= age {
            return unlock()
        }
        unlock()
        
        while true {
            if pthread_mutex_trylock(&lock) == 0 {
                if let tail = linkedMap.tail,
                    now - tail.lastAccessTime > age {
                    linkedMap.remove(tail)
                } else {
                    return unlock()
                }
                unlock()
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
    }
    
    /// Recursively trims the cache to the age limit
    private func trimRecursively() {
        queue.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.trim(toAge: self.ageLimit)
            self.trimRecursively()
        }
    }
}