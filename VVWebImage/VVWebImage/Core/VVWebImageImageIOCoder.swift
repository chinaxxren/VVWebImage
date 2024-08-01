//
//  VVWebImageImageIOCoder.swift
//  VVWebImage
//

import UIKit

public class VVWebImageImageIOCoder: VVImageCoder {
    private var imageSource: CGImageSource?
    private var imageWidth: Int
    private var imageHeight: Int
    private var imageOrientation: UIImage.Orientation
    
    public init() {
        imageWidth = 0
        imageHeight = 0
        imageOrientation = .up
    }
    
    public func canDecode(_ data: Data) -> Bool {
        switch data.vv_imageFormat {
        case .JPEG, .PNG:
            return true
        default:
            return false
        }
    }
    
    public func decodedImage(with data: Data) -> UIImage? {
        let image = UIImage(data: data)
        image?.vv_imageFormat = data.vv_imageFormat
        return image
    }
    
    public func decompressedImage(with image: UIImage, data: Data) -> UIImage? {
        guard let sourceImage = image.cgImage,
            let cgimage = VVWebImageImageIOCoder.decompressedImage(sourceImage) else { return image }
        let finalImage = UIImage(cgImage: cgimage, scale: image.scale, orientation: image.imageOrientation)
        finalImage.vv_imageFormat = image.vv_imageFormat
        return finalImage
    }
    
    public static func decompressedImage(_ sourceImage: CGImage) -> CGImage? {
        return autoreleasepool { () -> CGImage? in
            let width = sourceImage.width
            let height = sourceImage.height
            var bitmapInfo = sourceImage.bitmapInfo
            bitmapInfo.remove(.alphaInfoMask)
            if sourceImage.vv_containsAlpha {
                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            } else {
                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            }
            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: sourceImage.bitsPerComponent,
                                          bytesPerRow: 0,
                                          space: vv_shareColorSpace,
                                          bitmapInfo: bitmapInfo.rawValue) else { return nil }
            context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage()
        }
    }
    
    public func canEncode(_ format: VVImageFormat) -> Bool {
        return true
    }
    
    public func encodedData(with image: UIImage, format: VVImageFormat) -> Data? {
        guard let sourceImage = image.cgImage,
            let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        var imageFormat = format
        if format == .unknown { imageFormat = sourceImage.vv_containsAlpha ? .PNG : .JPEG }
        if let destination = CGImageDestinationCreateWithData(data, imageFormat.UTType, 1, nil) {
            let properties = [kCGImagePropertyOrientation : image.imageOrientation.vv_CGImageOrientation.rawValue]
            CGImageDestinationAddImage(destination, sourceImage, properties as CFDictionary)
            if CGImageDestinationFinalize(destination) { return data as Data }
        }
        return nil
    }
    
    public func copy() -> VVImageCoder { return VVWebImageImageIOCoder() }
}

extension VVWebImageImageIOCoder: VVImageProgressiveCoder {
    public func canIncrementallyDecode(_ data: Data) -> Bool {
        switch data.vv_imageFormat {
        case .JPEG, .PNG:
            return true
        default:
            return false
        }
    }
    
    public func incrementallyDecodedImage(with data: Data, finished: Bool) -> UIImage? {
        if imageSource == nil {
            imageSource = CGImageSourceCreateIncremental(nil)
        }
        guard let source = imageSource else { return nil }
        CGImageSourceUpdateData(source, data as CFData, finished)
        var image: UIImage?
        if imageWidth <= 0 || imageHeight <= 0,
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString : AnyObject] {
            if let width = properties[kCGImagePropertyPixelWidth] as? Int {
                imageWidth = width
            }
            if let height = properties[kCGImagePropertyPixelHeight] as? Int {
                imageHeight = height
            }
            if let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
                let orientation = CGImagePropertyOrientation(rawValue: rawValue) {
                imageOrientation = orientation.vv_UIImageOrientation
            }
        }
        if imageWidth > 0 && imageHeight > 0,
            let cgimage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            image = UIImage(cgImage: cgimage, scale: 1, orientation: imageOrientation)
            image?.vv_imageFormat = data.vv_imageFormat
        }
        if finished {
            imageSource = nil
            imageWidth = 0
            imageHeight = 0
            imageOrientation = .up
        }
        return image
    }
}
