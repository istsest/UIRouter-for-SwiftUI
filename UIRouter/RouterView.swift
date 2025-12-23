//
//  RouterView.swift
//  Router
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI
import Combine

public struct RouterView<Root: View>: View {
    @StateObject private var router = UIRouter()
    
    private let root: Root
    
    public init(@ViewBuilder root: () -> Root) {
        self.root = root()
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            root
                .environmentObject(router)
                .navigationDestination(for: AnyRoute.self) { anyRoute in
                    anyRoute.route.view()
                        .environmentObject(router)
                }
        }
        .modifier(ModalStackModifier(router: router, currentIndex: 0))
    }
}

// MARK: - Modal Stack Modifier
private struct ModalStackModifier: ViewModifier {
    @ObservedObject var router: UIRouter
    let currentIndex: Int
    
    func body(content: Content) -> some View {
        content
            .sheet(item: sheetBinding) { modalRoute in
                modalRoute.route.view()
                    .environmentObject(router)
                    .modifier(ModalStackModifier(router: router, currentIndex: currentIndex + 1))
            }
            .fullScreenCover(item: fullScreenCoverBinding) { modalRoute in
                modalRoute.route.view()
                    .environmentObject(router)
                    .modifier(ModalStackModifier(router: router, currentIndex: currentIndex + 1))
            }
    }
    
    private var currentModal: ModalRoute? {
        guard currentIndex < router.modalStack.count else { return nil }
        return router.modalStack[currentIndex]
    }
    
    private var sheetBinding: Binding<ModalRoute?> {
        Binding(
            get: {
                guard let modal = currentModal, modal.style == .sheet else { return nil }
                return modal
            },
            set: { newValue in
                if newValue == nil {
                    dismissFromIndex()
                }
            }
        )
    }
    
    private var fullScreenCoverBinding: Binding<ModalRoute?> {
        Binding(
            get: {
                guard let modal = currentModal, modal.style == .fullScreenCover else { return nil }
                return modal
            },
            set: { newValue in
                if newValue == nil {
                    dismissFromIndex()
                }
            }
        )
    }
    
    private func dismissFromIndex() {
        // When user dismisses via swipe, remove all modals from this index onwards
        guard currentIndex < router.modalStack.count else { return }
        router.modalStack.removeSubrange(currentIndex...)
    }
}

struct InjectRouter: ViewModifier {
    public func body(content: Content) -> some View {
        RouterView {
            content
        }
    }
}

public extension View {
    @MainActor func injectRouter() -> some View {
        return modifier(InjectRouter())
    }
}
