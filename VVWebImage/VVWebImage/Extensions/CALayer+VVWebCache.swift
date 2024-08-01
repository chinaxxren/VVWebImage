//
//  CALayer+VVWebCache.swift
//  VVWebImage
//

import UIKit

extension CALayer: VVWebCache {
    /// 设置图像，使用资源、占位符、自定义选项
    ///
    /// - Parameters:
    ///   - resource: 图像资源，指定如何下载和缓存图像
    ///   - placeholder: 加载图像时显示的占位符图像
    ///   - options: 一些行为的选项
    ///   - editor: 编辑器，指定如何在内存中编辑和缓存图像
    ///   - progress: 在图像下载过程中调用的闭包
    ///   - completion: 图像加载完成后调用的闭包
    public func vv_setImage(with resource: VVWebCacheResource,
                            placeholder: UIImage? = nil,
                            options: VVWebImageOptions = .none,
                            editor: VVWebImageEditor? = nil,
                            progress: VVImageDownloaderProgress? = nil,
                            completion: VVWebImageManagerCompletion? = nil)
    {
        let setImage: VVSetImage = { [weak self] image in
            if let self = self { self.contents = image?.cgImage }
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

    /// 取消图像加载任务
    public func vv_cancelImageLoadTask() {
        vv_webCacheOperation.task(forKey: vv_imageLoadTaskKey)?.cancel()
    }

    public var vv_imageLoadTaskKey: String { return classForCoder.description() }
}