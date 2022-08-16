//
//  Created by taktem on 2022/08/14
//

import Foundation

public enum Method {
    case get
    case post
    case put
    case patch
    case delete

    var stringValue: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .patch: return "PATCH"
        case .delete: return "DELETE"
        }
    }
}

public struct Endpoint {
    let hostName: String
    let path: String

    var url: URL {
        var urlComponents = URLComponents(string: hostName)!
        urlComponents.path = path

        return urlComponents.url!
    }
}

protocol RequestConfiguration {
    associatedtype Response

    var method: Method { get }
    var endpoint: Endpoint { get }
    var headers: [String: String] { get }
    var parameters: [String: Any] { get }

    func response(from data: Data) throws -> Response
}

protocol DecodableRequestConfiguration: RequestConfiguration where Response: Decodable { }
extension DecodableRequestConfiguration {
    func response(from data: Data) throws -> Response {
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
