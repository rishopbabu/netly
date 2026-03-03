import Foundation

public struct CommonAPIResponse: Decodable {
	public let status: String?
	public let message: String
}
