import Foundation
import Network

public protocol NetworkMonitorDelegate: AnyObject {
    func networkStatusDidChange(isConnected: Bool)
}

public protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var delegate: NetworkMonitorDelegate? { get set }
    func startMonitoring()
    func stopMonitoring()
}

public final class DefaultNetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    public static let shared = DefaultNetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private var _isConnected: Bool = true
    private let lock = NSLock()
    
    public var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConnected
    }
    
    public weak var delegate: NetworkMonitorDelegate?
    
    private init() {}
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            self?.updateStatus(connected)
        }
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateStatus(_ connected: Bool) {
        lock.lock()
        _isConnected = connected
        lock.unlock()
        
        delegate?.networkStatusDidChange(isConnected: connected)
    }
}
