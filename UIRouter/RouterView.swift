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
    
    init(@ViewBuilder root: () -> Root) {
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
        .sheet(item: sheetBinding) { modalRoute in
            modalRoute.route.view()
                .environmentObject(router)
        }
        .fullScreenCover(item: fullScreenCoverBinding) { modalRoute in
            modalRoute.route.view()
                .environmentObject(router)
        }
    }
}

private extension RouterView {
    var sheetBinding: Binding<ModalRoute?> {
        Binding(
            get: {
                guard let modal = router.modal, modal.style == .sheet else { return nil }
                return modal
            },
            set: { newValue in
                if newValue == nil {
                    router.modal = nil
                }
            }
        )
    }
    
    var fullScreenCoverBinding: Binding<ModalRoute?> {
        Binding(
            get: {
                guard let modal = router.modal, modal.style == .fullScreenCover else { return nil }
                return modal
            },
            set: { newValue in
                if newValue == nil {
                    router.modal = nil
                }
            }
        )
    }
}
