//
//  NetworkError.swift
//  netly
//
//  Created by Rishop Babu on 03/03/26.
//

import Foundation

	// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
	case noInternet
	case invalidURL
	case invalidResponse
	case invalidParameters
	case decodingFailed(Error)
	case httpError(code: Int, message: String)
	case serverError(code: Int, message: String)
	
	var errorDescription: String? {
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
