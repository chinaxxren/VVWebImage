//
//  VVImageCoderManagerTests.swift
//  VVWebImageTests
//
//  Created by waqu Lu on 2018/12/4.
//  Copyright © 2018年 waqu Lu. All rights reserved.
//

import XCTest
import VVWebImage

class VVImageCoderManagerTests: XCTestCase {
    var coder: VVImageCoderManager!
    
    var pngData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "png")!
        return try! Data(contentsOf: url)
    }
    
    var jpgData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "jpg")!
        return try! Data(contentsOf: url)
    }
    
    var gifData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        return try! Data(contentsOf: url)
    }
    
    override func setUp() {
        coder = VVImageCoderManager()
    }

    override func tearDown() {}

    func testCanDecode() {
        XCTAssertFalse(coder.canDecode(Data()))
        XCTAssertTrue(coder.canDecode(pngData))
        XCTAssertTrue(coder.canDecode(jpgData))
        XCTAssertTrue(coder.canDecode(gifData))
    }
    
    func testDecode() {
        XCTAssertNil(coder.decodedImage(with: Data()))
        
        let pngImage = coder.decodedImage(with: pngData)
        XCTAssertNotNil(pngImage)
        XCTAssertEqual(pngImage?.vv_imageFormat, .PNG)
        
        let jpgImage = coder.decodedImage(with: jpgData)
        XCTAssertNotNil(jpgImage)
        XCTAssertEqual(jpgImage?.vv_imageFormat, .JPEG)
        
        let gifImage = coder.decodedImage(with: gifData)
        XCTAssertNotNil(gifImage)
        XCTAssertEqual(gifImage?.vv_imageFormat, .GIF)
        XCTAssertTrue(gifImage is VVAnimatedImage)
    }
    
    func testDecompress() {
        let pngData = self.pngData
        let pngImage = coder.decodedImage(with: pngData)!
        let pngDecompressedImage = coder.decompressedImage(with: pngImage, data: pngData)
        XCTAssertNotNil(pngDecompressedImage)
        XCTAssertNotEqual(pngImage, pngDecompressedImage)
        XCTAssertEqual(pngDecompressedImage?.vv_imageFormat, .PNG)
        
        let jpgData = self.jpgData
        let jpgImage = coder.decodedImage(with: jpgData)!
        let jpgDecompressedImage = coder.decompressedImage(with: jpgImage, data: jpgData)
        XCTAssertNotNil(jpgDecompressedImage)
        XCTAssertNotEqual(jpgImage, jpgDecompressedImage)
        XCTAssertEqual(jpgDecompressedImage?.vv_imageFormat, .JPEG)
        
        let gifData = self.gifData
        let gifImage = coder.decodedImage(with: gifData)!
        let gifDecompressedImage = coder.decompressedImage(with: gifImage, data: gifData)
        XCTAssertNil(gifDecompressedImage)
    }
    
    func testCanEncode() {
        XCTAssertTrue(coder.canEncode(.unknown))
        XCTAssertTrue(coder.canEncode(.PNG))
        XCTAssertTrue(coder.canEncode(.JPEG))
        XCTAssertTrue(coder.canEncode(.GIF))
    }
    
    func testEncode() {
        let images: [UIImage] = [coder.decodedImage(with: pngData)!,
                                 coder.decodedImage(with: jpgData)!,
                                 coder.decodedImage(with: gifData)!]
        for image in images {
            XCTAssertNotNil(coder.encodedData(with: image, format: .PNG))
            XCTAssertNotNil(coder.encodedData(with: image, format: .JPEG))
            XCTAssertNotNil(coder.encodedData(with: image, format: .GIF))
            XCTAssertNotNil(coder.encodedData(with: image, format: .unknown))
        }
    }
    
    func testCopy() {
        XCTAssertFalse(coder === coder.copy())
    }
    
    func testCanIncrementallyDecode() {
        XCTAssertTrue(coder.canIncrementallyDecode(pngData))
        XCTAssertTrue(coder.canIncrementallyDecode(jpgData))
        XCTAssertFalse(coder.canIncrementallyDecode(gifData))
    }
    
    func testIncrementallyDecodedImage() {
        let test = { (data: Data, total: Int, canDecode: Bool) -> Void in
            for i in 1...total {
                let finished = (i == total)
                let end = Int((Double(i) / Double(total)) * Double(data.count))
                let subdata = data.subdata(in: 0..<end)
                if canDecode {
                    XCTAssertNotNil(self.coder.incrementallyDecodedImage(with: subdata, finished: finished))
                } else {
                    XCTAssertNil(self.coder.incrementallyDecodedImage(with: subdata, finished: finished))
                }
            }
        }
        test(pngData, 10, true)
        test(jpgData, 5, true) // Need enough data to decode
        test(gifData, 10, false)
    }
}
