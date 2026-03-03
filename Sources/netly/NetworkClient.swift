import Foundation

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

public protocol NetworkClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
