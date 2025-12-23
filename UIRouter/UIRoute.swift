//
//  UIRoute.swift
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI

public protocol UIRoute: Hashable, Identifiable {
    func view() -> AnyView
}

public extension UIRoute {
    var id: Self { self }
}

public enum PresentationStyle {
    case sheet
    case fullScreenCover
}

/// Represents a modal presentation in the modal stack.
/// Each instance has a unique ID, so even modals wrapping the same route type
/// are treated as distinct instances for SwiftUI's identity system.
public struct ModalRoute: Identifiable {
    /// Unique identifier for this modal instance.
    /// Each ModalRoute gets a new UUID, ensuring distinct identity in the stack.
    public let id = UUID()
    public let route: any UIRoute
    public let style: PresentationStyle
    
    public init(route: any UIRoute, style: PresentationStyle) {
        self.route = route
        self.style = style
    }
}

struct AnyRoute: Hashable {
    let route: any UIRoute
    
    init(_ route: any UIRoute) {
        self.route = route
    }
    
    static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool {
        AnyHashable(lhs.route) == AnyHashable(rhs.route)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(route))
    }
}
