import Foundation

public enum NetworkError: Error, LocalizedError {
	case noInternet
	case invalidURL
	case invalidResponse
	case invalidParameters
	case decodingFailed(Error)
	case httpError(code: Int, message: String)
	case serverError(code: Int, message: String)
	
	public var errorDescription: String? {
		switch self {
			case .noInternet:
				return NetworkConstants.noInternetConnectionMessage
			case .invalidURL:
				return NetworkConstants.invalidURL
			case .invalidResponse:
				return NetworkConstants.invalidServerResponse
			case .invalidParameters:
				return NetworkConstants.invalidParameters
			case .decodingFailed(let error):
				return "Decoding failed: \(error.localizedDescription)"
			case .httpError(_, let message), .serverError(_, let message):
				return message
		}
	}
}
