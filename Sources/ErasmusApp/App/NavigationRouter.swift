import SwiftUI

enum DeepLinkTarget: Equatable {
    case chat(conversationId: String)
    case profile(userId: String)
    case post(postId: String)
    case notifications
}

@MainActor
class NavigationRouter: ObservableObject {
    static let shared = NavigationRouter()
    @Published var pendingTarget: DeepLinkTarget? = nil
    private init() {}
}
