//
//  Created by taktem on 2022/08/06
//

import SwiftUI
import Github

@main
struct SwiftUIGithubApp: App {
    init() {
        Shared.setupNavigationBar()
    }
    
    var body: some Scene {
        WindowGroup {
            UserListView()
        }
    }
}


