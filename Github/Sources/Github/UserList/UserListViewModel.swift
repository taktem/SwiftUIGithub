//
//  Created by taktem on 2022/08/06
//

import Combine
import Infra

struct UserViewObject: Identifiable {
    var id: String { return name }
    var name: String
}

@MainActor final class UserListViewModel: ObservableObject {
    @Published var textFieldValue = ""
    @Published var items: [UserViewObject] = []
    
    func onTap() {
        Task {
            let repo = try! await GithubUsersRepository().fetch(searchWord: textFieldValue)
            items = repo.map { UserViewObject(name: $0.userName) }
        }
    }
}
