//
//  VVImageCoder.swift
//  VVWebImage
//

import UIKit

/// VVImageCoder defines image decoding and encoding behaviors
public protocol VVImageCoder: AnyObject {
    /// Image coder can decode data or not
    ///
    /// - Parameter data: data to decode
    /// - Returns: true if coder can decode data, or false if can not
    func canDecode(_ data: Data) -> Bool
    
    /// Decodes image with data
    ///
    /// - Parameter data: data to decode
    /// - Returns: decoded image, or nil if decoding fails
    func decodedImage(with data: Data) -> UIImage?
    
    /// Decompresses image with data
    ///
    /// - Parameters:
    ///   - image: image to decompress
    ///   - data: image data
    /// - Returns: decompressed image, or nil if decompressing fails
    func decompressedImage(with image: UIImage, data: Data) -> UIImage?
    
    /// Image coder can encode image format or not
    ///
    /// - Parameter format: image format to encode
    /// - Returns: true if coder can encode image format, or false if can not
    func canEncode(_ format: VVImageFormat) -> Bool
    
    /// Encodes image to specified format
    ///
    /// - Parameters:
    ///   - image: image to encode
    ///   - format: image format to encode
    /// - Returns: encoded data, or nil if encoding fails
    func encodedData(with image: UIImage, format: VVImageFormat) -> Data?
    
    /// Copies image coder
    ///
    /// - Returns: new image coder
    func copy() -> VVImageCoder
}

/// VVImageProgressiveCoder defines image incremental decoding behaviors
public protocol VVImageProgressiveCoder: VVImageCoder {
    /// Image coder can decode data incrementally or not
    ///
    /// - Parameter data: data to decode
    /// - Returns: true if image coder can decode data incrementally, or false if can not
    func canIncrementallyDecode(_ data: Data) -> Bool
    
    /// Decodes data incrementally
    ///
    /// - Parameters:
    ///   - data: data to decode
    ///   - finished: whether downloading is finished
    /// - Returns: decoded image, or nil if decoding fails
    func incrementallyDecodedImage(with data: Data, finished: Bool) -> UIImage?
}

/// VVAnimatedImageCoder defines animated image decoding behaviors
public protocol VVAnimatedImageCoder: VVImageCoder {
    /// Image data to decode
    var imageData: Data? { get set }
    
    /// Number of image frames, or nil if fail to get the value
    var frameCount: Int? { get }
    
    /// Number of times to repeat the animation.
    /// Value 0 specifies to repeat the animation indefinitely.
    /// Value nil means failing to get the value.
    var loopCount: Int? { get }
    
    /// Gets image frame at specified index
    ///
    /// - Parameters:
    ///   - index: frame index
    ///   - decompress: whether to decompress image or not
    /// - Returns: image frame, or nil if fail
    func imageFrame(at index: Int, decompress: Bool) -> UIImage?
    
    /// Gets image frame size at specified index
    ///
    /// - Parameter index: frame index
    /// - Returns: image frame size, or nil if fail
    func imageFrameSize(at index: Int) -> CGSize?
    
    /// Gets image frame duration at specified index
    ///
    /// - Parameter index: frame index
    /// - Returns: image frame duration, or nil if fail
    func duration(at index: Int) -> TimeInterval?
}

/// VVImageCoderManager manages image coders for diffent image formats
public class VVImageCoderManager {
    /// Image coders.
    /// Getting and setting are thread safe.
    /// Set this property with custom image coders to custom image encoding and decoding.
    public var coders: [VVImageCoder] {
        get {
            pthread_mutex_lock(&coderLock)
            let currentCoders = _coders
            pthread_mutex_unlock(&coderLock)
            return currentCoders
        }
        set {
            pthread_mutex_lock(&coderLock)
            _coders = newValue
            pthread_mutex_unlock(&coderLock)
        }
    }
    private var _coders: [VVImageCoder]
    private var coderLock: pthread_mutex_t
    
    init() {
        _coders = [VVWebImageImageIOCoder(), VVWebImageGIFCoder()]
        coderLock = pthread_mutex_t()
        pthread_mutex_init(&coderLock, nil)
    }
}

extension VVImageCoderManager: VVImageCoder {
    /// Checks if the image coder can decode the given data
    public func canDecode(_ data: Data) -> Bool {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(data) {
            return true
        }
        return false
    }
    
    /// Decodes the given data into an image
    public func decodedImage(with data: Data) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(data) {
            return coder.decodedImage(with: data)
        }
        return nil
    }
    
    /// Decompresses the given image with the given data
    public func decompressedImage(with image: UIImage, data: Data) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(data) {
            return coder.decompressedImage(with: image, data: data)
        }
        return nil
    }
    
    /// Checks if the image coder can encode the given image format
    public func canEncode(_ format: VVImageFormat) -> Bool {
        let currentCoders = coders
        for coder in currentCoders where coder.canEncode(format) {
            return true
        }
        return false
    }
    
    /// Encodes the given image to the specified format
    public func encodedData(with image: UIImage, format: VVImageFormat) -> Data? {
        let currentCoders = coders
        for coder in currentCoders where coder.canEncode(format) {
            return coder.encodedData(with: image, format: format)
        }
        return nil
    }
    
    /// Copies the image coder
    public func copy() -> VVImageCoder {
        let newObj = VVImageCoderManager()
        var newCoders: [VVImageCoder] = []
        let currentCoders = coders
        for coder in currentCoders {
            newCoders.append(coder.copy())
        }
        newObj.coders = newCoders
        return newObj
    }
}

extension VVImageCoderManager: VVImageProgressiveCoder {
    /// Checks if the image coder can decode the given data incrementally
    public func canIncrementallyDecode(_ data: Data) -> Bool {
        let currentCoders = coders
        for coder in currentCoders {
            if let progressiveCoder = coder as? VVImageProgressiveCoder,
                progressiveCoder.canIncrementallyDecode(data) {
                return true
            }
        }
        return false
    }
    
    /// Decodes the given data incrementally
    public func incrementallyDecodedImage(with data: Data, finished: Bool) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders {
            if let progressiveCoder = coder as? VVImageProgressiveCoder,
                progressiveCoder.canIncrementallyDecode(data) {
                return progressiveCoder.incrementallyDecodedImage(with: data, finished: finished)
            }
        }
        return nil
    }
}