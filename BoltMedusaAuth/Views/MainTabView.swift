//
//  MainTabView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var cartService = CartServiceReview()
    @StateObject private var regionService = RegionService()
    
    var body: some View {
        TabView {
            DashboardView()
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

            ProductCategoriesView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("Categories")
                }

            ProductCollectionsView()
                .tabItem {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("Collections")
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
            
            DebugView()
                .tabItem {
                    Image(systemName: "ladybug")
                    Text("Debug")
                }
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
                cartService.createCartIfNeeded(regionId: newCountry.regionId) { success in
                    // Handle success/failure if needed, but no print statements
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            // When authentication status changes, handle cart association
            if isAuthenticated {
                // Cart service will automatically associate cart when user logs in
            } else {
                // Cart service will handle logout cleanup
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}
