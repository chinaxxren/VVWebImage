//
//  VVWebCacheResource.swift
//  VVWebImage
//

import UIKit

/// VVWebCacheResource defines how to download and cache image
public protocol VVWebCacheResource {
    var cacheKey: String { get }
    var downloadUrl: URL { get }
}

extension URL: VVWebCacheResource {
    public var cacheKey: String { return absoluteString }
    public var downloadUrl: URL { return self }
}
