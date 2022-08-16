//
//  Created by taktem on 2022/08/13
//

#if os(iOS)
import UIKit
#endif
import SwiftUI

class Shared {
    static func setupNavigationBar() {
        #if os(iOS)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}
