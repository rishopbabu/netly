//
//  BodyType.swift
//  netly
//
//  Created by Rishop Babu on 03/03/26.
//

import Foundation

	// MARK: - Body Types

enum BodyType {
	case json
	case formURLEncoded
	case multipart(boundary: String?, media: [Media]?)
}
