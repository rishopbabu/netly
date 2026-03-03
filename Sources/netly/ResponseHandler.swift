import Foundation

public protocol ResponseHandler {
    func handle<T: Decodable>(data: Data, response: URLResponse) throws -> T
}

public final class DefaultResponseHandler: ResponseHandler {
    public init() {}
    
    public func handle<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        } else {
            // Try decoding a common API error model if available, or fallback
            if let apiError = try? JSONDecoder().decode(CommonAPIResponse.self, from: data) {
                throw NetworkError.serverError(code: httpResponse.statusCode, message: apiError.message)
            }
            
            let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw NetworkError.httpError(code: httpResponse.statusCode, message: message)
        }
    }
}
