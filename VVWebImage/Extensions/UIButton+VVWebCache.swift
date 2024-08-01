//
//  UIButton+VVWebCache.swift
//  VVWebImage
//

import UIKit

extension UIButton: VVWebCache {
    /// 设置图片，带资源、占位符、自定义选项
    ///
    /// - Parameters:
    ///   - resource: 图片资源，指定如何下载和缓存图片
    ///   - state: 设置图片的按钮状态
    ///   - placeholder: 加载图片时显示的占位符图片
    ///   - options: 一些行为的选项
    ///   - editor: 编辑器，指定如何在内存中编辑和缓存图片
    ///   - progress: 在图片下载过程中调用的闭包
    ///   - completion: 图片加载完成后调用的闭包
    public func vv_setImage(with resource: VVWebCacheResource,
                            forState state: UIControl.State,
                            placeholder: UIImage? = nil,
                            options: VVWebImageOptions = .none,
                            editor: VVWebImageEditor? = nil,
                            progress: VVImageDownloaderProgress? = nil,
                            completion: VVWebImageManagerCompletion? = nil)
    {
        let setImage: VVSetImage = { [weak self] image in
            if let self = self { self.setImage(image, for: state) }
        }
        vv_setImage(with: resource,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: vv_imageLoadTaskKey(forState: state),
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    /// 取消图片加载任务
    ///
    /// - Parameter state: 设置图片的按钮状态
    public func vv_cancelImageLoadTask(forState state: UIControl.State) {
        let key = vv_imageLoadTaskKey(forState: state)
        vv_webCacheOperation.task(forKey: key)?.cancel()
    }
    
    public func vv_imageLoadTaskKey(forState state: UIControl.State) -> String {
        return classForCoder.description() + "Image\(state.rawValue)"
    }
    
    /// 设置背景图片，带资源、占位符、自定义选项
    ///
    /// - Parameters:
    ///   - resource: 图片资源，指定如何下载和缓存图片
    ///   - state: 设置背景图片的按钮状态
    ///   - placeholder: 加载图片时显示的占位符图片
    ///   - options: 一些行为的选项
    ///   - editor: 编辑器，指定如何在内存中编辑和缓存图片
    ///   - progress: 在图片下载过程中调用的闭包
    ///   - completion: 图片加载完成后调用的闭包
    public func vv_setBackgroundImage(with resource: VVWebCacheResource,
                                      forState state: UIControl.State,
                                      placeholder: UIImage? = nil,
                                      options: VVWebImageOptions = .none,
                                      editor: VVWebImageEditor? = nil,
                                      progress: VVImageDownloaderProgress? = nil,
                                      completion: VVWebImageManagerCompletion? = nil)
    {
        let setImage: VVSetImage = { [weak self] image in
            if let self = self { self.setBackgroundImage(image, for: state) }
        }
        vv_setImage(with: resource,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: vv_backgroundImageLoadTaskKey(forState: state),
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    /// 取消背景图片加载任务
    ///
    /// - Parameter state: 设置背景图片的按钮状态
    public func vv_cancelBackgroundImageLoadTask(forState state: UIControl.State) {
        let key = vv_backgroundImageLoadTaskKey(forState: state)
        vv_webCacheOperation.task(forKey: key)?.cancel()
    }
    
    public func vv_backgroundImageLoadTaskKey(forState state: UIControl.State) -> String {
        return classForCoder.description() + "BackgroundImage\(state.rawValue)"
    }
}