import Foundation
import Combine

struct DiskUsage {
    let used: Int64
    let free: Int64
    let total: Int64
    
    var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }
    
    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
    }
    
    var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
    }
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}

struct MemoryUsage {
    let used: UInt64
    let free: UInt64
    let total: UInt64
    
    var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }
    
    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
    }
    
    var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory)
    }
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
    }
}

@MainActor
class SystemMonitor: ObservableObject {
    @Published var diskUsage: DiskUsage = DiskUsage(used: 0, free: 0, total: 0)
    @Published var memoryUsage: MemoryUsage = MemoryUsage(used: 0, free: 0, total: 0)
    @Published var cpuUsage: Double = 0
    @Published var lastUpdated: Date = Date()
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 5.0
    
    init() {
        updateStats()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStats()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateStats() {
        updateDiskUsage()
        updateMemoryUsage()
        updateCPUUsage()
        lastUpdated = Date()
    }
    
    private func updateDiskUsage() {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: "/")
            let totalSize = attributes[.systemSize] as? Int64 ?? 0
            let freeSize = attributes[.systemFreeSize] as? Int64 ?? 0
            let usedSize = totalSize - freeSize
            
            diskUsage = DiskUsage(used: usedSize, free: freeSize, total: totalSize)
        } catch {
            diskUsage = DiskUsage(used: 0, free: 0, total: 0)
        }
    }
    
    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            memoryUsage = MemoryUsage(used: 0, free: 0, total: 0)
            return
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        
        let used = active + wired + compressed
        let free = total - used
        
        memoryUsage = MemoryUsage(used: used, free: free, total: total)
    }
    
    private func updateCPUUsage() {
        var cpuInfo: processor_info_array_t?
        var numCPUs: natural_t = 0
        var numCPUInfo: mach_msg_type_number_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCPUInfo)
        
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            cpuUsage = 0
            return
        }
        
        var totalUser: Int32 = 0
        var totalSystem: Int32 = 0
        var totalIdle: Int32 = 0
        
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += cpuInfo[offset + Int(CPU_STATE_USER)]
            totalSystem += cpuInfo[offset + Int(CPU_STATE_SYSTEM)]
            totalIdle += cpuInfo[offset + Int(CPU_STATE_IDLE)]
        }
        
        let totalTicks = totalUser + totalSystem + totalIdle
        if totalTicks > 0 {
            cpuUsage = Double(totalUser + totalSystem) / Double(totalTicks) * 100
        } else {
            cpuUsage = 0
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size))
    }
    
    var timeSinceLastUpdate: String {
        let seconds = Int(-lastUpdated.timeIntervalSinceNow)
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            return "\(seconds / 60)m ago"
        }
    }
}
