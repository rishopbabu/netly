# Netly

Universal networking for Apple platforms. Simple, async/await powered, and zero-dependency.

## Features

- **Protocol-Oriented**: Highly modular and testable through protocol-based components.
- **Async/Await**: Native support for Swift's modern concurrency.
- **Modern Architecture**: Separate concerns for request building, response handling, and network monitoring.
- **Easy Customization**: Inject your own `RequestBuilder`, `ResponseHandler`, or `URLSession`.
- **Media Uploads**: Built-in support for multipart/form-data with media files.
- **Network Monitoring**: Integrated connectivity checks before making requests.

## Installation

Add Netly to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/rishopbabu/Netly.git", from: "1.0.0")
]
```

## Usage

### 1. Define your Endpoint

Create a struct or enum that conforms to the `Endpoint` protocol.

```swift
import Netly
import Foundation

struct GetUsersEndpoint: Endpoint {
    var url: URL? = URL(string: "https://api.example.com/users")
    var method: HTTPMethod = .get
    var headers: [String : String]? = nil
    var parameters: [String : Any]? = nil
    var bodyType: BodyType = .json
}
```

### 2. Perform a Request

Use the `Netly.shared` instance (or create your own) to perform the request.

```swift
import Netly

struct User: Decodable {
    let id: Int
    let name: String
}

func fetchUsers() async {
    do {
        let endpoint = GetUsersEndpoint()
        let users: [User] = try await Netly.shared.request(endpoint)
        print("Fetched \(users.count) users")
    } catch {
        print("Request failed with error: \(error.localizedDescription)")
    }
}
```

### 3. Handle Errors

Netly provides a descriptive `NetworkError` enum that conforms to `LocalizedError`.

```swift
do {
    // request...
} catch let error as NetworkError {
    switch error {
    case .noInternet:
        print("Please check your internet connection.")
    case .serverError(let code, let message):
        print("Server error \(code): \(message)")
    case .decodingFailed(let underlyingError):
        print("Failed to decode response: \(underlyingError)")
    default:
        print(error.localizedDescription)
    }
} catch {
    print("An unknown error occurred: \(error)")
}
```

### 4. Modular Components

Because Netly is built on protocols, you can easily customize its behavior.

- **`RequestBuilder`**: Customize how `URLRequest` is constructed.
- **`ResponseHandler`**: Customize how responses are validated and decoded.
- **`NetworkMonitor`**: Provide your own logic for checking connectivity.
- **`URLSessionProtocol`**: Inject a mock session for unit testing.

```swift
// Example: Creating a custom Netly instance with a custom session
let mockSession = MyMockURLSession()
let customNetly = Netly(session: mockSession)
```

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 12.0+ / watchOS 4.0+ / visionOS 1.0+
- Swift 6.0+
