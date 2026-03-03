import Foundation

/// The main class for the Netly library, providing a high-level API for network requests.
public final class Netly: NetworkClient, @unchecked Sendable {
    public static let shared = Netly()
    
    private let session: URLSessionProtocol
    private let requestBuilder: RequestBuilder
    private let responseHandler: ResponseHandler
    private let monitor: NetworkMonitorProtocol
    
    public init(session: URLSessionProtocol = URLSession.shared,
                requestBuilder: RequestBuilder = DefaultRequestBuilder(),
                responseHandler: ResponseHandler = DefaultResponseHandler(),
                monitor: NetworkMonitorProtocol = DefaultNetworkMonitor.shared) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.responseHandler = responseHandler
        self.monitor = monitor
    }
    
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard monitor.isConnected else {
            throw NetworkError.noInternet
        }
        
        let request = try requestBuilder.build(from: endpoint)
        let (data, response) = try await session.data(for: request)
        return try responseHandler.handle(data: data, response: response)
    }
}
