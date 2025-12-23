//
//  TabExampleView.swift
//  Router
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI

// MARK: - Tab Definition

enum AppTab: String, CaseIterable, Hashable {
    case home
    case search
    case favorites
    case profile
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .favorites: return "Favorites"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .favorites: return "heart.fill"
        case .profile: return "person.fill"
        }
    }
    
    var labelView: some View {
        Label(title, systemImage: icon)
    }
    
    @ViewBuilder
    var contentView: some View {
        switch self {
        case .home: HomeTabView()
        case .search: SearchTabView()
        case .favorites: FavoritesTabView()
        case .profile: ProfileTabView()
        }
    }
    
    var routeTabItem: UIRouteTabItem<AppTab> {
        return UIRouteTabItem(tag: self) {
            labelView
        } content: {
            contentView
        }
    }
    
    static var allTabItems: [UIRouteTabItem<AppTab>] {
        return self.allCases.map(\.routeTabItem)
    }
}

// MARK: - Tab Content Views

struct HomeTabView: View {
    @EnvironmentObject private var router: UIRouter
    @EnvironmentObject private var coordinator: TabCoordinator<AppTab>
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Home")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 12) {
                Button("Push to Detail") {
                    router.push(AppRoute.detail(text: "From Home Tab"))
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Settings Sheet") {
                    router.presentSheet(AppRoute.settings)
                }
                .buttonStyle(.bordered)
                
                Button("🧪 Deep Modal Test") {
                    router.presentSheet(AppRoute.deepModalTest)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                
                Button("Switch to Profile Tab") {
                    coordinator.selectTab(.profile)
                }
                .buttonStyle(.bordered)
            }
            
            VStack(spacing: 4) {
                Text("Navigation Stack Depth: \(router.depth)")
                Text("Modal Depth: \(router.modalDepth)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Home")
    }
}

struct SearchTabView: View {
    @EnvironmentObject private var router: UIRouter
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Search")
                .font(.largeTitle)
                .bold()
            
            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
            
            Button("Push to Detail") {
                router.push(AppRoute.detail(text: "Search Result: \(searchText.isEmpty ? "Empty" : searchText)"))
            }
            .buttonStyle(.borderedProminent)
            
            Text("Navigation Stack Depth: \(router.depth)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Search")
    }
}

struct FavoritesTabView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink)
            
            Text("Favorites")
                .font(.largeTitle)
                .bold()
            
            Text("Your favorite items")
                .foregroundStyle(.secondary)
            
            Button("Show Profile") {
                router.presentSheet(AppRoute.profile(name: "Favorite User"))
            }
            .buttonStyle(.borderedProminent)
            
            Text("Navigation Stack Depth: \(router.depth)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Favorites")
    }
}

struct ProfileTabView: View {
    @EnvironmentObject private var router: UIRouter
    @EnvironmentObject private var coordinator: TabCoordinator<AppTab>
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple)
            
            Text("Joon Jang")
                .font(.title)
                .bold()
            
            Text("iOS Developer")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
                .padding(.vertical)
            
            VStack(spacing: 12) {
                Button("View Settings") {
                    router.push(AppRoute.settings)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show About") {
                    router.presentFullScreenCover(AppRoute.about)
                }
                .buttonStyle(.bordered)
                
                Button("Go to Home Tab") {
                    coordinator.selectTab(.home)
                }
                .buttonStyle(.bordered)
            }
            
            Text("Navigation Stack Depth: \(router.depth)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Profile")
    }
}

// MARK: - Tab Router View Container

struct TabExampleView: View {
    var body: some View {
        TabRouterView(tabs: AppTab.allTabItems, initialTab: AppTab.home)
    }
}

#Preview {
    TabExampleView()
}
