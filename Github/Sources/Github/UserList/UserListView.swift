//
//  Created by taktem on 2022/08/06
//

import SwiftUI
import ProjectFoundation


public struct UserListView: View {
    @StateObject var viewModel = UserListViewModel()
    
    public init() {}

    public var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("User Name", text: $viewModel.textFieldValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("検索") {
                        viewModel.onTap()
                    }
                    .frame(height: 32)
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    .background(Color.primaryMain)
                    .cornerRadius(8)
                }
                .padding()
                List {
                    ForEach(viewModel.items) { s in
                        NavigationLink(
                            destination: RepositoriesView(
                                viewModel: .init(userName: s.name)
                            ),
                            label: { Text(s.name) }
                        )
                        .listRowInsets(EdgeInsets())
                    }
                    .padding()
                }
                .listStyle(.plain)
                
            }
            #if !os(macOS)
            .navigationBarTitle("ユーザー検索", displayMode: .inline)
            #endif
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        UserListView()
    }
}
