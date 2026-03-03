//
//  NetworkErrorHandler.swift
//  netly
//
//  Created by Rishop Babu on 03/03/26.
//

import Foundation

@MainActor
final class NetworkErrorHandler {
	static let shared = NetworkErrorHandler()
	private init() {}
	
		/// Handles all network errors and returns a user-friendly message
	func handle(_ error: NetworkError) -> String {
		switch error {
			case .noInternet:
				return NetworkConstants.noInternetConnectionMessage
				
			case .invalidURL:
				return NetworkConstants.invalidURL
				
			case .serverError(let code, let message),
					.httpError(let code, let message):
				debugPrint("❌ HTTP Error \(code): \(message)")
				return message.isEmpty ? NetworkConstants.somethingWentWrong : message
				
			case .decodingFailed:
				return NetworkConstants.failedToParseResponse
				
			default:
				return NetworkConstants.somethingWentWrong
		}
	}
}
