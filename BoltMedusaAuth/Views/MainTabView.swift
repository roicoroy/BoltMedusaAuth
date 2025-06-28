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
    @StateObject private var regionService = RegionService()
    
    var body: some View {
        TabView {
            DashboardView(authService: authService)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
            
            ProductsView()
                .environmentObject(regionService)
                .environmentObject(cartService)
                .environmentObject(authService)
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
                .environmentObject(regionService)
                .environmentObject(authService)
        }
        .accentColor(.blue)
        .onAppear {
            // Set up service references for cross-communication
            authService.setCartService(cartService)
            cartService.setAuthService(authService)
            
            // Initialize cart when app starts if region is available
            if regionService.hasSelectedRegion, cartService.currentCart == nil {
                if let regionId = regionService.selectedRegionId {
                    cartService.createCartIfNeeded(regionId: regionId)
                }
            }
        }
        .onChange(of: regionService.selectedCountry) { newCountry in
            // When region changes, update or create cart for that region
            if let newCountry = newCountry {
                print("🌍 Country changed globally to: \(newCountry.label) (\(newCountry.currencyCode))")
                cartService.createCartIfNeeded(regionId: newCountry.regionId) { success in
                    if success {
                        print("✅ Cart updated/created for new country successfully")
                    } else {
                        print("❌ Failed to update/create cart for new country")
                    }
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            // When authentication status changes, handle cart association
            if isAuthenticated {
                print("👤 User logged in, cart service will handle association")
                // Cart service will automatically associate cart when user logs in
            } else {
                print("👤 User logged out, cart service will handle cleanup")
                // Cart service will handle logout cleanup
            }
        }
    }
}

#Preview {
    MainTabView(authService: AuthService())
}