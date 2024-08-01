//
//  VVCILookupTestFilter.swift
//  VVWebImageDemo
//

import UIKit
import VVWebImage

class VVCILookupTestFilter: VVCILookupFilter {
    private static var _sharedLookupTable: CIImage?
    private static var sharedLookupTable: CIImage? {
        var localLookupTable = _sharedLookupTable
        if localLookupTable == nil {
            let url = Bundle.main.url(forResource: "test_lookup", withExtension: "png")!
            localLookupTable = CIImage(contentsOf: url)
            _sharedLookupTable = localLookupTable
        }
        return localLookupTable
    }
    
    override static func clear() {
        _sharedLookupTable = nil
        super.clear()
    }
    
    override init() {
        super.init()
        lookupTable = VVCILookupTestFilter.sharedLookupTable
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// The higher maxTileSize, the less memory cost, the longer processing time
public func vv_imageEditorCILookupTestFilter(maxTileSize: Int = 0) -> VVWebImageEditor {
    let edit: VVWebImageEditMethod = { (image) in
        autoreleasepool { () -> UIImage? in
            var inputImage: CIImage?
            if let ciimage = image.ciImage {
                inputImage = ciimage
            } else if let cgimage = image.cgImage {
                inputImage = CIImage(cgImage: cgimage)
            } else {
                inputImage = CIImage(image: image)
            }
            guard let input = inputImage else { return image }
            let filter = VVCILookupTestFilter()
            if maxTileSize <= 0 {
                filter.inputImage = input
                if let output = filter.outputImage,
                    let sourceImage = vv_shareCIContext.createCGImage(output, from: output.extent),
                    let cgimage = VVWebImageImageIOCoder.decompressedImage(sourceImage) {
                    // It costs more memory without decompressing
                    return UIImage(cgImage: cgimage)
                }
                return image
            }
            // Split image into tiles, process tiles and combine
            let width = input.extent.width
            var height = max(1, floor(CGFloat(maxTileSize) / width))
            var y: CGFloat = 0
            var context: CGContext?
            while y < input.extent.height {
                if y + height > input.extent.height {
                    height = input.extent.height - y
                }
                let success = autoreleasepool { () -> Bool in
                    filter.inputImage = input.cropped(to: CGRect(x: 0, y: y, width: width, height: height))
                    guard let output = filter.outputImage,
                        let cgimage = vv_shareCIContext.createCGImage(output, from: output.extent) else { return false }
                    if context == nil {
                        var bitmapInfo = cgimage.bitmapInfo
                        bitmapInfo.remove(.alphaInfoMask)
                        if cgimage.vv_containsAlpha {
                            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
                        } else {
                            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
                        }
                        context = CGContext(data: nil,
                                            width: Int(width),
                                            height: Int(input.extent.height),
                                            bitsPerComponent: cgimage.bitsPerComponent,
                                            bytesPerRow: 0,
                                            space: vv_shareColorSpace,
                                            bitmapInfo: bitmapInfo.rawValue)
                        if (context == nil) { return false }
                    }
                    context?.draw(cgimage, in: CGRect(x: 0, y: y, width: width, height: height))
                    return true
                }
                if !success { return image }
                y += height
            }
            return context?.makeImage().flatMap { UIImage(cgImage: $0) } ?? image
        }
    }
    return VVWebImageEditor(key: VVCILookupTestFilter.description(), edit: edit)
}
