//
//  Created by taktem on 2022/08/06
//

import Foundation
import Combine
import Infra

struct UserViewObject: Identifiable {
    var id: String { return name }
    var name: String
    var avatarURL: URL
}

@MainActor final class UserListViewModel: ObservableObject {
    @Published var textFieldValue = ""
    @Published var items: [UserViewObject] = []
    
    func onTap() {
        Task {
            let users = try! await GithubUsersRepository().fetch(searchWord: textFieldValue)
            items = users.map { UserViewObject(name: $0.userName, avatarURL: $0.avatarURL) }
        }
    }
}
