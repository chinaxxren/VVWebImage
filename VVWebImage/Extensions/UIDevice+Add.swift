//
//  UIDevice+VVAdd.swift
//  VVWebImage
//

import UIKit

extension UIDevice {
    // 获取设备总内存
    static var vv_totalMemory: Int64 { return Int64(ProcessInfo().physicalMemory) }

    // 获取设备可用内存
    static var vv_freeMemory: Int64 {
        let host_port = mach_host_self()
        var page_size: vm_size_t = 0
        // 获取页大小
        guard host_page_size(host_port, &page_size) == KERN_SUCCESS else { return -1 }
        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size)
        // 创建vm_statistics_data_t结构体
        let hostInfo = vm_statistics_t.allocate(capacity: 1)
        // 将vm_statistics_data_t结构体转换为integer_t类型
        let kern = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
            // 获取虚拟内存统计信息
            host_statistics(host_port, HOST_VM_INFO, $0, &host_size)
        }
        // 获取vm_statistics_data_t结构体
        let vm_stat = hostInfo.move()
        // 释放vm_statistics_data_t结构体
        hostInfo.deallocate()
        // 判断是否获取成功
        guard kern == KERN_SUCCESS else { return -1 }
        // 返回可用内存
        return Int64(page_size) * Int64(vm_stat.free_count)
    }
}