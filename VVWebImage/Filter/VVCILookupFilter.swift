//
//  VVCILookupFilter.swift
//  VVWebImage
//

import UIKit

open class VVCILookupFilter: CIFilter {
    private static var _kernel: CIKernel?
    
    private static var kernel: CIKernel? {
        var localKernel = _kernel // Use local var to prevent multithreading problem
        if localKernel == nil {
            localKernel = CIKernel(source: kernelString)
            _kernel = localKernel
        }
        return localKernel
    }
    
    private static var kernelString: String {
        let path = Bundle(for: self).path(forResource: "VVCILookup", ofType: "cikernel")!
        return try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
    }
    
    open class func clear() { _kernel = nil }
    
    public static func outputImage(withInputImage inputImage: CIImage, lookupTable: CIImage, intensity: CGFloat) -> CIImage? {
        return kernel?.apply(extent: inputImage.extent, roiCallback: { (index: Int32, destRect: CGRect) -> CGRect in
            if index == 0 { return destRect }
            return lookupTable.extent
        }, arguments: [inputImage, lookupTable, intensity])
    }
    
    @objc public var inputImage: CIImage? // Add `@objc` to make it key-value coding compliant. Or it will crash in iOS 8
    
    public var lookupTable: CIImage?
    
    private var _intensity: CGFloat
    public var intensity: CGFloat {
        get { return _intensity }
        set { _intensity = min(1, max(0, newValue)) }
    }
    
    open override var outputImage: CIImage? {
        if let inputImage = inputImage,
            let lookupTable = lookupTable {
            return VVCILookupFilter.outputImage(withInputImage: inputImage, lookupTable: lookupTable, intensity: _intensity)
        }
        return nil
    }
    
    public override init() {
        _intensity = 1
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
