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

enum PresentationStyle {
    case sheet
    case fullScreenCover
}

public struct ModalRoute: Identifiable {
    public let id = UUID()
    let route: any UIRoute
    let style: PresentationStyle
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
