import Foundation

public protocol RequestBuilder {
    func build(from endpoint: Endpoint) throws -> URLRequest
}

public final class DefaultRequestBuilder: RequestBuilder {
    public init() {}
    
    public func build(from endpoint: Endpoint) throws -> URLRequest {
        guard let url = endpoint.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        switch endpoint.bodyType {
        case .json:
            try setJSONBody(for: &request, parameters: endpoint.parameters)
        case .formURLEncoded:
            try setFormURLEncodedBody(for: &request, parameters: endpoint.parameters)
        case .multipart(let boundary, let media):
            setMultipartBody(for: &request, parameters: endpoint.parameters, boundary: boundary, media: media)
        }
        
        return request
    }
    
    private func setJSONBody(for request: inout URLRequest, parameters: [String: Any]?) throws {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let parameters = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        }
    }
    
    private func setFormURLEncodedBody(for request: inout URLRequest, parameters: [String: Any]?) throws {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        guard let params = parameters else { return }
        
        let bodyString = params
            .compactMap { (key, value) -> String? in
                guard let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
    }
    
    private func setMultipartBody(for request: inout URLRequest, parameters: [String: Any]?, boundary: String?, media: [Media]?) {
        let finalBoundary = boundary ?? "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(finalBoundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let lineBreak = "\r\n"
        
        parameters?.forEach { key, value in
            body.append("--\(finalBoundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
            body.append("\(value)\(lineBreak)")
        }
        
        media?.forEach { media in
            body.append("--\(finalBoundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(media.key)\"; filename=\"\(media.filename)\"\(lineBreak)")
            body.append("Content-Type: \(media.mimeType)\(lineBreak + lineBreak)")
            body.append(media.data)
            body.append(lineBreak)
        }
        
        body.append("--\(finalBoundary)--\(lineBreak)")
        request.httpBody = body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
