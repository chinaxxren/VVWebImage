//
//  UIImage+ImageFormat.swift
//  VVWebImage
//

import UIKit

// 定义三个私有变量，用于存储图像格式、图像数据和图像编辑信息
private var imageFormatKey: Void?
private var imageDataKey: Void?
private var imageEditKey: Void?

// 扩展UIImage类，添加VVImageFormat属性
public extension UIImage {
    // 获取图像格式
    var vv_imageFormat: VVImageFormat? {
        get { return objc_getAssociatedObject(self, &imageFormatKey) as? VVImageFormat }
        // 设置图像格式
        set { objc_setAssociatedObject(self, &imageFormatKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // 获取图像编辑信息
    var vv_imageEditKey: String? {
        get { return objc_getAssociatedObject(self, &imageEditKey) as? String }
        // 设置图像编辑信息
        set { objc_setAssociatedObject(self, &imageEditKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // 获取图像的字节数
    var vv_bytes: Int64 { return Int64(size.width * size.height * scale) }
}

// 扩展CGImage类，添加VVImageFormat属性
public extension CGImage {
    // 判断图像是否包含透明度
    var vv_containsAlpha: Bool { return !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast) }
    // 获取图像的字节数
    var vv_bytes: Int { return max(1, height * bytesPerRow) }
}

// 扩展CGImagePropertyOrientation枚举，添加VVImageFormat属性
extension CGImagePropertyOrientation {
    // 获取UIImageOrientation枚举值
    var vv_UIImageOrientation: UIImage.Orientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .downMirrored
        default: return .up
        }
    }
}

// 扩展UIImage.Orientation枚举，添加VVImageFormat属性
extension UIImage.Orientation {
    // 获取CGImagePropertyOrientation枚举值
    var vv_CGImageOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        default: return .up
        }
    }
}