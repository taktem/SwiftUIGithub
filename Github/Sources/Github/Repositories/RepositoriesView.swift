//
//  Created by taktem on 2022/08/07
//

import SwiftUI

struct NavigationChildView {
    enum Child {
        case repository
    }
    var isChildViewVisible: Bool {
        didSet {
            child = nil
        }
    }
    var child: Child?
}

@MainActor final class RepositoriesViewModel: ObservableObject {
    var userName: String
    
    init(userName: String) {
        self.userName = userName
    }
}

struct RepositoriesView: View {
    @StateObject var viewModel: RepositoriesViewModel

    var body: some View {
        ZStack {
            VStack {
                Text(viewModel.userName)
            }
        }
    }
}

struct RepositoriesView_Previews: PreviewProvider {
    static var previews: some View {
        RepositoriesView(viewModel: .init(userName: "Test"))
    }
}
