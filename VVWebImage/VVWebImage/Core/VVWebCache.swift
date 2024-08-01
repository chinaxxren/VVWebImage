//
//  VVWebCache.swift
//  VVWebImage
//

import UIKit

public typealias VVSetImage = (UIImage?) -> Void

private var webCacheOperationKey: Void?

/// VVWebCache defines image loading, editing and setting behaivors
public protocol VVWebCache: AnyObject {
    func vv_setImage(with resource: VVWebCacheResource,
                     placeholder: UIImage?,
                     options: VVWebImageOptions,
                     editor: VVWebImageEditor?,
                     taskKey: String,
                     setImage: @escaping VVSetImage,
                     progress: VVImageDownloaderProgress?,
                     completion: VVWebImageManagerCompletion?)
}

/// VVWebCacheOperation contains image loading tasks (VVWebImageLoadTask) for VVWebCache object
public class VVWebCacheOperation {
    private let weakTaskMap: NSMapTable<NSString, VVWebImageLoadTask>
    private var downloadProgressDic: [String : Double]
    private var lock: pthread_mutex_t
    
    public init() {
        weakTaskMap = NSMapTable(keyOptions: .strongMemory, valueOptions: .weakMemory)
        downloadProgressDic = [:]
        lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
    }
    
    public func task(forKey key: String) -> VVWebImageLoadTask? {
        pthread_mutex_lock(&lock)
        let task = weakTaskMap.object(forKey: key as NSString)
        pthread_mutex_unlock(&lock)
        return task
    }
    
    public func setTask(_ task: VVWebImageLoadTask, forKey key: String) {
        pthread_mutex_lock(&lock)
        weakTaskMap.setObject(task, forKey: key as NSString)
        pthread_mutex_unlock(&lock)
    }
    
    public func downloadProgress(forKey key: String) -> Double {
        pthread_mutex_lock(&lock)
        let p = downloadProgressDic[key] ?? 0
        pthread_mutex_unlock(&lock)
        return p
    }
    
    public func setDownloadProgress(_ downloadProgress: Double, forKey key: String) {
        pthread_mutex_lock(&lock)
        downloadProgressDic[key] = downloadProgress
        pthread_mutex_unlock(&lock)
    }
}

/// Default behaivor of VVWebCache
public extension VVWebCache {
    var vv_webCacheOperation: VVWebCacheOperation {
        if let operation = objc_getAssociatedObject(self, &webCacheOperationKey) as? VVWebCacheOperation { return operation }
        let operation = VVWebCacheOperation()
        objc_setAssociatedObject(self, &webCacheOperationKey, operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return operation
    }
    
    func vv_setImage(with resource: VVWebCacheResource,
                     placeholder: UIImage? = nil,
                     options: VVWebImageOptions = .none,
                     editor: VVWebImageEditor? = nil,
                     taskKey: String,
                     setImage: @escaping VVSetImage,
                     progress: VVImageDownloaderProgress? = nil,
                     completion: VVWebImageManagerCompletion? = nil) {
        let webCacheOperation = vv_webCacheOperation
        webCacheOperation.task(forKey: taskKey)?.cancel()
        webCacheOperation.setDownloadProgress(0 ,forKey: taskKey)
        if !options.contains(.ignorePlaceholder) {
            DispatchQueue.main.vv_safeSync { [weak self] in
                if self != nil { setImage(placeholder) }
            }
        }
        var currentProgress = progress
        var sentinel: Int32 = 0
        if options.contains(.progressiveDownload) {
            currentProgress = { [weak self] (data, expectedSize, image) in
                guard let self = self else { return }
                guard let partialData = data,
                    expectedSize > 0,
                    let partialImage = image else {
                        progress?(data, expectedSize, nil)
                        return
                }
                var displayImage = partialImage
                if let currentEditor = editor,
                    let currentImage = currentEditor.edit(partialImage) {
                    currentImage.vv_imageEditKey = currentEditor.key
                    currentImage.vv_imageFormat = partialData.vv_imageFormat
                    displayImage = currentImage
                } else if !options.contains(.ignoreImageDecoding),
                    let currentImage = VVWebImageManager.shared.imageCoder.decompressedImage(with: partialImage, data: partialData) {
                    displayImage = currentImage
                }
                let downloadProgress = min(1, Double(partialData.count) / Double(expectedSize))
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let webCacheOperation = self.vv_webCacheOperation
                    guard let task = webCacheOperation.task(forKey: taskKey),
                        task.sentinel == sentinel,
                        !task.isCancelled,
                        webCacheOperation.downloadProgress(forKey: taskKey) < downloadProgress else { return }
                    setImage(displayImage)
                    webCacheOperation.setDownloadProgress(downloadProgress, forKey: taskKey)
                }
                if let userProgress = progress {
                    let webCacheOperation = self.vv_webCacheOperation
                    if let task = webCacheOperation.task(forKey: taskKey),
                        task.sentinel == sentinel,
                        !task.isCancelled {
                        userProgress(partialData, expectedSize, displayImage)
                    }
                }
            }
        }
        let task = VVWebImageManager.shared.loadImage(with: resource, options: options, editor: editor, progress: currentProgress) { [weak self] (image: UIImage?, data: Data?, error: Error?, cacheType: VVImageCacheType) in
            guard let self = self else { return }
            if let currentImage = image { setImage(currentImage) }
            if error == nil { self.vv_webCacheOperation.setDownloadProgress(1, forKey: taskKey) }
            completion?(image, data, error, cacheType)
        }
        webCacheOperation.setTask(task, forKey: taskKey)
        sentinel = task.sentinel
    }
}
