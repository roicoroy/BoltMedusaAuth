//
//  MainTabView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var cartService = CartService()
    
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
            
            CartView()
                .tabItem {
                    Image(systemName: cartService.currentCart?.isEmpty == false ? "cart.fill.badge.plus" : "cart")
                    Text("Cart")
                }
                .badge(cartService.currentCart?.itemCount ?? 0)
                .environmentObject(cartService)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView(authService: AuthService())
}