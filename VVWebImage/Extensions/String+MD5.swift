//
//  String+MD5.swift
//  VVWebImage
//

import CommonCrypto
import Foundation

public extension String {
    // 计算字符串的MD5值
    var vv_md5: String {
        // 将字符串转换为UTF-8编码的数据
        guard let data = data(using: .utf8) else { return self }
        // 创建一个长度为CC_MD5_DIGEST_LENGTH的UInt8数组，用于存储MD5值
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        // 使用data的withUnsafeBytes方法，将data转换为UnsafeRawBufferPointer类型
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            // 调用CC_MD5函数，计算data的MD5值，并将结果存储到digest数组中
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        // 将digest数组中的每个元素转换为16进制字符串，并拼接成一个字符串
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}