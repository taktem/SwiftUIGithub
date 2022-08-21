//
//  Created by taktem on 2022/08/07
//

import SwiftUI
import Domain
import Infra

@MainActor final class RepositoriesViewModel: ObservableObject {
    var userName: String
    @Published var hasChildView = false
    
    init(userName: String) {
        self.userName = userName
    }
}

struct RepositoriesView: View {
    @StateObject var viewModel: RepositoriesViewModel

    var body: some View {
        NavigationLink(
            destination: Text("\(viewModel.userName)'s Repository Detail"),
            isActive: $viewModel.hasChildView,
            label: { EmptyView() })
        
        Button("Detail") {
            viewModel.hasChildView = true
        }
    }
}

struct RepositoriesView_Previews: PreviewProvider {
    static var previews: some View {
        RepositoriesView(viewModel: .init(userName: "Test"))
    }
}
