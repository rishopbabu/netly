import XCTest
import Foundation
@testable import netly

final class NetlyTests: XCTestCase {
    
    struct MockEndpoint: Endpoint {
        var baseURL: URL? = URL(string: "https://api.example.com")
        var path: String = "/test"
        var method: HTTPMethod = .get
        var headers: [String: String]? = nil
        var parameters: [String: Any]? = nil
        var bodyType: BodyType = .json
    }
    
    struct MockResponse: Decodable, Equatable {
        let message: String
    }
    
    class MockURLSession: URLSessionProtocol {
        var dataToReturn: Data?
        var responseToReturn: URLResponse?
        var errorToThrow: Error?
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if let error = errorToThrow {
                throw error
            }
            return (dataToReturn ?? Data(), responseToReturn ?? HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
    }
    
    class MockNetworkMonitor: NetworkMonitorProtocol {
        var isConnected: Bool = true
        var delegate: NetworkMonitorDelegate?
        func startMonitoring() {}
        func stopMonitoring() {}
    }

    func testRequestSuccess() async throws {
        // Arrange
        let mockData = "{\"message\": \"success\"}".data(using: .utf8)!
        let mockSession = MockURLSession()
        mockSession.dataToReturn = mockData
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        // Act
        let result: MockResponse = try await netly.request(endpoint)
        
        // Assert
        XCTAssertEqual(result.message, "success")
    }
    
    func testRequestNoInternet() async throws {
        // Arrange
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = false
        
        let netly = Netly(monitor: mockMonitor)
        let endpoint = MockEndpoint()
        
        // Act & Assert
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown noInternet error")
        } catch NetworkError.noInternet {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
