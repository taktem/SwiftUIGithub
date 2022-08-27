import SwiftUI

public extension Image {
    @ViewBuilder
    static func async(
        url: URL,
        scale: CGFloat = 1,
        @ViewBuilder success: @escaping ((Image) -> Image) = { $0 },
        @ViewBuilder failureImage: @escaping (() -> Image),
        @ViewBuilder placeholderImage: @escaping (() -> Image)
    ) -> some View {
        if #available(iOS 15.0, *) {
            AsyncImage(
                url: url,
                scale: scale,
                content: { e in
                    switch e {
                    case .success(let image): success(image)
                    case .failure: failureImage()
                    case .empty: placeholderImage()
                    @unknown default: placeholderImage()
                    }
                }
            )
        } else {
            AsyncImageForOldOS(
                url: url,
                scale: scale,
                success: success,
                failureImage: failureImage,
                inProgressImage: placeholderImage
            )
        }
    }
}

import UIKit
@available(iOS, introduced: 14.0, deprecated: 15.0)
struct AsyncImageForOldOS: View {
    enum Result {
        case success(Image)
        case failure
        case inProgress
    }
    
    @State var state: Result = .inProgress
    
    private let url: URL
    private let scale: Double
    private let success: ((Image) -> Image)
    private let failureImage: (() -> Image)
    private let inProgressImage: (() -> Image)

    init(
        url: URL,
        scale: Double,
        @ViewBuilder success: @escaping ((Image) -> Image),
        @ViewBuilder failureImage: @escaping (() -> Image),
        @ViewBuilder inProgressImage: @escaping (() -> Image)
    ) {
        self.url = url
        self.scale = scale
        self.success = success
        self.failureImage = failureImage
        self.inProgressImage = inProgressImage
    }

    var body: some View {
        ZStack {
            switch state {
            case .success(let image): success(image)
            case .failure: failureImage()
            case .inProgress: inProgressImage()
            }
        }
        .onAppear() {
            Task {
                do {
                    let result = try await URLSession.shared.data(from: url)
                    if
                        let response = result.1 as? HTTPURLResponse,
                        case 200...299 = response.statusCode,
                        let uiImage = UIImage(data: result.0) {
                        state = .success(Image(uiImage: uiImage))
                    } else {
                        state = .failure
                    }
                } catch {
                    state = .failure
                }
            }
        }
    }
}
