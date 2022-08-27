//
//  Created by taktem on 2022/08/19.
//

import Foundation
import APIClient
import Domain

private struct GithubUsersRequest: DecodableRequestConfiguration {
    struct RootDTO: Decodable {
        struct GithubUserDTO: Decodable {
            let id: Int
            let userName: String
            let avatarURL: URL
            
            enum CodingKeys: String, CodingKey {
                case id
                case userName = "login"
                case avatarURL = "avatar_url"
            }
        }

        let items: [GithubUserDTO]
    }
    typealias Response = RootDTO

    let method = Method.get
    let endpoint = Endpoint(hostName: "https://api.github.com", path: "/search/users")
    let headers: [String : String] = ["Accept": "application/vnd.github.v3+json"]
    let parameters: [String : Any]
    
    public init(searchWord: String) {
        parameters = ["q": searchWord]
    }
}

public struct GithubUsersRepository {
    public init() {}
    
    public func fetch(searchWord: String) async throws -> [GithubUser] {
        try await APIClient().connect(config: GithubUsersRequest(searchWord: searchWord))
            .items
            .map { GithubUser(id: $0.id, userName: $0.userName, avatarURL: $0.avatarURL) }
    }
}
