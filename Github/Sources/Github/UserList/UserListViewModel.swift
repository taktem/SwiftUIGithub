//
//  Created by taktem on 2022/08/06
//

import Combine

@MainActor final class UserListViewModel: ObservableObject {
    @Published var textFieldValue = ""
    @Published var items: [Item] = [.init(name: "taktem"), .init(name: "hoge")]
    
    func onTap() {
        items.append(.init(name: "test"))
    }
}
