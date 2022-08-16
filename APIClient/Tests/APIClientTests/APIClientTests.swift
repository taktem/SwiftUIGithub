//
//  Created by taktem on 2022/08/14
//

import XCTest
@testable import APIClient

private final class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        do {
            let (response, data) = try MockURLProtocol.requestHandler!(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MEMO: In this step, httpBody is pushed to stream already.
// https://stackoverflow.com/questions/36555018/why-is-the-httpbody-of-a-request-inside-an-nsurlprotocol-subclass-always-nil
private extension URLRequest {
    var httpBodyFromStream: Data? {
        guard let bodyStream = self.httpBodyStream else { return nil }
        let bufferSize = 64
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        bodyStream.open()
        var data = Data()
        while bodyStream.hasBytesAvailable {
            let readDat = bodyStream.read(buffer, maxLength: bufferSize)
            data.append(buffer, count: readDat)
        }
        buffer.deallocate()
        bodyStream.close()

        return data
    }
}

class URLSessionTaskTests: XCTestCase {
    func test正常系() async {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        let 期待値 = "Success".data(using: .utf8)!

        MockURLProtocol.requestHandler = {
            (HTTPURLResponse(url: $0.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, 期待値)
        }
        URLProtocol.registerClass(MockURLProtocol.self)

        let response = try! await URLSessionClient().request(url: URL(string: "https://taktem.com")!, method: "GET", headers: [:], parameters: [:])
        XCTAssertEqual(response, 期待値)
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }

    func testエラー() async {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        let 期待値 = "Error".data(using: .utf8)!

        MockURLProtocol.requestHandler = {
            (HTTPURLResponse(url: $0.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!, 期待値)
        }
        URLProtocol.registerClass(MockURLProtocol.self)

        do {
            let _ = try await URLSessionClient().request(url: URL(string: "https://taktem.com")!, method: "GET", headers: [:], parameters: [:])
            XCTAssertThrowsError("リクエスト成功してはいけない")
        } catch(let error ) {
            if case .httpResponseError(_, let statusCode, _, _) = (error as! APIClientError) {
                XCTAssertEqual(statusCode, 400)
            }
        }
    }

    func testPostPutPatchJSON正常系() async {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        URLProtocol.registerClass(MockURLProtocol.self)
        let client = URLSessionClient()

        
        func match(body: [String: Any], method: String) async throws -> Data {
            let 期待値 = try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            MockURLProtocol.requestHandler = {
                XCTAssertEqual($0.httpBodyFromStream, 期待値)
                return (HTTPURLResponse(url: $0.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, 期待値)
            }
            return try await client.request(
                url: URL(string: "https://taktem.com")!,
                method: method,
                headers: [:],
                parameters: body
            )
        }

        let body: [String: Any] = {
            return ["content": [ "list": [1, 2, 3, 4]]]
        }()
        
        do {
            for method in ["POST", "PUT", "PATCH"] {
                let _ = try await match(body: body, method: method)
            }
        } catch {
            XCTAssertThrowsError("リクエスト失敗してはいけない")
        }
        
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }

    func testPostPutPatchJSONエラー() async {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        URLProtocol.registerClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = {
            return (HTTPURLResponse(url: $0.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }

        let client = URLSessionClient()
        func executeTest(body: [String: Any], method: String) async throws -> Data {
            return try await client.request(
                url: URL(string: "https://taktem.com")!,
                method: method,
                headers: [:],
                parameters: body
            )
        }
        let invalidBody: [String: Any] = {
            return ["content": UIImage()]
        }()

        let testCases: [(line: UInt, method: String, body: [String: Any])] = [
            (#line, "POST", invalidBody),
            (#line, "PUT", invalidBody),
            (#line, "PATCH", invalidBody)
        ]

        for (line, method, body) in testCases {
            do {
                let _ = try await executeTest(body: body, method: method)
                XCTFail("成功してはいけない", line: line)
            } catch {
            }
        }
    }
}

class APIClientTests: XCTestCase {
    struct StubSession: URLSessionClientProtocol {

        let response: Data

        init(value: Data) {
            response = value
        }

        func request(url: URL, method: String, headers: [String: String], parameters: [String: Any]) async throws -> Data {
            return response
        }
    }

    func test基本形正常パターン() async {
        struct ダミーConfig {
            let data: Data
        }

        struct RequestConfigurationダミーConfig {
            struct Get: RequestConfiguration {
                typealias Response = ダミーConfig
                let endpoint = Endpoint(
                    hostName: "https://taktem.com",
                    path: "/dummy")
                let method = Method.get
                let headers: [String : String] = [:]
                let parameters: [String: Any] = [:]

                init() {}

                func response(from data: Data) throws -> ダミーConfig {
                    // テスト用なので、受けたdataをそのまま露出させる
                    return ダミーConfig(data: data)
                }
            }
        }

        let 期待値 = "Success".data(using: .utf8)!
        let client = APIClient(dependency: APIClient.Dependency(session: StubSession(value: 期待値)))

        let result = try! await client.connect(config: RequestConfigurationダミーConfig.Get())
        XCTAssertEqual(result.data, 期待値)
    }

    func testDecodable正常パターン() async {
        struct ダミーConfig: Decodable, Equatable {
            let value: String
        }

        struct RequestConfigurationダミーConfig {
            struct Get: DecodableRequestConfiguration {
                typealias Response = ダミーConfig
                let endpoint = Endpoint(
                    hostName: "https://taktem.com",
                    path: "/dummy")
                let method = Method.get
                let headers: [String : String] = [:]
                let parameters: [String: Any] = [:]

                init() {}
            }
        }

        let 期待値: [String: String] = ["value": "Success"]
        let 期待値をJson化したもの = try! JSONSerialization.data(withJSONObject: 期待値, options: [])
        let client = APIClient(dependency: APIClient.Dependency(session: StubSession(value: 期待値をJson化したもの)))

        let result = try! await client.connect(config: RequestConfigurationダミーConfig.Get())
        XCTAssertEqual(result, ダミーConfig(value: 期待値["value"]!))
    }

    func test型がDecodableであっても明示的に指定されない限りは勝手にDecodeしない() async {
        struct ダミーConfig: Decodable {
            let data: Data
        }

        struct RequestConfigurationダミーConfig {
            struct Get: RequestConfiguration {
                typealias Response = ダミーConfig
                let endpoint = Endpoint(
                    hostName: "https://taktem.com",
                    path: "/dummy")
                let method = Method.get
                let headers: [String : String] = [:]
                let needsAccessToken = true
                let parameters: [String: Any] = [:]

                init() {}

                func response(from data: Data) throws -> ダミーConfig {
                    // テスト用なので、受けたdataをそのまま露出させる
                    return ダミーConfig(data: data)
                }
            }
        }

        let 期待値 = "Success".data(using: .utf8)!
        let client = APIClient(dependency: APIClient.Dependency(session: StubSession(value: 期待値)))
        let result = try! await client.connect(config: RequestConfigurationダミーConfig.Get())
        XCTAssertEqual(result.data, 期待値)
    }
}
