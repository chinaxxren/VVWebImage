//
//  Data+ImageFormat.swift
//  VVWebImage
//

import MobileCoreServices
import UIKit

public enum VVImageFormat {
    case unknown
    case JPEG
    case PNG
    case GIF

    var UTType: CFString {
        switch self {
        case .JPEG:
            return kUTTypeJPEG
        case .PNG:
            return kUTTypePNG
        case .GIF:
            return kUTTypeGIF
        default:
            return kUTTypeImage
        }
    }
}

public extension Data {
    var vv_imageFormat: VVImageFormat {
        if let firstByte = first {
            switch firstByte {
            case 0xff: return .JPEG // https://en.wikipedia.org/wiki/JPEG
            case 0x89: return .PNG // https://en.wikipedia.org/wiki/Portable_Network_Graphics
            case 0x47: return .GIF // https://en.wikipedia.org/wiki/GIF
            default: return .unknown
            }
        }
        return .unknown
    }
}
