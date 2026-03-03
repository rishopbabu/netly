import Foundation

public enum BodyType {
	case json
	case formURLEncoded
	case multipart(boundary: String?, media: [Media]?)
}
