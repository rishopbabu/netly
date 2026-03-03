import Foundation

public protocol Endpoint {
    var url: URL? { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var bodyType: BodyType { get }
}
