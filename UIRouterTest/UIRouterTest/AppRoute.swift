//
//  AppRoute.swift
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI
import UIRouter

/// App route definition (example)
enum AppRoute: UIRoute {
    case detail(text: String)
    case settings
    case profile(name: String)
    case about
    
    func view() -> AnyView {
        switch self {
        case .detail(let text):
            return AnyView(DetailView(text: text))
        case .settings:
            return AnyView(SettingsView())
        case .profile(let name):
            return AnyView(ProfileView(name: name))
        case .about:
            return AnyView(AboutView())
        }
    }
}

// MARK: - Example Views

struct DetailView: View {
    @EnvironmentObject private var router: UIRouter
    let text: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Detail View")
                .font(.largeTitle)
                .bold()
            
            Text(text)
                .font(.title3)
            
            VStack(spacing: 12) {
                Button("Go to Settings") {
                    router.push(AppRoute.settings)
                }
                
                Button("Show Profile (Sheet)") {
                    router.presentSheet(AppRoute.profile(name: "Joon"))
                }
                
                Button("Pop") {
                    router.pop()
                }
                
                Button("Pop to Root") {
                    router.popToRoot()
                }
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Detail")
    }
}

struct SettingsView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings View")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 12) {
                Button("Show About (Full Screen)") {
                    router.presentFullScreenCover(AppRoute.about)
                }
                
                Button("Pop") {
                    router.pop()
                }
                
                Button("Pop to Root") {
                    router.popToRoot()
                }
            }
            .buttonStyle(.bordered)
            
            Text("Stack Depth: \(router.depth)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Settings")
    }
}

struct ProfileView: View {
    @EnvironmentObject private var router: UIRouter
    let name: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.blue)
                
                Text("Profile: \(name)")
                    .font(.title)
                    .bold()
                
                Button("Go to Settings from Modal") {
                    router.dismissModal()
                    router.push(AppRoute.settings)
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        router.dismissModal()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "info.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.white)
                
                Text("About This App")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
                
                Text("Router Demo App\nVersion 1.0")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                
                Button {
                    router.dismissModal()
                } label: {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundStyle(.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
            }
        }
    }
}
