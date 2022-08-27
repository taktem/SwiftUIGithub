//
//  Created by taktem on 2022/08/19.
//

import Foundation

public struct GithubUser {
    public init(id: Int, userName: String, avatarURL: URL) {
        self.id = id
        self.userName = userName
        self.avatarURL = avatarURL
    }
    
    public let id: Int
    public let userName: String
    public let avatarURL: URL
}
