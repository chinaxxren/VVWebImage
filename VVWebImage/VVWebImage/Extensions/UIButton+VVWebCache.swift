//
//  UIButton+VVWebCache.swift
//  VVWebImage
//

import UIKit

extension UIButton: VVWebCache {
    /// Sets image with resource, placeholder, custom opotions
    ///
    /// - Parameters:
    ///   - resource: image resource specifying how to download and cache image
    ///   - state: button state to set image
    ///   - placeholder: placeholder image displayed when loading image
    ///   - options: options for some behaviors
    ///   - editor: editor specifying how to edit and cache image in memory
    ///   - progress: a closure called while image is downloading
    ///   - completion: a closure called when image loading is finished
    public func vv_setImage(with resource: VVWebCacheResource,
                            forState state: UIControl.State,
                            placeholder: UIImage? = nil,
                            options: VVWebImageOptions = .none,
                            editor: VVWebImageEditor? = nil,
                            progress: VVImageDownloaderProgress? = nil,
                            completion: VVWebImageManagerCompletion? = nil) {
        let setImage: VVSetImage = { [weak self] (image) in
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
    
    /// Cancels image loading task
    ///
    /// - Parameter state: button state to set image
    public func vv_cancelImageLoadTask(forState state: UIControl.State) {
        let key = vv_imageLoadTaskKey(forState: state)
        vv_webCacheOperation.task(forKey: key)?.cancel()
    }
    
    public func vv_imageLoadTaskKey(forState state: UIControl.State) -> String {
        return classForCoder.description() + "Image\(state.rawValue)"
    }
    
    /// Sets background image with resource, placeholder, custom opotions
    ///
    /// - Parameters:
    ///   - resource: image resource specifying how to download and cache image
    ///   - state: button state to set background image
    ///   - placeholder: placeholder image displayed when loading image
    ///   - options: options for some behaviors
    ///   - editor: editor specifying how to edit and cache image in memory
    ///   - progress: a closure called while image is downloading
    ///   - completion: a closure called when image loading is finished
    public func vv_setBackgroundImage(with resource: VVWebCacheResource,
                                      forState state: UIControl.State,
                                      placeholder: UIImage? = nil,
                                      options: VVWebImageOptions = .none,
                                      editor: VVWebImageEditor? = nil,
                                      progress: VVImageDownloaderProgress? = nil,
                                      completion: VVWebImageManagerCompletion? = nil) {
        let setImage: VVSetImage = { [weak self] (image) in
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
    
    /// Cancels background image loading task
    ///
    /// - Parameter state: button state to set background image
    public func vv_cancelBackgroundImageLoadTask(forState state: UIControl.State) {
        let key = vv_backgroundImageLoadTaskKey(forState: state)
        vv_webCacheOperation.task(forKey: key)?.cancel()
    }
    
    public func vv_backgroundImageLoadTaskKey(forState state: UIControl.State) -> String {
        return classForCoder.description() + "BackgroundImage\(state.rawValue)"
    }
}
