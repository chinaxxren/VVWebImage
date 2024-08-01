//
//  VVAnimatedImageTests.swift
//  VVWebImageTests
//
//  Created by waqu Lu on 2/19/19.
//  Copyright © 2019 waqu Lu. All rights reserved.
//

import XCTest
import VVWebImage

class VVAnimatedImageTests: XCTestCase {
    var image: VVAnimatedImage!
    var imageData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        return try! Data(contentsOf: url)
    }
    
    override func setUp() {
        image = VVAnimatedImage(vv_data: imageData)
    }

    override func tearDown() {}

    func testFormat() {
        XCTAssertEqual(image.vv_imageFormat, .GIF)
    }
    
    func testFrameCount() {
        XCTAssertEqual(image.vv_frameCount, 44)
    }
    
    func testLoopCount() {
        XCTAssertEqual(image.vv_loopCount, 65535)
    }
    
    func testMaxCacheSize() {
        image.vv_maxCacheSize = 1024
        XCTAssertEqual(image.vv_maxCacheSize, 1024)
        
        image.vv_maxCacheSize = 0
        XCTAssertEqual(image.vv_maxCacheSize, 0)
        
        image.vv_maxCacheSize = -1
        XCTAssertGreaterThan(image.vv_maxCacheSize, 0)
    }
    
    func testCurrentCacheSize() {
        XCTAssertEqual(image.vv_currentCacheSize, image.vv_bytes)
    }
    
    func testOriginalImageData() {
        XCTAssertEqual(image.vv_originalImageData, imageData)
    }
    
    func testImageFrame() {
        for i in 0..<image.vv_frameCount {
            let cachedFrame = image.vv_imageFrame(at: i, decodeIfNeeded: false)
            if i == 0 {
                XCTAssertNotNil(cachedFrame)
            } else {
                XCTAssertNil(cachedFrame)
            }
            let decodedFrame = image.vv_imageFrame(at: i, decodeIfNeeded: true)
            XCTAssertNotNil(decodedFrame)
        }
    }
    
    func testDuration() {
        for i in 0..<image.vv_frameCount {
            let duration = image.vv_duration(at: i)
            XCTAssertEqual(duration, 0.09)
        }
    }
    
    func testPreloadImageFrame() {
        let expectation = self.expectation(description: "Wait for preloading images")
        image.vv_preloadImageFrame(fromIndex: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var count = self.image.vv_frameCount
            for i in 0..<self.image.vv_frameCount {
                let cachedFrame = self.image.vv_imageFrame(at: i, decodeIfNeeded: false)
                XCTAssertNotNil(cachedFrame)
                count -= 1
                if count == 0 { expectation.fulfill() }
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancelPreloadTask() {
        let expectation = self.expectation(description: "Wait for preloading images")
        image.vv_preloadImageFrame(fromIndex: 0)
        image.vv_cancelPreloadTask()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var count = self.image.vv_frameCount
            for i in 0..<self.image.vv_frameCount {
                let cachedFrame = self.image.vv_imageFrame(at: i, decodeIfNeeded: false)
                if i == 0 {
                    XCTAssertNotNil(cachedFrame)
                } else {
                    XCTAssertNil(cachedFrame)
                }
                count -= 1
                if count == 0 { expectation.fulfill() }
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testPreloadAllImageFrames() {
        image.vv_preloadAllImageFrames()
        for i in 0..<image.vv_frameCount {
            let cachedFrame = image.vv_imageFrame(at: i, decodeIfNeeded: false)
            XCTAssertNotNil(cachedFrame)
        }
    }
    
    func testClear() {
        image.vv_preloadAllImageFrames()
        image.vv_clear()
        for i in 0..<image.vv_frameCount {
            let cachedFrame = image.vv_imageFrame(at: i, decodeIfNeeded: false)
            XCTAssertNil(cachedFrame)
        }
    }
    
    func testClearAsynchronously() {
        let expectation = self.expectation(description: "Wait for preloading images")
        image.vv_preloadAllImageFrames()
        image.vv_clearAsynchronously {
            for i in 0..<self.image.vv_frameCount {
                let cachedFrame = self.image.vv_imageFrame(at: i, decodeIfNeeded: false)
                XCTAssertNil(cachedFrame)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testEditor() {
        for i in 0..<image.vv_frameCount {
            let frame = image.vv_imageFrame(at: i, decodeIfNeeded: true)
            let size = frame?.size
            XCTAssertEqual(size, CGSize(width: 400, height: 400))
        }
        image.vv_editor = vv_imageEditorResize(with: CGSize(width: 200, height: 200))
        for i in 0..<image.vv_frameCount {
            let frame = image.vv_imageFrame(at: i, decodeIfNeeded: false)
            XCTAssertNil(frame)
        }
        for i in 0..<image.vv_frameCount {
            let frame = image.vv_imageFrame(at: i, decodeIfNeeded: true)
            let size = frame?.size
            XCTAssertEqual(size, CGSize(width: 200, height: 200))
        }
    }
    
    func testSetCurrentFrameIndex() {
        let imageView = VVAnimatedImageView()
        imageView.vv_autoStartAnimation = false
        imageView.image = image
        XCTAssertEqual(imageView.vv_currentFrameIndex, 0)
        for i in 0..<image.vv_frameCount * 2 {
            let result = imageView.vv_setCurrentFrameIndex(i, decodeIfNeeded: false)
            if i == 0 {
                XCTAssertTrue(result)
            } else {
                XCTAssertFalse(result)
            }
            XCTAssertEqual(imageView.vv_currentFrameIndex, 0)
        }
        for i in 0..<image.vv_frameCount * 2 {
            let result = imageView.vv_setCurrentFrameIndex(i, decodeIfNeeded: true)
            if i < image.vv_frameCount {
                XCTAssertTrue(result)
                XCTAssertEqual(imageView.vv_currentFrameIndex, i)
            } else {
                XCTAssertFalse(result)
                XCTAssertEqual(imageView.vv_currentFrameIndex, image.vv_frameCount - 1)
            }
        }
    }
}
