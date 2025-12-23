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
    
    /// Maximum number of pending modals to prevent unbounded queue growth
    private static let maxPendingModals = 10
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
    /// Presents a route as a sheet modal.
    ///
    /// If a transition is in progress, the modal is automatically queued and
    /// presented after the current transition completes. This ensures smooth
    /// animations without conflicts.
    ///
    /// - Parameter route: The route to present as a sheet
    func presentSheet(_ route: any UIRoute) {
        let modal = ModalRoute(route: route, style: .sheet)
        enqueueOrPresent(modal)
    }
    
    /// Presents a route as a full screen cover modal.
    ///
    /// If a transition is in progress, the modal is automatically queued and
    /// presented after the current transition completes. This ensures smooth
    /// animations without conflicts.
    ///
    /// - Parameter route: The route to present as a full screen cover
    func presentFullScreenCover(_ route: any UIRoute) {
        let modal = ModalRoute(route: route, style: .fullScreenCover)
        enqueueOrPresent(modal)
    }
    
    /// Dismisses the topmost modal in the stack.
    ///
    /// If a transition is in progress, the dismiss operation is queued and
    /// executed after the current transition completes. Only the topmost modal's
    /// dismiss animation is shown.
    func dismissModal() {
        guard !modalStack.isEmpty else { return }
        dismissToIndex(modalStack.count - 1)
    }
    
    /// Dismisses all modals in the stack.
    ///
    /// When multiple modals are dismissed, intermediate modals are removed
    /// instantly (without animation) and only the topmost modal animates out.
    /// If a transition is in progress, this operation is queued.
    func dismissAllModals() {
        guard !modalStack.isEmpty else { return }
        dismissToIndex(0)
    }
    
    /// Dismisses a specific number of modals from the top of the stack.
    ///
    /// When multiple modals are dismissed, intermediate modals are removed
    /// instantly (without animation) and only the topmost modal animates out.
    /// If a transition is in progress, this operation is queued.
    ///
    /// - Parameter count: The number of modals to dismiss (must be > 0)
    func dismissModals(_ count: Int) {
        guard count > 0 else { return }
        let removeCount = min(count, modalStack.count)
        let targetIndex = modalStack.count - removeCount
        dismissToIndex(targetIndex)
    }
    
    /// Dismisses all modals above a specific route in the modal stack.
    ///
    /// The specified route and all modals below it are retained.
    /// For example, if the stack is [A, B, C, D] and you call `dismissModalsAbove(B)`,
    /// the result will be [A, B].
    ///
    /// - Note: If the same route appears multiple times in the stack, only the first
    ///   occurrence is matched. Consider using index-based methods for precise control.
    /// - Parameter route: The route to find; modals above this route will be dismissed
    /// - Returns: `true` if the route was found and modals were dismissed, `false` if not found
    @discardableResult
    func dismissModalsAbove(_ route: any UIRoute) -> Bool {
        guard !modalStack.isEmpty else { return false }
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return false
        }
        warnIfDuplicateRoutes(targetRoute, foundAt: index)
        dismissToIndex(index + 1)
        return true
    }
    
    /// Dismisses all modals through (including) a specific route.
    ///
    /// For example, if the stack is [A, B, C, D] and you call `dismissModalsThrough(B)`,
    /// the result will be [A]. The specified route (B) is also dismissed.
    ///
    /// - Note: If the same route appears multiple times in the stack, only the first
    ///   occurrence is matched. Consider using index-based methods for precise control.
    /// - Parameter route: The route to find; this route and all above it will be dismissed
    /// - Returns: `true` if the route was found and modals were dismissed, `false` if not found
    @discardableResult
    func dismissModalsThrough(_ route: any UIRoute) -> Bool {
        guard !modalStack.isEmpty else { return false }
        let targetRoute = AnyRoute(route)
        guard let index = modalStack.firstIndex(where: { AnyRoute($0.route) == targetRoute }) else {
            return false
        }
        warnIfDuplicateRoutes(targetRoute, foundAt: index)
        dismissToIndex(index)
        return true
    }
    
    private func warnIfDuplicateRoutes(_ targetRoute: AnyRoute, foundAt firstIndex: Int) {
        #if DEBUG
        let duplicateCount = modalStack.dropFirst(firstIndex + 1)
            .filter { AnyRoute($0.route) == targetRoute }
            .count
        if duplicateCount > 0 {
            print("[UIRouter] Warning: Route appears \(duplicateCount + 1) times in modal stack. Only the first occurrence (index \(firstIndex)) was matched.")
        }
        #endif
    }
}

