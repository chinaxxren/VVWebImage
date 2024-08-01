//
//  VVWebImageImageIOCoder.swift
//  VVWebImage
//

import UIKit

public class VVWebImageImageIOCoder: VVImageCoder {
    // CGImageSource对象
    private var imageSource: CGImageSource?
    // 图片宽度
    private var imageWidth: Int
    // 图片高度
    private var imageHeight: Int
    // 图片方向
    private var imageOrientation: UIImage.Orientation
    
    public init() {
        imageWidth = 0
        imageHeight = 0
        imageOrientation = .up
    }
    
    // 判断是否可以解码
    public func canDecode(_ data: Data) -> Bool {
        switch data.vv_imageFormat {
        case .JPEG, .PNG:
            return true
        default:
            return false
        }
    }
    
    // 解码图片
    public func decodedImage(with data: Data) -> UIImage? {
        let image = UIImage(data: data)
        image?.vv_imageFormat = data.vv_imageFormat
        return image
    }
    
    // 解压缩图片
    public func decompressedImage(with image: UIImage, data: Data) -> UIImage? {
        guard let sourceImage = image.cgImage,
            let cgimage = VVWebImageImageIOCoder.decompressedImage(sourceImage) else { return image }
        let finalImage = UIImage(cgImage: cgimage, scale: image.scale, orientation: image.imageOrientation)
        finalImage.vv_imageFormat = image.vv_imageFormat
        return finalImage
    }
    
    // 解压缩CGImage
    public static func decompressedImage(_ sourceImage: CGImage) -> CGImage? {
        // 在自动释放池中执行
        return autoreleasepool { () -> CGImage? in
            // 获取源图像的宽度和高度
            let width = sourceImage.width
            let height = sourceImage.height
            // 获取源图像的位图信息
            var bitmapInfo = sourceImage.bitmapInfo
            // 移除位图信息中的alpha信息
            bitmapInfo.remove(.alphaInfoMask)
            // 如果源图像包含alpha信息
            if sourceImage.vv_containsAlpha {
                // 将位图信息设置为预乘的alpha信息
                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            } else {
                // 否则，将位图信息设置为无alpha信息
                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            }
            // 创建一个位图上下文
            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: sourceImage.bitsPerComponent,
                                          bytesPerRow: 0,
                                          space: vv_shareColorSpace,
                                          bitmapInfo: bitmapInfo.rawValue) else { return nil }
            // 在位图上下文中绘制源图像
            context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            // 返回位图上下文中的图像
            return context.makeImage()
        }
    }
    
    // 判断是否可以编码
    public func canEncode(_ format: VVImageFormat) -> Bool {
        return true
    }
    
    // 编码图片
    public func encodedData(with image: UIImage, format: VVImageFormat) -> Data? {
        // 将UIImage转换为CGImage
        guard let sourceImage = image.cgImage,
            // 创建可变数据
            let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        // 将传入的格式赋值给imageFormat
        var imageFormat = format
        // 如果传入的格式为unknown，则根据源图像是否包含alpha通道来确定格式
        if format == .unknown { imageFormat = sourceImage.vv_containsAlpha ? .PNG : .JPEG }
        // 创建CGImageDestination
        if let destination = CGImageDestinationCreateWithData(data, imageFormat.UTType, 1, nil) {
            // 设置图像属性
            let properties = [kCGImagePropertyOrientation : image.imageOrientation.vv_CGImageOrientation.rawValue]
            // 将源图像添加到CGImageDestination
            CGImageDestinationAddImage(destination, sourceImage, properties as CFDictionary)
            // 完成CGImageDestination
            if CGImageDestinationFinalize(destination) { return data as Data }
        }
        // 如果CGImageDestination创建失败，则返回nil
        return nil
    }
    
    // 复制对象
    public func copy() -> VVImageCoder { return VVWebImageImageIOCoder() }
}

extension VVWebImageImageIOCoder: VVImageProgressiveCoder {
    // 判断是否可以增量解码
    public func canIncrementallyDecode(_ data: Data) -> Bool {
        switch data.vv_imageFormat {
        case .JPEG, .PNG:
            return true
        default:
            return false
        }
    }
    
    // 增量解码图片
    public func incrementallyDecodedImage(with data: Data, finished: Bool) -> UIImage? {
        // 如果imageSource为空，则创建一个新的CGImageSource
        if imageSource == nil {
            imageSource = CGImageSourceCreateIncremental(nil)
        }
        // 获取imageSource
        guard let source = imageSource else { return nil }
        // 更新imageSource的数据
        CGImageSourceUpdateData(source, data as CFData, finished)
        var image: UIImage?
        // 如果imageWidth和imageHeight都小于等于0，则获取图片的属性
        if imageWidth <= 0 || imageHeight <= 0,
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString : AnyObject] {
            // 获取图片的宽度
            if let width = properties[kCGImagePropertyPixelWidth] as? Int {
                imageWidth = width
            }
            // 获取图片的高度
            if let height = properties[kCGImagePropertyPixelHeight] as? Int {
                imageHeight = height
            }
            // 获取图片的方向
            if let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
                let orientation = CGImagePropertyOrientation(rawValue: rawValue) {
                imageOrientation = orientation.vv_UIImageOrientation
            }
        }
        // 如果imageWidth和imageHeight都大于0，则创建图片
        if imageWidth > 0 && imageHeight > 0,
            let cgimage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            image = UIImage(cgImage: cgimage, scale: 1, orientation: imageOrientation)
            image?.vv_imageFormat = data.vv_imageFormat
        }
        // 如果finished为true，则重置imageSource、imageWidth、imageHeight和imageOrientation
        if finished {
            imageSource = nil
            imageWidth = 0
            imageHeight = 0
            imageOrientation = .up
        }
        return image
    }
}