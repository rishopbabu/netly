import Foundation

public protocol Endpoint {
    var baseURL: URL? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var bodyType: BodyType { get }
}

extension Endpoint {
    public var url: URL? {
        guard let baseURL = baseURL else { return URL(string: path) }
        return baseURL.appendingPathComponent(path)
    }
}
