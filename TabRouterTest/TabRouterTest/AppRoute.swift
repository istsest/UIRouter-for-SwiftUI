//
//  AppRoute.swift
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI

/// App route definition (example)
enum AppRoute: UIRoute {
    case detail(text: String)
    case settings
    case profile(name: String)
    case about
    case deepModalTest
    case modalLevel(Int)
    
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
        case .deepModalTest:
            return AnyView(DeepModalTestView())
        case .modalLevel(let level):
            return AnyView(ModalLevelView(level: level))
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
                
                Button("Dismiss Modal") {
                    router.dismissModal()
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

// MARK: - Deep Modal Test Views

struct DeepModalTestView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Section
                    VStack(spacing: 8) {
                        Text("Modal Depth: \(router.modalDepth)")
                            .font(.title2)
                            .bold()
                        
                        Text("Deep Modal Test")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Present Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Present Modals")
                            .font(.headline)
                        
                        Button("Present Sheet (Level 1)") {
                            router.presentSheet(AppRoute.modalLevel(1))
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Present FullScreen (Level 1)") {
                            router.presentFullScreenCover(AppRoute.modalLevel(1))
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Present 3 Sheets at Once") {
                            router.presentSheet(AppRoute.modalLevel(1))
                            router.presentSheet(AppRoute.modalLevel(2))
                            router.presentSheet(AppRoute.modalLevel(3))
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Dismiss Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dismiss Modals")
                            .font(.headline)
                        
                        Button("Dismiss All & Present New") {
                            router.dismissAllModals()
                            router.presentSheet(AppRoute.modalLevel(1))
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Deep Modal Test")
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

struct ModalLevelView: View {
    @EnvironmentObject private var router: UIRouter
    let level: Int
    
    private var levelColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .cyan, .mint]
        let normalizedLevel = max(level, 1)
        return colors[(normalizedLevel - 1) % colors.count]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Level Indicator
                    ZStack {
                        Circle()
                            .fill(levelColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        VStack {
                            Text("Level")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(level)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(levelColor)
                        }
                    }
                    
                    // Status
                    VStack(spacing: 4) {
                        Text("Modal Depth: \(router.modalDepth)")
                            .font(.headline)
                        Text("This is modal level \(level)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Present More
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Present More")
                            .font(.headline)
                        
                        Button("Present Next Level (Sheet)") {
                            router.presentSheet(AppRoute.modalLevel(level + 1))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(levelColor)
                        
                        Button("Present Next Level (FullScreen)") {
                            router.presentFullScreenCover(AppRoute.modalLevel(level + 1))
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Dismiss Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dismiss Options")
                            .font(.headline)
                        
                        Button("Dismiss This Modal") {
                            router.dismissModal()
                        }
                        .buttonStyle(.bordered)
                        
                        if router.modalDepth > 1 {
                            Button("Dismiss 2 Modals") {
                                router.dismissModals(2)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Dismiss All Modals") {
                                router.dismissAllModals()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        
                        if level > 1 {
                            Button("Dismiss to Level 1") {
                                router.dismissModalsAfter(AppRoute.modalLevel(1))
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Dismiss & Present
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dismiss & Present")
                            .font(.headline)
                        
                        Button("Dismiss All & Present New") {
                            router.dismissAllModals()
                            router.presentSheet(AppRoute.modalLevel(1))
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Modal Level \(level)")
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
