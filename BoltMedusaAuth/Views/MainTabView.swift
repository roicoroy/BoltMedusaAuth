//
//  MainTabView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthService
    
    var body: some View {
        TabView {
            DashboardView(authService: authService)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
            
            ProductsView()
                .tabItem {
                    Image(systemName: "cube.box")
                    Text("Products")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView(authService: AuthService())
}