// MARK: - Internal Helpers (for RouterView)
extension UIRouter {
    /// Called when user dismisses a modal via swipe gesture
    internal func handleSwipeDismiss(fromIndex index: Int, retryCount: Int = 0) {
        guard index < modalStack.count else { return }
        
        // If already transitioning, queue this swipe dismiss operation with retry limit
        guard !isTransitioning else {
            guard retryCount < Self.maxRetryAttempts else {
                #if DEBUG
                print("[UIRouter] Warning: Swipe dismiss from index \(index) was dropped after \(retryCount) retry attempts due to ongoing transitions.")
                #endif
                return
            }
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
            // Check pending queue size to prevent unbounded growth
            guard pendingModals.count < Self.maxPendingModals else {
                #if DEBUG
                print("[UIRouter] Warning: Pending modal queue is full (\(Self.maxPendingModals)). Modal presentation ignored.")
                #endif
                return
            }
            pendingModals.append(modal)
        } else {
            // When presenting directly (not queued), mark as transitioning
            // and schedule completion to avoid overlapping animations.
            isTransitioning = true
            modalStack.append(modal)
            scheduleTransitionCompletion()
        }
    }
    
    func processPendingModals() {
        guard !pendingModals.isEmpty else {
            // If there are no pending modals and the modal stack is empty,
            // we can safely reset transitioning state immediately without
            // waiting for an extra animation duration.
            if modalStack.isEmpty {
                isTransitioning = false
            } else {
                // Delay resetting isTransitioning to ensure any in-flight animations
                // have time to complete before we allow new transitions
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.modalTransitionDuration) { [weak self] in
                    self?.isTransitioning = false
                }
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
    
    /// Dismisses modals down to a target index, keeping modals at indices 0..<targetIndex.
    ///
    /// For example, if the stack has 4 modals [0, 1, 2, 3] and targetIndex is 2,
    /// modals at indices 2 and 3 are dismissed, leaving [0, 1].
    ///
    /// - Note: If targetIndex >= modalStack.count, no operation is performed.
    ///   Only the topmost modal animates; intermediate modals are removed instantly.
    /// - Parameter targetIndex: The index to dismiss down to (exclusive - this index is not kept)
    /// - Parameter retryCount: Internal retry counter (do not set manually)
    func dismissToIndex(_ targetIndex: Int, retryCount: Int = 0) {
        // Validate that targetIndex is within the meaningful range 0...modalStack.count.
        // - targetIndex == modalStack.count is a valid no-op (keep all modals).
        // - Values outside this range are likely caller errors and will be logged in DEBUG builds.
        guard targetIndex >= 0 && targetIndex <= modalStack.count else {
            #if DEBUG
            print("UIRouter.dismissToIndex: Invalid targetIndex \(targetIndex). Expected between 0 and \(modalStack.count). No operation performed.")
            #endif
            return
        }
        
        // If already transitioning, queue this dismiss operation with retry limit
        guard !isTransitioning else {
            guard retryCount < Self.maxRetryAttempts else {
                #if DEBUG
                print("UIRouter.dismissToIndex: Dropping dismiss to index \(targetIndex) after \(retryCount) retries. Current modal depth: \(modalStack.count).")
                #endif
                return
            }
            
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
            // Unexpected state: no modal available to dismiss. Cancel the transition
            // and process any pending modals immediately, since no animation will occur.
            isTransitioning = false
            processPendingModals()
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
