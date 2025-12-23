//
//  UIRouter.swift
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI
import Combine

public class UIRouter: ObservableObject {
    @Published var path: [AnyRoute] = []
    @Published var modalStack: [ModalRoute] = []
    
    private var isTransitioning = false
    private var pendingModals: [ModalRoute] = []
}

// MARK: - Navigation Methods
public extension UIRouter {
    func push(_ route: any UIRoute) {
        path.append(AnyRoute(route))
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func pop(_ count: Int) {
        let removeCount = min(count, path.count)
        path.removeLast(removeCount)
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func popTo(_ route: any UIRoute) {
        let targetRoute = AnyRoute(route)
        guard let index = path.firstIndex(where: { $0 == targetRoute }) else {
            return
        }
        path = Array(path.prefix(through: index))
    }
    
    func replacePath(_ newPath: [any UIRoute]) {
        path = newPath.map { AnyRoute($0) }
    }
}

// MARK: - Modal Presentation Methods
public extension UIRouter {
    func presentSheet(_ route: any UIRoute) {
        let modal = ModalRoute(route: route, style: .sheet)
        enqueueOrPresent(modal)
    }
    
    func presentFullScreenCover(_ route: any UIRoute) {
        let modal = ModalRoute(route: route, style: .fullScreenCover)
        enqueueOrPresent(modal)
    }
    
    func dismissModal() {
        guard !modalStack.isEmpty else { return }
        dismissToIndex(modalStack.count - 1)
    }
    
    func dismissAllModals() {
        dismissToIndex(0)
    }
    
    func dismissModals(_ count: Int) {
        let removeCount = min(count, modalStack.count)
        let targetIndex = modalStack.count - removeCount
        dismissToIndex(targetIndex)
    }
    
    /// Dismisses all modals after a specific route (the specified route is retained)
    func dismissModalsAfter(_ route: any UIRoute) {
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return
        }
        dismissToIndex(index + 1)
    }
    
    /// Dismisses all modals up to and including a specific route (the specified route is also removed)
    func dismissModalsTo(_ route: any UIRoute) {
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return
        }
        dismissToIndex(index)
    }
}

// MARK: - Private Helpers
private extension UIRouter {
    func enqueueOrPresent(_ modal: ModalRoute) {
        if isTransitioning {
            pendingModals.append(modal)
        } else {
            modalStack.append(modal)
        }
    }
    
    func processPendingModals() {
        guard !pendingModals.isEmpty else {
            isTransitioning = false
            return
        }
        
        let next = pendingModals.removeFirst()
        modalStack.append(next)
        
        // Process remaining pending modals after a short delay
        if !pendingModals.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.processPendingModals()
            }
        } else {
            isTransitioning = false
        }
    }
    
    /// Dismisses modals to a target index, animating only the topmost modal
    func dismissToIndex(_ targetIndex: Int) {
        guard modalStack.count > targetIndex else {
            processPendingModals()
            return
        }
        
        isTransitioning = true
        
        // If only one modal to dismiss, just remove it with animation
        if modalStack.count == targetIndex + 1 {
            modalStack.removeLast()
            scheduleTransitionCompletion()
            return
        }
        
        // Remove all intermediate modals without animation, keep only the topmost one
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            // Keep only target modals + the topmost one for animated dismissal
            modalStack = Array(modalStack.prefix(targetIndex)) + [modalStack.last!]
        }
        
        // Dismiss the remaining topmost modal with animation
        DispatchQueue.main.async {
            self.modalStack.removeLast()
            self.scheduleTransitionCompletion()
        }
    }
    
    func scheduleTransitionCompletion() {
        // Wait for dismiss animation to complete before processing pending modals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.processPendingModals()
        }
    }
}

// MARK: - Utility Methods
public extension UIRouter {
    var depth: Int {
        path.count
    }
    
    var isEmpty: Bool {
        path.isEmpty
    }
    
    var isModalPresented: Bool {
        !modalStack.isEmpty
    }
    
    var modalDepth: Int {
        modalStack.count
    }
    
    var currentModal: ModalRoute? {
        modalStack.last
    }
}
