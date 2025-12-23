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
    ///
    /// - Note: This value may not match all scenarios:
    ///   - Different presentation styles (sheet vs fullScreenCover) may have different durations
    ///   - iOS accessibility settings (e.g., reduced motion) may affect animation speed
    ///   - Custom animation timings may require adjusting this value
    private static let modalTransitionDuration: TimeInterval = 0.35
    
    /// Maximum number of retry attempts for queued operations to prevent unbounded callbacks
    private static let maxRetryAttempts = 10
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
        guard !modalStack.isEmpty else { return }
        dismissToIndex(0)
    }
    
    func dismissModals(_ count: Int) {
        guard count > 0 else { return }
        let removeCount = min(count, modalStack.count)
        let targetIndex = modalStack.count - removeCount
        dismissToIndex(targetIndex)
    }
    
    /// Dismisses all modals positioned above (later than) a specific route in the modal stack.
    ///
    /// The specified route and all modals below it (earlier in the stack) are retained.
    /// For example, if the stack is [A, B, C, D] and you call `dismissModalsAfter(B)`,
    /// the result will be [A, B].
    ///
    /// - Note: If the same route appears multiple times in the stack, only the first
    ///   occurrence is matched. Consider using index-based methods for precise control.
    /// - Parameter route: The route to find; modals above this route will be dismissed
    /// - Returns: `true` if the route was found and modals were dismissed, `false` if not found
    @discardableResult
    func dismissModalsAfter(_ route: any UIRoute) -> Bool {
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return false
        }
        dismissToIndex(index + 1)
        return true
    }
    
    /// Dismisses all modals from a specific route upward, including the route itself.
    ///
    /// For example, if the stack is [A, B, C, D] and you call `dismissModalsTo(B)`,
    /// the result will be [A].
    ///
    /// - Note: If the same route appears multiple times in the stack, only the first
    ///   occurrence is matched. Consider using index-based methods for precise control.
    /// - Parameter route: The route to find; this route and all above it will be dismissed
    /// - Returns: `true` if the route was found and modals were dismissed, `false` if not found
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
    internal func handleSwipeDismiss(fromIndex index: Int, retryCount: Int = 0) {
        guard index < modalStack.count else { return }
        
        // If already transitioning, queue this swipe dismiss operation with retry limit
        guard !isTransitioning else {
            guard retryCount < Self.maxRetryAttempts else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
                self?.handleSwipeDismiss(fromIndex: index, retryCount: retryCount + 1)
            }
            return
        }
        
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
            // Delay resetting isTransitioning to ensure any in-flight animations
            // have time to complete before we allow new transitions
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
                self?.isTransitioning = false
            }
            return
        }
        
        let next = pendingModals.removeFirst()
        modalStack.append(next)
        
        // Process remaining pending modals or wait for last modal's animation to complete
        if !pendingModals.isEmpty {
            scheduleNextPendingModal()
        } else {
            // Wait for the last modal's presentation animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
                self?.isTransitioning = false
            }
        }
    }
    
    func scheduleNextPendingModal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
            self?.processPendingModals()
        }
    }
    
    /// Dismisses modals to a target index, animating only the topmost modal
    func dismissToIndex(_ targetIndex: Int, retryCount: Int = 0) {
        guard modalStack.count > targetIndex else {
            return
        }
        
        // If already transitioning, queue this dismiss operation with retry limit
        guard !isTransitioning else {
            guard retryCount < Self.maxRetryAttempts else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
                self?.dismissToIndex(targetIndex, retryCount: retryCount + 1)
            }
            return
        }
        
        isTransitioning = true
        
        // If exactly one modal to dismiss, remove it with animation
        if modalStack.count - targetIndex == 1 {
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
        
        // Dismiss the remaining topmost modal with animation on next run loop
        // to ensure the transaction above has fully completed
        DispatchQueue.main.async { [weak self] in
            self?.modalStack.removeLast()
            self?.scheduleTransitionCompletion()
        }
    }
    
    func scheduleTransitionCompletion() {
        // Wait for dismiss animation to complete before processing pending modals
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
            self?.processPendingModals()
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
