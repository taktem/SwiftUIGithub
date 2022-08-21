//
//  Created by taktem on 2022/08/19.
//

import Foundation

public struct GithubUser {
    public init(id: Int, userName: String) {
        self.id = id
        self.userName = userName
    }
    
    public let id: Int
    public let userName: String
}
