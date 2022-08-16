import Foundation

public enum RequestError: Swift.Error {
    case noEncoderAvailable(value: Any)
    case invalidBody(description: String, value: Any)
}

public enum APIClientError: Swift.Error {
    case unknown(message: String?)
    case invalidRequest(RequestError)
    case urlSessionError(code: Int, description: String)
    case httpResponseError(request: URLRequest, statusCode: Int, reason: String?, description: String?)

    public var localizedDescription: String {
        switch self {
        case .unknown: return "unknown"
        case .invalidRequest(let error): return "invalidRequest: \(error.reason)"
        case .urlSessionError(let code, let description):
            return "urlSessionError code: \(code), description: \(description)"
        case .httpResponseError(let request, let statusCode, let reason, let description):
            return "httpResponseError request: \(request.debugDescription), statusCode: \(statusCode), reason: \(reason ?? ""), description: \(description ?? "")"
        }
    }
}

public protocol APIClientLoggerProtocol {
    func log(_ message: String)
}

public protocol APIClientErrorHandlerProtocol {
    func handle(error: APIClientError)
}

public final class APIClient {
    struct Dependency {
        let session: URLSessionClientProtocol

        static var `default`: Dependency {
            return Dependency(
                session: URLSessionClient()
            )
        }
    }

    private static var loggers: [APIClientLoggerProtocol] = []
    private static var defaultErrorHandlers: [APIClientErrorHandlerProtocol] = []

    private let dependency: Dependency

    init(dependency: Dependency = .default) {
        self.dependency = dependency
    }

    public static func setupLoggers(_ loggers: [APIClientLoggerProtocol]) {
        self.loggers = loggers
    }

    public static func setupDefaultErrorHandlers(_ errorHandlers: [APIClientErrorHandlerProtocol]) {
        self.defaultErrorHandlers = errorHandlers
    }

    func connect<Config: RequestConfiguration>(
        config: Config,
        customErrorHandler: @escaping ((APIClientError) -> Bool) = { _ in return true }
        ) async throws -> Config.Response {
            let session = dependency.session
            
            do {
                let result = try await session.request(
                    url: config.endpoint.url,
                    method: config.method.stringValue,
                    headers: config.headers,
                    parameters: config.parameters
                )
                
                return try config.response(from: result)
            } catch(let error) {
                guard let error = error as? APIClientError else { throw error }

                APIClient.loggers.forEach {
                    $0.log("API.connect onSuccess \(config.summary)")
                }
                
                if customErrorHandler(error) {
                    APIClient.defaultErrorHandlers.forEach { $0.handle(error: error) }
                }
            }

            let result = try await session.request(
                url: config.endpoint.url,
                method: config.method.stringValue,
                headers: config.headers,
                parameters: config.parameters
            )
            
            return try config.response(from: result)
    }
}

protocol URLSessionClientProtocol {
    func request(url: URL, method: String, headers: [String: String], parameters: [String: Any]) async throws -> Data
}

private struct URLSessionClientTask {
    let url: URL
    let method: String
    let headers: [String: String]
    let parameters: [String: Any]

    let queryItemEncoderHandler: URLQueryValueEncoderHandler
    // TODO: Suggestion: introduce Body encoder

    func makeRequest() throws -> URLRequest {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!

        switch method {
        case "GET", "DELETE":
            var queryItems = urlComponents.queryItems
            try parameters.forEach {
                if let array = $0.value as? [Any] {
                    let key = "\($0.key)[]"
                    for value in array {
                        queryItems?.append(.init(
                            name: key,
                            value: try queryItemEncoderHandler.encode(value)
                        ))
                    }
                } else {
                    queryItems?.append(.init(
                        name: $0.key,
                        value: try queryItemEncoderHandler.encode($0.value)
                    ))
                }
            }
            urlComponents.queryItems = queryItems
        default: ()
        }

        var result = URLRequest(url: urlComponents.url!)
        result.httpMethod = method
        headers.forEach {
            result.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        switch method {
        case "GET", "DELETE":
            ()
        case "POST", "PUT", "PATCH":
            // MEMO: https://developer.apple.com/documentation/foundation/jsonserialization/1413636-data
            guard JSONSerialization.isValidJSONObject(parameters) else {
                throw RequestError.invalidBody(description: "encodeのできないHttp Body", value: parameters)
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                result.setValue("application/json", forHTTPHeaderField: "Content-Type")
                result.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
                result.httpBody = data
            } catch let error {
                throw RequestError.invalidBody(description: error.localizedDescription, value: parameters)
            }
        default:
            throw APIClientError.unknown(message: "未知なmethod(\(method))")
        }

        return result
    }
}

struct URLSessionClient: URLSessionClientProtocol {

    func request(url: URL, method: String, headers: [String: String], parameters: [String: Any]) async throws -> Data {
        let request: URLRequest
        do {
            request = try URLSessionClientTask(
                url: url,
                method: method,
                headers: headers,
                parameters: parameters,
                queryItemEncoderHandler: URLQueryValueEncoderHandler.default
            )
            .makeRequest()
        } catch let error {
            switch error {
            case let e as RequestError:
                throw APIClientError.invalidRequest(e)
            case let e as APIClientError:
                throw e
            default:
                throw APIClientError.unknown(message: "URLSessionClient内でのリクエスト生成時に何か起きているので要調査")

            }
        }
        
        let dataTaskResult: (Data, URLResponse)
        if #available(iOS 15.0, *) {
            do {
                dataTaskResult = try await URLSession.shared.data(for: request)
            } catch(let error) {
                throw APIClientError.urlSessionError(
                    code: (error as NSError).code,
                    description: error.localizedDescription
                )
            }
        } else {
            dataTaskResult = try await withCheckedThrowingContinuation { continuation in
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(with: .failure(APIClientError.urlSessionError(
                            code: (error as NSError).code,
                            description: error.localizedDescription
                        )))
                        return
                    }
                    
                    if
                        let data = data,
                        let response = response {
                        continuation.resume(with: .success((data, response)))
                    } else {
                        continuation.resume(with: .failure(APIClientError.unknown(message: "基本的にここに来ることは想定していない")))
                    }
                }

                task.resume()
            }
        }
        
        let result: Data
        if let response = dataTaskResult.1 as? HTTPURLResponse {
            if response.statusCode == 204 {
                result = Data()
            } else if case 200...299 = response.statusCode {
                result = dataTaskResult.0
            } else {
                throw APIClientError.httpResponseError(
                    request: request,
                    statusCode: response.statusCode,
                    reason: {
                        if let stringified = String(data: dataTaskResult.0, encoding: .utf8) {
                            return stringified
                        }
                        return nil
                    }(),
                    description: response.debugDescription
                )
            }
        } else {
            throw APIClientError.unknown(message: "基本的にここに来ることは想定していない")
        }
        
        return result
    }
}

private extension RequestConfiguration {
    var summary: String {
        return "endpoint: \(endpoint.url.absoluteString), parameters: \(parameters)"
    }
}

private extension RequestError {
    var reason: String {
        switch self {
        case .noEncoderAvailable(let value):
            return "noEncoderAvailable: \(type(of: value))"
        case .invalidBody(let description, let value):
            return "invalidBody: \(description), value: \(value)"
        }
    }
}
