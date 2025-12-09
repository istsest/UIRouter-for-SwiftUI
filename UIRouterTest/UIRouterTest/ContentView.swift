//
//  ContentView.swift
//  UIRouterTest
//
//  Created by Joon Jang on 12/8/25.
//

import SwiftUI
import UIRouter

struct ContentView: View {
    @EnvironmentObject private var router: UIRouter
    
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
            }
            
            Text("Navigation Stack Depth: \(router.depth)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Home")
    }
}

#Preview {
    ContentView()
        .injectRouter()
}
