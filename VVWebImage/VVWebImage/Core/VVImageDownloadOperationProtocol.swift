//
//  VVImageDownloadOperation.swift
//  VVWebImage
//

import UIKit

public protocol VVImageDownloadOperationProtocol: AnyObject {
    var url: URL { get }
    var dataTaskId: Int { get }
    var downloadTasks: [VVImageDownloadTaskProtocol] { get }
    var imageCoder: VVImageCoder? { get set }
    var completion: (() -> Void)? { get set }
    
    init(request: URLRequest, session: URLSession)
    func add(task: VVImageDownloadTaskProtocol)
    func start()
    func cancel()
}

class VVMergeRequestImageDownloadOperation: NSObject, VVImageDownloadOperationProtocol {
    var url: URL { return request.url! }
    
    var dataTaskId: Int {
        stateLock.wait()
        let tid = dataTask?.taskIdentifier ?? 0
        stateLock.signal()
        return tid
    }
    
    weak var imageCoder: VVImageCoder?
    private var imageProgressiveCoder: VVImageProgressiveCoder?
    
    var completion: (() -> Void)?
    
    private let request: URLRequest
    private let session: URLSession
    private var tasks: [VVImageDownloadTaskProtocol]
    private var dataTask: URLSessionTask?
    private let taskLock: DispatchSemaphore
    private let stateLock: DispatchSemaphore
    private var imageData: Data?
    private var expectedSize: Int
    
    private var cancelled: Bool
    private var finished: Bool
    private var downloadFinished: Bool
    
    private lazy var coderQueue: DispatchQueue = {
        return VVDispatchQueuePool.userInitiated.currentQueue
    }()
    
    var downloadTasks: [VVImageDownloadTaskProtocol] {
        taskLock.wait()
        let currentTasks = tasks
        taskLock.signal()
        return currentTasks
    }
    
    required init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
        tasks = []
        taskLock = DispatchSemaphore(value: 1)
        stateLock = DispatchSemaphore(value: 1)
        expectedSize = 0
        cancelled = false
        finished = false
        downloadFinished = false
    }
    
    func add(task: VVImageDownloadTaskProtocol) {
        taskLock.wait()
        tasks.append(task)
        taskLock.signal()
    }
    
    func start() {
        stateLock.wait()
        defer { stateLock.signal() }
        if cancelled || finished { return } // Completion call back will not be called when task is cancelled
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
    }
    
    func cancel() {
        stateLock.wait()
        defer { stateLock.signal() }
        if finished { return }
        cancelled = true
        dataTask?.cancel()
        done()
    }
    
    private func done() {
        finished = true
        dataTask = nil
        completion?()
        completion = nil
    }
}

extension VVMergeRequestImageDownloadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        stateLock.wait()
        downloadFinished = true
        if error != nil {
            complete(withData: nil, error: error)
        } else {
            if let data = imageData {
                complete(withData: data, error: nil)
            } else {
                let noDataError = NSError(domain: VVWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No image data"])
                complete(withData: nil, error: noDataError)
            }
        }
        stateLock.signal()
        stateLock.wait()
        done()
        stateLock.signal()
    }
    
    private func complete(withData data: Data?, error: Error?) {
        taskLock.wait()
        let currentTasks = tasks
        taskLock.signal()
        for task in currentTasks where !task.isCancelled {
            task.completion(data, error)
        }
    }
}

extension VVMergeRequestImageDownloadOperation: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expectedSize = max(0, Int(response.expectedContentLength))
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        if statusCode >= 400 || statusCode == 304 {
            completionHandler(.cancel)
        } else {
            progress(with: nil, expectedSize: expectedSize, image: nil)
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if imageData == nil { imageData = Data(capacity: expectedSize) }
        imageData?.append(data)
        guard let currentImageData = imageData else { return }

        if let coder = imageCoder,
            imageProgressiveCoder == nil {
            if let coderManager = coder as? VVImageCoderManager {
                let coders = coderManager.coders
                for coder in coders {
                    if let progressiveCoder = coder as? VVImageProgressiveCoder,
                        progressiveCoder.canIncrementallyDecode(currentImageData) {
                        imageProgressiveCoder = progressiveCoder.copy() as? VVImageProgressiveCoder
                        break
                    }
                }
            } else if let progressiveCoder = coder as? VVImageProgressiveCoder {
                imageProgressiveCoder = progressiveCoder.copy() as? VVImageProgressiveCoder
            }
        }
        if let progressiveCoder = imageProgressiveCoder {
            let size = expectedSize
            let finished = currentImageData.count >= size
            coderQueue.async { [weak self] in
                guard let self = self, !self.cancelled, !self.finished else { return }
                let image = progressiveCoder.incrementallyDecodedImage(with: currentImageData, finished: finished)
                self.progress(with: currentImageData, expectedSize: size, image: image)
            }
        } else {
            progress(with: currentImageData, expectedSize: expectedSize, image: nil)
        }
    }
    
    func progress(with data: Data?, expectedSize: Int, image: UIImage?) {
        taskLock.wait()
        let currentTasks = tasks
        taskLock.signal()
        stateLock.wait()
        defer { stateLock.signal() }
        if downloadFinished { return }
        for task in currentTasks where !task.isCancelled {
            task.progress?(data, expectedSize, image)
        }
    }
}
