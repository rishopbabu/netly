import XCTest
import Foundation
@testable import Netly

final class NetlyTests: XCTestCase {
    
    // MARK: - Mocks
    
    struct MockEndpoint: Endpoint {
        var url: URL? = URL(string: "https://api.example.com/test")
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
            let url = request.url ?? URL(string: "https://example.com")!
            let response = responseToReturn ?? HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (dataToReturn ?? Data(), response)
        }
    }
    
    class MockNetworkMonitor: NetworkMonitorProtocol {
        var isConnected: Bool = true
        var delegate: NetworkMonitorDelegate?
        func startMonitoring() {}
        func stopMonitoring() {}
        
        func simulateStatusChange(connected: Bool) {
            isConnected = connected
            delegate?.networkStatusDidChange(isConnected: connected)
        }
    }
    
    class MockNetworkMonitorDelegate: NetworkMonitorDelegate {
        var lastStatus: Bool?
        func networkStatusDidChange(isConnected: Bool) {
            lastStatus = isConnected
        }
    }

    // MARK: - Netly Tests

    func testRequestSuccess() async throws {
        let mockData = "{\"message\": \"success\"}".data(using: .utf8)!
        let mockSession = MockURLSession()
        mockSession.dataToReturn = mockData
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        let result: MockResponse = try await netly.request(endpoint)
        
        XCTAssertEqual(result.message, "success")
    }
    
    func testRequestNoInternet() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = false
        
        let netly = Netly(monitor: mockMonitor)
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown noInternet error")
        } catch NetworkError.noInternet {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestInvalidURL() async throws {
        struct InvalidEndpoint: Endpoint {
            var url: URL? = nil
            var method: HTTPMethod = .get
            var headers: [String: String]? = nil
            var parameters: [String: Any]? = nil
            var bodyType: BodyType = .json
        }
        
        let netly = Netly(monitor: MockNetworkMonitor())
        let endpoint = InvalidEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown invalidURL error")
        } catch NetworkError.invalidURL {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestInvalidResponse() async throws {
        let mockSession = MockURLSession()
        mockSession.responseToReturn = URLResponse(url: URL(string: "https://example.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown invalidResponse error")
        } catch NetworkError.invalidResponse {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestDecodingFailed() async throws {
        let mockData = "{\"wrong_key\": \"success\"}".data(using: .utf8)!
        let mockSession = MockURLSession()
        mockSession.dataToReturn = mockData
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown decodingFailed error")
        } catch NetworkError.decodingFailed {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestDecodingFailedWrongType() async throws {
        let mockData = "[{\"message\": \"success\"}]".data(using: .utf8)!
        let mockSession = MockURLSession()
        mockSession.dataToReturn = mockData
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown decodingFailed error")
        } catch NetworkError.decodingFailed {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestEmptyDataDecodingFailure() async throws {
        let mockSession = MockURLSession()
        mockSession.dataToReturn = Data()
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown decodingFailed error")
        } catch NetworkError.decodingFailed {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestServerErrorWithCommonResponse() async throws {
        let mockData = "{\"status\": \"error\", \"message\": \"Internal Server Error\"}".data(using: .utf8)!
        let mockSession = MockURLSession()
        mockSession.dataToReturn = mockData
        mockSession.responseToReturn = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown serverError")
        } catch let NetworkError.serverError(code, message) {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(message, "Internal Server Error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestHTTPErrorFallback() async throws {
        let mockData = "Not found".data(using: .utf8)!
        let mockSession = MockURLSession()
        mockSession.dataToReturn = mockData
        mockSession.responseToReturn = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        let netly = Netly(session: mockSession, monitor: MockNetworkMonitor())
        let endpoint = MockEndpoint()
        
        do {
            let _: MockResponse = try await netly.request(endpoint)
            XCTFail("Should have thrown httpError")
        } catch let NetworkError.httpError(code, message) {
            XCTAssertEqual(code, 404)
            XCTAssertEqual(message, "Not found")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - RequestBuilder Tests
    
    func testRequestBuilderHeaders() throws {
        let builder = DefaultRequestBuilder()
        let headers = ["X-API-Key": "secret", "Accept": "application/json"]
        let endpoint = MockEndpoint(headers: headers)
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testRequestBuilderJSONBody() throws {
        let builder = DefaultRequestBuilder()
        let parameters: [String: Any] = ["key": "value"]
        let endpoint = MockEndpoint(parameters: parameters, bodyType: .json)
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(request.httpBody)
        
        let decoded = try JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: String]
        XCTAssertEqual(decoded?["key"], "value")
    }

    func testRequestBuilderEmptyJSONParameters() throws {
        let builder = DefaultRequestBuilder()
        let endpoint = MockEndpoint(parameters: nil, bodyType: .json)
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNil(request.httpBody)
    }
    
    func testRequestBuilderFormURLEncodedBody() throws {
        let builder = DefaultRequestBuilder()
        let parameters: [String: Any] = ["key": "value", "space": "hello world"]
        let endpoint = MockEndpoint(parameters: parameters, bodyType: .formURLEncoded)
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertNotNil(request.httpBody)
        
        let bodyString = String(data: request.httpBody!, encoding: .utf8)
        XCTAssertTrue(bodyString?.contains("key=value") == true)
        XCTAssertTrue(bodyString?.contains("space=hello%20world") == true)
    }

    func testRequestBuilderEmptyFormParameters() throws {
        let builder = DefaultRequestBuilder()
        let endpoint = MockEndpoint(parameters: nil, bodyType: .formURLEncoded)
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertNil(request.httpBody)
    }
    
    func testRequestBuilderMultipartBody() throws {
        let builder = DefaultRequestBuilder()
        let boundary = "testBoundary"
        let media = Media(key: "file", filename: "test.txt", data: "hello".data(using: .utf8)!, mimeType: "text/plain")
        let endpoint = MockEndpoint(parameters: ["name": "test"], bodyType: .multipart(boundary: boundary, media: [media]))
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "multipart/form-data; boundary=\(boundary)")
        XCTAssertNotNil(request.httpBody)
        
        let bodyString = String(data: request.httpBody!, encoding: .utf8)
        XCTAssertTrue(bodyString?.contains("--\(boundary)") == true)
        XCTAssertTrue(bodyString?.contains("Content-Disposition: form-data; name=\"name\"") == true)
        XCTAssertTrue(bodyString?.contains("test") == true)
        XCTAssertTrue(bodyString?.contains("filename=\"test.txt\"") == true)
        XCTAssertTrue(bodyString?.contains("Content-Type: text/plain") == true)
        XCTAssertTrue(bodyString?.contains("hello") == true)
        XCTAssertTrue(bodyString?.contains("--\(boundary)--") == true)
    }

    func testRequestBuilderEmptyMultipartParameters() throws {
        let builder = DefaultRequestBuilder()
        let boundary = "testBoundary"
        let endpoint = MockEndpoint(parameters: nil, bodyType: .multipart(boundary: boundary, media: nil))
        
        let request = try builder.build(from: endpoint)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "multipart/form-data; boundary=\(boundary)")
        XCTAssertNotNil(request.httpBody)
        
        let bodyString = String(data: request.httpBody!, encoding: .utf8)
        XCTAssertEqual(bodyString, "--\(boundary)--\r\n")
    }

    // MARK: - Endpoint Tests
    
    func testEndpointURL() {
        let url = URL(string: "https://api.example.com/v1/users")
        struct TestEndpoint: Endpoint {
            var url: URL?
            var method: HTTPMethod = .get
            var headers: [String: String]? = nil
            var parameters: [String: Any]? = nil
            var bodyType: BodyType = .json
        }
        
        let endpoint = TestEndpoint(url: url)
        XCTAssertEqual(endpoint.url?.absoluteString, "https://api.example.com/v1/users")
    }

    // MARK: - NetworkMonitor Tests

    func testNetworkMonitorDelegate() {
        let monitor = MockNetworkMonitor()
        let delegate = MockNetworkMonitorDelegate()
        monitor.delegate = delegate
        
        monitor.simulateStatusChange(connected: false)
        XCTAssertEqual(delegate.lastStatus, false)
        
        monitor.simulateStatusChange(connected: true)
        XCTAssertEqual(delegate.lastStatus, true)
    }

    // MARK: - NetworkError Tests
    
    func testNetworkErrorDescriptions() {
        XCTAssertEqual(NetworkError.noInternet.errorDescription, NetworkConstants.noInternetConnectionMessage)
        XCTAssertEqual(NetworkError.invalidURL.errorDescription, NetworkConstants.invalidURL)
        XCTAssertEqual(NetworkError.invalidResponse.errorDescription, NetworkConstants.invalidServerResponse)
        XCTAssertEqual(NetworkError.invalidParameters.errorDescription, NetworkConstants.invalidParameters)
        
        let decodingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fail"])
        XCTAssertTrue(NetworkError.decodingFailed(decodingError).errorDescription?.contains("Decoding failed") == true)
        
        XCTAssertEqual(NetworkError.httpError(code: 404, message: "Not Found").errorDescription, "Not Found")
        XCTAssertEqual(NetworkError.serverError(code: 500, message: "Error").errorDescription, "Error")
    }
}
