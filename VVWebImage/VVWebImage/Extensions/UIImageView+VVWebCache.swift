//
//  UIImageView+VVWebCache.swift
//  VVWebImage
//

import UIKit

extension UIImageView: VVWebCache {
    /// 设置图片，使用资源、占位符、自定义选项
    ///
    /// - Parameters:
    ///   - resource: 指定如何下载和缓存图片的资源
    ///   - placeholder: 加载图片时显示的占位符图片
    ///   - options: 一些行为的选项
    ///   - editor: 指定如何在内存中编辑和缓存图片
    ///   - progress: 在图片下载过程中调用的闭包
    ///   - completion: 图片加载完成后调用的闭包
    public func vv_setImage(with resource: VVWebCacheResource,
                            placeholder: UIImage? = nil,
                            options: VVWebImageOptions = .none,
                            editor: VVWebImageEditor? = nil,
                            progress: VVImageDownloaderProgress? = nil,
                            completion: VVWebImageManagerCompletion? = nil)
    {
        let setImage: VVSetImage = { [weak self] image in
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
    
    /// 取消图片加载任务
    public func vv_cancelImageLoadTask() {
        vv_webCacheOperation.task(forKey: vv_imageLoadTaskKey)?.cancel()
    }
    
    public var vv_imageLoadTaskKey: String { return classForCoder.description() }
    
    /// 设置高亮图片，使用资源、占位符、自定义选项
    ///
    /// - Parameters:
    ///   - resource: 指定如何下载和缓存图片的资源
    ///   - placeholder: 加载图片时显示的占位符图片
    ///   - options: 一些行为的选项
    ///   - editor: 指定如何在内存中编辑和缓存图片
    ///   - progress: 在图片下载过程中调用的闭包
    ///   - completion: 图片加载完成后调用的闭包
    public func vv_setHighlightedImage(with resource: VVWebCacheResource,
                                       placeholder: UIImage? = nil,
                                       options: VVWebImageOptions = .none,
                                       editor: VVWebImageEditor? = nil,
                                       progress: VVImageDownloaderProgress? = nil,
                                       completion: VVWebImageManagerCompletion? = nil)
    {
        let setImage: VVSetImage = { [weak self] image in
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
    
    /// 取消高亮图片加载任务
    public func vv_cancelHighlightedImageLoadTask() {
        vv_webCacheOperation.task(forKey: vv_highlightedImageLoadTaskKey)?.cancel()
    }
    
    public var vv_highlightedImageLoadTaskKey: String { return classForCoder.description() + "Highlighted" }
}