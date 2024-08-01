//
//  UIImage+ImageFormat.swift
//  VVWebImage
//

import UIKit

private var imageFormatKey: Void?
private var imageDataKey: Void?
private var imageEditKey: Void?

public extension UIImage {
    var vv_imageFormat: VVImageFormat? {
        get { return objc_getAssociatedObject(self, &imageFormatKey) as? VVImageFormat }
        set { objc_setAssociatedObject(self, &imageFormatKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var vv_imageEditKey: String? {
        get { return objc_getAssociatedObject(self, &imageEditKey) as? String }
        set { objc_setAssociatedObject(self, &imageEditKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var vv_bytes: Int64 { return Int64(size.width * size.height * scale) }
}

public extension CGImage {
    var vv_containsAlpha: Bool { return !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast) }
    var vv_bytes: Int { return max(1, height * bytesPerRow) }
}

extension CGImagePropertyOrientation {
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

extension UIImage.Orientation {
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
