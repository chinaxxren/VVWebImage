//
//  TestImageDownloadTask.swift
//  VVWebImageTests
//
//  Created by waqu Lu on 1/28/19.
//  Copyright © 2019 waqu Lu. All rights reserved.
//

import UIKit
import VVWebImage

class TestImageDownloadTask: VVImageDownloadTaskProtocol {
    private(set) var sentinel: Int32
    private(set) var url: URL
    private(set) var isCancelled: Bool
    private(set) var progress: VVImageDownloaderProgress?
    private(set) var completion: VVImageDownloaderCompletion
    
    init(sentinel: Int32, url: URL, progress: VVImageDownloaderProgress?, completion: @escaping VVImageDownloaderCompletion) {
        self.sentinel = sentinel
        self.url = url
        self.isCancelled = false
        self.progress = progress
        self.completion = { (_, _) in
            completion(nil, NSError(domain: "TestError", code: 0, userInfo: nil))
        }
    }
    
    func cancel() { isCancelled = true }
}
