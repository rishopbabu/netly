	// The Swift Programming Language
	// https://docs.swift.org/swift-book

import Foundation
import Network


	// MARK: - Network Manager Class
@MainActor
final class NetworkManager: @unchecked Sendable {
	static let shared = NetworkManager()
	
	private let monitor = NWPathMonitor()
	private let queue = DispatchQueue(label: "NetworkMonitor")
	
	private var _isConnected: Bool = true
	private let lock = NSLock()
	
	var isConnected: Bool {
		lock.lock()
		defer {
			lock.unlock()
		}
		
		return _isConnected
	}
	
		// MARK: - Public Method
	
	func request<T: Decodable>(urlString: String, method: HTTPMethod, parameters: [String: Any]? = nil, bodyType: BodyType,  headers: [String: String]? = nil, responseType: T.Type) async throws -> T {
		
			// MARK: - Internet & URL Validation
		guard isConnected else { throw NetworkError.noInternet }
		guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
		
			// MARK: - Request Setup
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		
			// Add Headers
		headers?.forEach { key, value in
			request.setValue(value, forHTTPHeaderField: key)
		}
		
			// Add Body
		switch bodyType {
			case .formURLEncoded:
				try setFormURLEncodedBody(for: &request, parameters: parameters)
				
			case .json:
				try setJSONBody(for: &request, parameters: parameters)
				
			case .multipart(let boundary, let media):
				setMultipartBody(for: &request, parameters: parameters, boundary: boundary, media: media)
		}
		
			// MARK: - Perform Request
		let (data, response) = try await URLSession.shared.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw NetworkError.invalidResponse
		}
		
			// MARK: - Debug Raw Response
		if let raw = String(data: data, encoding: .utf8) {
			debugPrint("📩 [\(httpResponse.statusCode)] \(urlString)\nResponse: \(raw)")
		}
		
		if (200...299).contains(httpResponse.statusCode) {
			do {
				return try JSONDecoder().decode(T.self, from: data)
			} catch {
				throw NetworkError.decodingFailed(error)
			}
		} else {
				// Try decoding a common API error model
			if let apiError = try? JSONDecoder().decode(CommonAPIResponse.self, from: data) {
				throw NetworkError.serverError(code: httpResponse.statusCode, message: apiError.message)
			}
			
				// Fallback: use HTTP status text or raw body
			let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
			throw NetworkError.httpError(code: httpResponse.statusCode, message: message)
		}
	}
}

extension NetworkManager {
		// MARK: - Private Body Builders
	private func setFormURLEncodedBody(for request: inout URLRequest, parameters: [String: Any]?) throws {
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		guard let params = parameters as? [String: String] else {
			throw NetworkError.invalidParameters
		}
		
		let bodyString = params
			.map { "\($0.key)=\(percentEscape($0.value))" }
			.joined(separator: "&")
		
		request.httpBody = bodyString.data(using: .utf8)
	}
	
	private func setJSONBody(for request: inout URLRequest, parameters: [String: Any]?) throws {
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		if let parameters = parameters {
			request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
		}
	}
	
	private func setMultipartBody(for request: inout URLRequest, parameters: [String: Any]?, boundary: String?, media: [Media]?) {
		let finalBoundary = boundary ?? "Boundary-\(UUID().uuidString)"
		request.setValue("multipart/form-data; boundary=\(finalBoundary)", forHTTPHeaderField: "Content-Type")
		request.httpBody = createMultipartBody(parameters: parameters, media: media, boundary: finalBoundary)
	}
	
		// MARK: - Multipart Helper
	private func createMultipartBody(parameters: [String: Any]?, media: [Media]?, boundary: String) -> Data {
		var body = Data()
		let lineBreak = "\r\n"
		
			// Parameters
		parameters?.forEach { key, value in
			body.append("--\(boundary)\(lineBreak)")
			body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
			body.append("\(value)\(lineBreak)")
		}
		
			// Media Files
		media?.forEach { media in
			body.append("--\(boundary)\(lineBreak)")
			body.append("Content-Disposition: form-data; name=\"\(media.key)\"; filename=\"\(media.filename)\"\(lineBreak)")
			body.append("Content-Type: \(media.mimeType)\(lineBreak + lineBreak)")
			body.append(media.data)
			body.append(lineBreak)
		}
		
		body.append("--\(boundary)--\(lineBreak)")
		return body
	}
	
		// MARK: - Percent Escape
	private func percentEscape(_ string: String) -> String {
		let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._* ")
		return string
			.addingPercentEncoding(withAllowedCharacters: allowed)?
			.replacingOccurrences(
				of: NetworkConstants.Space,
				with: "+"
			) ?? string
	}
}
