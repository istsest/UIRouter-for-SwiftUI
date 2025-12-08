# UIRouter Swift Package

A type-safe, SwiftUI-native navigation and routing framework with support for tab-based navigation, independent navigation stacks, and modal presentations.

## Features

- ✅ Type-safe routing with protocol-based routes
- ✅ Simple single-stack navigation
- ✅ Tab-based navigation with independent stacks per tab
- ✅ Modal presentations (sheets and full-screen covers)
- ✅ Programmatic navigation control
- ✅ SwiftUI-native implementation
- ✅ No third-party dependencies

## Requirements

- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+
- Swift 5.9+
- SwiftUI
- Combine

## Installation

### Swift Package Manager

Add UIRouter to your project using Swift Package Manager:

#### In Xcode

1. Select **File → Add Package Dependencies...**
2. Enter the package repository URL: `https://github.com/yourusername/UIRouter.git`
3. Select the version you want to use (e.g., "Up to Next Major Version" from 1.0.0)
4. Add the package to your target

#### In Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/UIRouter.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["UIRouter"]
        )
    ]
)
```

> **Important:** Make sure your core files are organized in the `Sources/UIRouter/` directory before publishing. See [PACKAGE_STRUCTURE.md](PACKAGE_STRUCTURE.md) for details.

## Quick Start

### 1. Define Your Routes

```swift
import UIRouter

enum AppRoute: UIRoute {
    case detail(text: String)
    case settings
    
    func view() -> AnyView {
        switch self {
        case .detail(let text):
            return AnyView(Text("Detail: \(text)"))
        case .settings:
            return AnyView(Text("Settings"))
        }
    }
}
```

### 2. Use RouterView

```swift
import SwiftUI
import UIRouter

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView {
                ContentView()
            }
        }
    }
}
```

### 3. Navigate in Your Views

```swift
struct ContentView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        VStack {
            Button("Go to Detail") {
                router.push(AppRoute.detail(text: "Hello"))
            }
            
            Button("Show Settings") {
                router.presentSheet(AppRoute.settings)
            }
        }
    }
}
```

## Navigation Types

### Simple Navigation - `RouterView`

Single navigation stack without tabs.

```swift
RouterView {
    ContentView()
}
```

### Tab-Based Navigation - `TabRouterView`

Multiple tabs, each with their own independent navigation stack.

```swift
enum AppTab: String, Hashable {
    case home, search, profile
}

TabRouterView(
    tabs: [
        UIRouteTabItem(tag: AppTab.home) {
            Label("Home", systemImage: "house.fill")
        } content: {
            HomeView()
        },
        UIRouteTabItem(tag: AppTab.search) {
            Label("Search", systemImage: "magnifyingglass")
        } content: {
            SearchView()
        }
    ],
    initialTab: .home
)
```

## API Reference

### Navigation Methods

```swift
// Push a route
router.push(AppRoute.detail(text: "Hello"))

// Pop back one level
router.pop()

// Pop multiple levels
router.pop(2)

// Pop to root
router.popToRoot()

// Pop to specific route
router.popTo(someRoute)

// Replace entire navigation path
router.replacePath([route1, route2])
```

### Modal Presentation

```swift
// Present sheet
router.presentSheet(AppRoute.profile(name: "John"))

// Present full screen cover
router.presentFullScreenCover(AppRoute.about)

// Dismiss modal
router.dismissModal()
```

### Tab Management (TabRouterView only)

```swift
// Select a tab
router.selectTab(AppTab.home)

// Switch to a tab and optionally reset its navigation stack
router.switchTab(AppTab.profile, resetStack: true)
```

### Properties

```swift
// Current navigation depth
let depth = router.depth

// Check if stack is empty
let isEmpty = router.isEmpty

// Check if modal is presented
let hasModal = router.isModalPresented

// Currently selected tab (TabRouterView only)
let currentTab = router.selectedTab
```

## Key Features

### Independent Navigation Stacks per Tab

Each tab maintains its own navigation stack, so users can navigate independently in each tab without affecting others.

### Type-Safe Routing

All routes conform to the `UIRoute` protocol, ensuring type safety and compile-time checking.

### Shared Modals

Modals (sheets and full-screen covers) are shared across all tabs and displayed on top of the TabView.

### Tab Switching with Stack Reset

```swift
// Switch tab and reset its navigation stack to root
router.switchTab(AppTab.home, resetStack: true)
```

## Usage in Views

Access the router using `@EnvironmentObject`:

```swift
struct MyView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        VStack {
            Button("Navigate") {
                router.push(AppRoute.detail(text: "Hello"))
            }
            
            Button("Switch Tab") {
                router.selectTab(AppTab.profile)
            }
        }
    }
}
```

## Project Structure

Before publishing this package, ensure your files are organized correctly:

```
UIRouter/
├── Package.swift
├── README.md
├── LICENSE
├── .gitignore
├── Sources/
│   └── UIRouter/
│       ├── UIRouter.swift
│       ├── UIRoute.swift
│       ├── RouterView.swift
│       └── TabRouterView.swift
├── Tests/
│   └── UIRouterTests/
│       └── UIRouterTests.swift
└── Examples/
    └── (example files)
```

See [PACKAGE_STRUCTURE.md](PACKAGE_STRUCTURE.md) for detailed organization instructions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[Add your license here]

## Author

Created by Joon Jang

## Resources

- [Package Structure Guide](PACKAGE_STRUCTURE.md) - How to organize files for Swift Package
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [SwiftUI Navigation](https://developer.apple.com/documentation/swiftui/navigation)
