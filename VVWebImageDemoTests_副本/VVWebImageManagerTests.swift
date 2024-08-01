//
//  VVWebImageManagerTests.swift
//  VVWebImageTests
//
//  Created by waqu Lu on 2018/12/10.
//  Copyright © 2018年 waqu Lu. All rights reserved.
//

import XCTest
import VVWebImage

class VVWebImageManagerTests: XCTestCase {
    var imageManager: VVWebImageManager!
    var urls: [URL]!
    
    override func setUp() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.waqu.VVWebImage.test"
        imageManager = VVWebImageManager(cachePath: path, sizeThreshold: 20 * 1024)
        urls = []
        for i in 1...10 {
            urls.append(ImageURLProvider.originURL(forIndex: i)!)
        }
    }

    override func tearDown() {
        let lock = DispatchSemaphore(value: 0)
        imageManager.imageCache.clear(.all) {
            lock.signal()
        }
        lock.wait()
    }

    func testShared() {
        XCTAssertTrue(VVWebImageManager.shared === VVWebImageManager.shared)
        XCTAssertTrue(VVWebImageManager.shared !== imageManager)
    }
    
    func testLoadImageFromNetwork() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        let lock = DispatchSemaphore(value: 1)
        var finish = false
        imageManager.loadImage(with: url, progress: { (data, expectedSize, image) in
            lock.wait()
            XCTAssertFalse(finish)
            lock.signal()
            if data == nil {
                XCTAssertTrue(expectedSize > 0)
            } else {
                XCTAssertTrue(data!.count <= expectedSize)
            }
            XCTAssertNil(image)
            XCTAssertFalse(Thread.isMainThread)
        }) { (image, data, error, cacheType) in
            lock.wait()
            finish = true
            lock.signal()
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                expectation.fulfill()
            }
        }
        lock.wait()
        XCTAssertFalse(finish)
        lock.signal()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImagesFromNetwork() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            let lock = DispatchSemaphore(value: 1)
            var finish = false
            imageManager.loadImage(with: url, progress: { (data, expectedSize, image) in
                lock.wait()
                XCTAssertFalse(finish)
                lock.signal()
                if data == nil {
                    XCTAssertTrue(expectedSize > 0)
                } else {
                    XCTAssertTrue(data!.count <= expectedSize)
                }
                XCTAssertNil(image)
                XCTAssertFalse(Thread.isMainThread)
            }) { (image, data, error, cacheType) in
                lock.wait()
                finish = true
                lock.signal()
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    expectation.fulfill()
                }
            }
            lock.wait()
            XCTAssertFalse(finish)
            lock.signal()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPreloadImagesFromNetwork() {
        var expectations: [XCTestExpectation] = []
        for _ in urls {
            expectations.append(expectation(description: "Wait for loading image"))
        }
        imageManager.preload(urls, progress: { (successCount, finishCount, total) in
            XCTAssertGreaterThan(successCount, 0)
            XCTAssertGreaterThan(finishCount, 0)
            XCTAssertEqual(total, self.urls.count)
        }) { (successCount, total) in
            XCTAssertEqual(successCount, total)
            XCTAssertEqual(total, self.urls.count)
            for i in 0..<self.urls.count {
                var sentinel = false
                self.imageManager.imageCache.image(forKey: self.urls[i].absoluteString, cacheType: .memory) { (result) in
                    switch result {
                    case .none:
                        sentinel = true
                    default:
                        XCTFail()
                    }
                }
                self.imageManager.imageCache.diskDataExists(forKey: self.urls[i].absoluteString) { (exists) in
                    XCTAssertTrue(sentinel)
                    XCTAssertTrue(exists)
                    expectations[i].fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPreloadImagesFromNetwork2() {
        var expectations: [XCTestExpectation] = []
        for _ in urls {
            expectations.append(expectation(description: "Wait for loading image"))
        }
        imageManager.preload(urls, progress: { (_, _, _) in
            XCTFail()
        }) { (_, _) in
            XCTFail()
        }
        imageManager.preload(urls, progress: { (successCount, finishCount, total) in
            XCTAssertGreaterThan(successCount, 0)
            XCTAssertGreaterThan(finishCount, 0)
            XCTAssertEqual(total, self.urls.count)
        }) { (successCount, total) in
            XCTAssertEqual(successCount, total)
            XCTAssertEqual(total, self.urls.count)
            for i in 0..<self.urls.count {
                var sentinel = false
                self.imageManager.imageCache.image(forKey: self.urls[i].absoluteString, cacheType: .memory) { (result) in
                    switch result {
                    case .none:
                        sentinel = true
                    default:
                        XCTFail()
                    }
                }
                self.imageManager.imageCache.diskDataExists(forKey: self.urls[i].absoluteString) { (exists) in
                    XCTAssertTrue(sentinel)
                    XCTAssertTrue(exists)
                    expectations[i].fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImageFromMemory() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            var sentinel = false
            self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .memory)
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
                sentinel = true
            }
            XCTAssertTrue(sentinel)
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImagesFromMemory() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                var sentinel = false
                self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .memory)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                    sentinel = true
                }
                XCTAssertTrue(sentinel)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPreloadImagesFromMemory() {
        var expectations: [XCTestExpectation] = []
        let group = DispatchGroup()
        for url in urls {
            expectations.append(expectation(description: "Wait for loading image"))
            group.enter()
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.imageManager.preload(self.urls, progress: { (successCount, finishCount, total) in
                XCTAssertGreaterThan(successCount, 0)
                XCTAssertGreaterThan(finishCount, 0)
                XCTAssertEqual(total, self.urls.count)
            }) { (successCount, total) in
                XCTAssertEqual(successCount, total)
                XCTAssertEqual(total, self.urls.count)
                for i in 0..<self.urls.count {
                    var sentinel = false
                    self.imageManager.imageCache.image(forKey: self.urls[i].absoluteString, cacheType: .memory) { (result) in
                        switch result {
                        case .memory(image: _):
                            sentinel = true
                        default:
                            XCTFail()
                        }
                    }
                    self.imageManager.imageCache.diskDataExists(forKey: self.urls[i].absoluteString) { (exists) in
                        XCTAssertTrue(sentinel)
                        XCTAssertTrue(exists)
                        expectations[i].fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImageFromDisk() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            self.imageManager.imageCache.clear(.memory) {
                var sentinel = false
                self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .disk)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                    sentinel = true
                }
                XCTAssertFalse(sentinel)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImagesFromDisk() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                self.imageManager.imageCache.clear(.memory, completion: nil)
                var sentinel = false
                self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .disk)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                    sentinel = true
                }
                XCTAssertFalse(sentinel)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPreloadImagesFromDisk() {
        var expectations: [XCTestExpectation] = []
        let group = DispatchGroup()
        for url in urls {
            expectations.append(expectation(description: "Wait for loading image"))
            group.enter()
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.imageManager.imageCache.clear(.memory, completion: nil)
            self.imageManager.preload(self.urls, progress: { (successCount, finishCount, total) in
                XCTAssertGreaterThan(successCount, 0)
                XCTAssertGreaterThan(finishCount, 0)
                XCTAssertEqual(total, self.urls.count)
            }) { (successCount, total) in
                XCTAssertEqual(successCount, total)
                XCTAssertEqual(total, self.urls.count)
                for i in 0..<self.urls.count {
                    var sentinel = false
                    self.imageManager.imageCache.image(forKey: self.urls[i].absoluteString, cacheType: .memory) { (result) in
                        switch result {
                        case .none:
                            sentinel = true
                        default:
                            XCTFail()
                        }
                    }
                    self.imageManager.imageCache.diskDataExists(forKey: self.urls[i].absoluteString) { (exists) in
                        XCTAssertTrue(sentinel)
                        XCTAssertTrue(exists)
                        expectations[i].fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTask() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        let task = imageManager.loadImage(with: url) { (_, _, _, _) in
            XCTFail()
        }
        XCTAssertEqual(imageManager.currentTaskCount, 1)
        task.cancel()
        XCTAssertEqual(imageManager.currentTaskCount, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTaskAndLoad() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        let task = imageManager.loadImage(with: url) { (_, _, _, _) in
            XCTFail()
        }
        task.cancel()
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTaskAndLoadRepeatedly() {
        let url = urls.first!
        for _ in 0..<10 {
            let task = imageManager.loadImage(with: url) { (_, _, _, _) in
                XCTFail()
            }
            task.cancel()
        }
        let expectation = self.expectation(description: "Wait for loading image")
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTaskAndLoadRepeatedly2() {
        let url = urls.first!
        for _ in 0..<10 {
            let expectation = self.expectation(description: "Wait for loading image")
            let task = imageManager.loadImage(with: url) { (_, _, _, _) in
                XCTFail()
            }
            task.cancel()
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadDiskImageTask() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        let localUrl = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "png")!
        let data = try! Data(contentsOf: localUrl)
        let image = UIImage(data: data)!
        imageManager.imageCache.store(image, data: nil, forKey: url.cacheKey, cacheType: .disk) {
            let task = self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTFail()
            }
            task.cancel()
            self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .disk)
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTasks() {
        let expectation = self.expectation(description: "Wait for loading image")
        var tasks: [VVWebImageLoadTask] = []
        for url in urls {
            let task = imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTFail()
            }
            tasks.append(task)
        }
        XCTAssertEqual(imageManager.currentTaskCount, urls.count)
        for task in tasks {
            task.cancel()
        }
        XCTAssertEqual(imageManager.currentTaskCount, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTasksAndLoad() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            let task = imageManager.loadImage(with: url) { (_, _, _, _) in
                XCTFail()
            }
            task.cancel()
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelLoadImageTasksAndLoadRepeatedly() {
        for _ in 0..<10 {
            for url in urls {
                let expectation = self.expectation(description: "Wait for loading image")
                let task = imageManager.loadImage(with: url) { (_, _, _, _) in
                    XCTFail()
                }
                task.cancel()
                imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .none)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelSomeLoadImageTasks() {
        var i = 0
        for url in urls {
            let shouldCancel = (i % 2 == 0)
            let expectation: XCTestExpectation? = shouldCancel ? nil : self.expectation(description: "Wait for loading image")
            let task = imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                if shouldCancel {
                    XCTFail()
                } else {
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .none)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation!.fulfill()
                }
            }
            if shouldCancel {
                task.cancel()
            }
            i += 1
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelSomeLoadImageTasksAndLoad() {
        var i = 0
        for url in urls {
            let shouldCancel = (i % 2 == 0)
            let expectation: XCTestExpectation? = shouldCancel ? nil : self.expectation(description: "Wait for loading image")
            let task = imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                if shouldCancel {
                    XCTFail()
                } else {
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .none)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation!.fulfill()
                }
            }
            if shouldCancel {
                task.cancel()
                let expectation2 = self.expectation(description: "Wait for loading image")
                imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .none)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation2.fulfill()
                }
            }
            i += 1
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelAll() {
        let expectation = self.expectation(description: "Wait for loading image")
        for url in urls {
            imageManager.loadImage(with: url) { (_, _, _, _) in
                XCTFail()
            }
        }
        XCTAssertEqual(imageManager.currentTaskCount, urls.count)
        imageManager.cancelAll()
        XCTAssertEqual(imageManager.currentTaskCount, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelPreloading() {
        let expectation = self.expectation(description: "Wait for loading image")
        imageManager.preload(urls, progress: { (_, _, _) in
            XCTFail()
        }) { (_, _) in
            XCTFail()
        }
        XCTAssertEqual(imageManager.currentPreloadTaskCount, urls.count)
        imageManager.cancelPreloading()
        XCTAssertEqual(imageManager.currentPreloadTaskCount, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testOptionQueryDataWhenInMemory() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                var sentinel = false
                self.imageManager.loadImage(with: url, options: .queryDataWhenInMemory) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .all)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                    sentinel = true
                }
                XCTAssertFalse(sentinel)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testOptionIgnoreDiskCache() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url, options: .ignoreDiskCache) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                self.imageManager.imageCache.image(forKey: url.cacheKey, cacheType: .all) { (result) in
                    switch result {
                    case let .memory(image: memoryImage):
                        XCTAssertTrue(image == memoryImage)
                        expectation.fulfill()
                    default:
                        XCTFail()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testOptionRefreshCache() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                self.imageManager.loadImage(with: url, options: .refreshCache) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .none)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testOptionRetryFailedUrl() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = URL(string: "http://www.qq.com")!
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            let currentError = error! as NSError
            XCTAssertEqual(currentError.domain, VVWebImageErrorDomain)
            XCTAssertEqual(currentError.code, 0)
            self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                let currentError = error! as NSError
                XCTAssertEqual(currentError.domain, NSURLErrorDomain)
                XCTAssertEqual(currentError.code, NSURLErrorFileDoesNotExist)
                self.imageManager.loadImage(with: url, options: .retryFailedUrl) { (image, data, error, cacheType) in
                    let currentError = error! as NSError
                    XCTAssertEqual(currentError.domain, VVWebImageErrorDomain)
                    XCTAssertEqual(currentError.code, 0)
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
