//
//  UIImageView+VVWebCache.swift
//  VVWebImage
//

import UIKit

extension UIImageView: VVWebCache {
    /// Sets image with resource, placeholder, custom opotions
    ///
    /// - Parameters:
    ///   - resource: image resource specifying how to download and cache image
    ///   - placeholder: placeholder image displayed when loading image
    ///   - options: options for some behaviors
    ///   - editor: editor specifying how to edit and cache image in memory
    ///   - progress: a closure called while image is downloading
    ///   - completion: a closure called when image loading is finished
    public func vv_setImage(with resource: VVWebCacheResource,
                            placeholder: UIImage? = nil,
                            options: VVWebImageOptions = .none,
                            editor: VVWebImageEditor? = nil,
                            progress: VVImageDownloaderProgress? = nil,
                            completion: VVWebImageManagerCompletion? = nil) {
        let setImage: VVSetImage = { [weak self] (image) in
            if let self = self { self.image = image }
        }
        vv_setImage(with: resource,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: vv_imageLoadTaskKey,
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    /// Cancels image loading task
    public func vv_cancelImageLoadTask() {
        vv_webCacheOperation.task(forKey: vv_imageLoadTaskKey)?.cancel()
    }
    
    public var vv_imageLoadTaskKey: String { return classForCoder.description() }
    
    /// Sets highlighted image with resource, placeholder, custom opotions
    ///
    /// - Parameters:
    ///   - resource: image resource specifying how to download and cache image
    ///   - placeholder: placeholder image displayed when loading image
    ///   - options: options for some behaviors
    ///   - editor: editor specifying how to edit and cache image in memory
    ///   - progress: a closure called while image is downloading
    ///   - completion: a closure called when image loading is finished
    public func vv_setHighlightedImage(with resource: VVWebCacheResource,
                                       placeholder: UIImage? = nil,
                                       options: VVWebImageOptions = .none,
                                       editor: VVWebImageEditor? = nil,
                                       progress: VVImageDownloaderProgress? = nil,
                                       completion: VVWebImageManagerCompletion? = nil) {
        let setImage: VVSetImage = { [weak self] (image) in
            if let self = self { self.highlightedImage = image }
        }
        vv_setImage(with: resource,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: vv_highlightedImageLoadTaskKey,
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    /// Cancels highlighted image loading task
    public func vv_cancelHighlightedImageLoadTask() {
        vv_webCacheOperation.task(forKey: vv_highlightedImageLoadTaskKey)?.cancel()
    }
    
    public var vv_highlightedImageLoadTaskKey: String { return classForCoder.description() + "Highlighted" }
}
