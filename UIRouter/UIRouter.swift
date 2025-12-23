//
//  UIRouter.swift
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI
import Combine

@MainActor
public class UIRouter: ObservableObject {
    @Published var path: [AnyRoute] = []
    @Published var modalStack: [ModalRoute] = []
    
    private var isTransitioning = false
    private var pendingModals: [ModalRoute] = []
    
    /// Duration to wait for modal transition animations to complete.
    ///
    /// This value (0.35s) is chosen to roughly match the default system
    /// modal presentation/dismissal duration used by UIKit/SwiftUI.
    /// If custom animation timings are used, consider adjusting this value.
    private static let modalTransitionDuration: TimeInterval = 0.35
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
        guard count > 0 else { return }
        let removeCount = min(count, modalStack.count)
        let targetIndex = modalStack.count - removeCount
        dismissToIndex(targetIndex)
    }
    
    /// Dismisses all modals that appear after a specific route in the modal stack,
    /// retaining the specified route and all modals below it (earlier in the stack).
    /// - Returns: `true` if the route was found and modals were dismissed, `false` if the route was not found
    @discardableResult
    func dismissModalsAfter(_ route: any UIRoute) -> Bool {
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return false
        }
        dismissToIndex(index + 1)
        return true
    }
    
    /// Dismisses all modals up to and including a specific route (the specified route is also removed)
    /// - Returns: `true` if the route was found and modals were dismissed, `false` if the route was not found
    @discardableResult
    func dismissModalsTo(_ route: any UIRoute) -> Bool {
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return false
        }
        dismissToIndex(index)
        return true
    }
}

// MARK: - Internal Helpers (for RouterView)
extension UIRouter {
    /// Called when user dismisses a modal via swipe gesture
    internal func handleSwipeDismiss(fromIndex index: Int) {
        guard index < modalStack.count else { return }
        
        isTransitioning = true
        
        // Remove all modals from this index onwards (SwiftUI handles animation)
        modalStack.removeSubrange(index...)
        
        // Schedule pending modals processing after animation completes
        scheduleTransitionCompletion()
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
            scheduleNextPendingModal()
        } else {
            isTransitioning = false
        }
    }
    
    func scheduleNextPendingModal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
            self?.processPendingModals()
        }
    }
    
    /// Dismisses modals to a target index, animating only the topmost modal
    func dismissToIndex(_ targetIndex: Int) {
        guard modalStack.count > targetIndex else {
            return
        }
        
        isTransitioning = true
        
        // If only one modal to dismiss, just remove it with animation
        if modalStack.count == targetIndex + 1 {
            modalStack.removeLast()
            scheduleTransitionCompletion()
            return
        }
        
        // Safely capture the topmost modal before modification
        guard let lastModal = modalStack.last else {
            isTransitioning = false
            return
        }
        
        // Remove all intermediate modals without animation, keep only the topmost one
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            // Keep only target modals + the captured topmost one for animated dismissal
            modalStack = Array(modalStack.prefix(targetIndex)) + [lastModal]
        }
        
        // Dismiss the remaining topmost modal with animation
        DispatchQueue.main.async {
            self.modalStack.removeLast()
            self.scheduleTransitionCompletion()
        }
    }
    
    func scheduleTransitionCompletion() {
        // Wait for dismiss animation to complete before processing pending modals
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) {
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
