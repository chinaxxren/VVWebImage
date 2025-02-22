//
//  VVAnimatedImageView.swift
//  VVWebImage
//

import UIKit

enum VVAnimatedImageViewType {
    case none
    case image
    case hilightedImage
    case animationImages
    case hilightedAnimationImages
}

/// VVAnimatedImageView displays VVAnimatedImage
public class VVAnimatedImageView: UIImageView {
    /// If true (default value), animation will be started/stopped automatically when the view becomes visible/invisible
    public var vv_autoStartAnimation: Bool = true
    
    /// A scale value that will be multiplied by duration. The default value is 1.
    /// Change this property to change animation speed. Only positive value is valid.
    public var vv_animationDurationScale: Double {
        get { return animationDurationScale }
        set { if newValue > 0 { animationDurationScale = newValue } }
    }
    
    /// The image animation is played with CADisplayLink. This property is the run loop mode associated with the CADisplayLink.
    /// The default value is common run loop mode.
    public var vv_runLoopMode: RunLoop.Mode {
        get { return runLoopMode }
        set {
            if runLoopMode == newValue { return }
            if let oldLink = displayLink {
                // If remove old run loop mode and add new run loop mode, the animation will pause a while in iOS 8.
                // So create a new display link here.
                let isPaused = oldLink.isPaused
                oldLink.invalidate()
                let link = CADisplayLink(target: VVWeakProxy(target: self), selector: #selector(displayLinkRefreshed(_:)))
                link.isPaused = isPaused
                link.add(to: .main, forMode: newValue)
                displayLink = link
            }
            runLoopMode = newValue
        }
    }
    
    /// Index of current image frame
    public private(set) var vv_currentFrameIndex: Int = 0
    
    /// Set a VVAnimatedImage object to play animation
    public override var image: UIImage? {
        get { return super.image }
        set {
            if super.image == newValue { return }
            setImage(newValue, withType: .image)
        }
    }
    
    /// Set a VVAnimatedImage object to play animation
    public override var highlightedImage: UIImage? {
        get { return super.highlightedImage }
        set {
            if super.highlightedImage == newValue { return }
            setImage(newValue, withType: .hilightedImage)
        }
    }
    
    public override var animationImages: [UIImage]? {
        get { return super.animationImages }
        set {
            if super.animationImages == newValue { return }
            setImage(newValue, withType: .animationImages)
        }
    }
    
    public override var highlightedAnimationImages: [UIImage]? {
        get { return super.highlightedAnimationImages }
        set {
            if super.highlightedAnimationImages == newValue { return }
            setImage(newValue, withType: .hilightedAnimationImages)
        }
    }
    
    public override var isAnimating: Bool {
        switch currentType {
        case .none: return false
        case .image, .hilightedImage:
            if let link = displayLink { return !link.isPaused }
            return false
        default: return super.isAnimating
        }
    }
    
    private var currentType: VVAnimatedImageViewType {
        var type: VVAnimatedImageViewType = .none
        if isHighlighted {
            if let count = highlightedAnimationImages?.count, count > 0 { type = .hilightedAnimationImages }
            else if highlightedImage != nil { type = .hilightedImage }
        }
        if type == .none {
            if let count = animationImages?.count, count > 0 { type = .animationImages }
            else if image != nil { type = .image }
        }
        return type
    }
    
    private var imageForCurrentType: Any? { return image(forType: currentType) }
    
    private var displayLink: CADisplayLink?
    private var animationDurationScale: Double = 1
    private var runLoopMode: RunLoop.Mode = .common
    private var shouldUpdateLayer: Bool = true
    private var loopCount: Int = 0
    private var accumulatedTime: TimeInterval = 0
    private var currentLayerContent: CGImage?
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setImage(_ image: Any?, withType type: VVAnimatedImageViewType) {
        stopAnimating()
        if displayLink != nil { resetAnimation() }
        let animatedImage = image as? VVAnimatedImage
        switch type {
        case .none: break
        case .image:
            let old = super.image as? VVAnimatedImage
            super.image = image as? UIImage
            old?.vv_didRemoveFromView(self)
        case .hilightedImage:
            let old = super.highlightedImage as? VVAnimatedImage
            super.highlightedImage = image as? UIImage
            old?.vv_didRemoveFromView(self)
        case .animationImages: super.animationImages = image as? [UIImage]
        case .hilightedAnimationImages: super.highlightedAnimationImages = image as? [UIImage]
        }
        animatedImage?.vv_didAddToView(self)
        animatedImage?.vv_updateCacheSizeIfNeeded()
        didMove()
    }
    
    private func resetAnimation() {
        loopCount = 0
        vv_currentFrameIndex = 0
        accumulatedTime = 0
        currentLayerContent = nil
        shouldUpdateLayer = true
    }
    
    @objc private func displayLinkRefreshed(_ link: CADisplayLink) {
        guard let currentImage = imageForCurrentType as? VVAnimatedImage else { return }
        if shouldUpdateLayer,
            let cgimage = currentImage.vv_imageFrame(at: vv_currentFrameIndex, decodeIfNeeded: (vv_currentFrameIndex == 0))?.cgImage {
            currentLayerContent = cgimage
            layer.setNeedsDisplay()
            shouldUpdateLayer = false
        }
        let nextIndex = (vv_currentFrameIndex + 1) % currentImage.vv_frameCount
        currentImage.vv_preloadImageFrame(fromIndex: nextIndex)
        accumulatedTime += link.duration // multiply frameInterval if frameInterval is not 1
        if var duration = currentImage.vv_duration(at: vv_currentFrameIndex) {
            duration *= animationDurationScale
            if accumulatedTime >= duration {
                vv_currentFrameIndex = nextIndex
                accumulatedTime -= duration
                shouldUpdateLayer = true
                if (animationRepeatCount > 0 || currentImage.vv_loopCount > 0) && vv_currentFrameIndex == 0 {
                    loopCount += 1
                    if (animationRepeatCount > 0 && loopCount >= animationRepeatCount) ||
                        (currentImage.vv_loopCount > 0 && loopCount >= currentImage.vv_loopCount) {
                        stopAnimating()
                        resetAnimation()
                    }
                }
            }
        }
    }
    
    private func image(forType type: VVAnimatedImageViewType) -> Any? {
        switch type {
        case .none: return nil
        case .image: return image
        case .hilightedImage: return highlightedImage
        case .animationImages: return animationImages
        case .hilightedAnimationImages: return highlightedAnimationImages
        }
    }
    
    /// Sets the current animated image frame index
    ///
    /// - Parameters:
    ///   - index: frame index
    ///   - decodeIfNeeded: whether to decode or edit image synchronously if no cached image found
    /// - Returns: true if succeed, or false if fail
    @discardableResult
    public func vv_setCurrentFrameIndex(_ index: Int, decodeIfNeeded: Bool) -> Bool {
        guard let currentImage = imageForCurrentType as? VVAnimatedImage,
         let cgimage = currentImage.vv_imageFrame(at: index, decodeIfNeeded: decodeIfNeeded)?.cgImage else { return false }
        currentLayerContent = cgimage
        layer.setNeedsDisplay()
        vv_currentFrameIndex = index
        accumulatedTime = 0
        shouldUpdateLayer = false
        if let link = displayLink, !link.isPaused {
            let nextIndex = (vv_currentFrameIndex + 1) % currentImage.vv_frameCount
            currentImage.vv_preloadImageFrame(fromIndex: nextIndex)
        }
        return true
    }
    
    public override func startAnimating() {
        switch currentType {
        case .image, .hilightedImage:
            if let link = displayLink {
                if link.isPaused { link.isPaused = false }
            } else {
                let link = CADisplayLink(target: VVWeakProxy(target: self), selector: #selector(displayLinkRefreshed(_:)))
                link.add(to: .main, forMode: runLoopMode)
                displayLink = link
            }
        default:
            super.startAnimating()
        }
    }
    
    public override func stopAnimating() {
        super.stopAnimating()
        displayLink?.isPaused = true
    }
    
    public override func didMoveToSuperview() {
        didMove()
    }
    
    public override func didMoveToWindow() {
        didMove()
    }
    
    private func didMove() {
        if vv_autoStartAnimation {
            if superview != nil && window != nil {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    // MARK: - Layer delegate
    
    public override func display(_ layer: CALayer) {
        if let content = currentLayerContent { layer.contents = content }
    }
}
