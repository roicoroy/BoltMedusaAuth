//
//  MainTabView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI
import StripeCore

struct MainTabView: View {
    private let networkManager = NetworkManager(baseURL: "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app", publishableKey: "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a")

    @StateObject private var authService: AuthService
    @StateObject private var cartService: CartService
    @StateObject private var regionService = RegionService()
    @StateObject private var productCategoryService: ProductCategoryService
    @StateObject private var productCollectionService: ProductCollectionService
    @StateObject private var productService: ProductService

    init() {
        _authService = StateObject(wrappedValue: AuthService(networkManager: NetworkManager(baseURL: "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app", publishableKey: "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a")))
        _cartService = StateObject(wrappedValue: CartService(networkManager: NetworkManager(baseURL: "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app", publishableKey: "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a")))
        _productCategoryService = StateObject(wrappedValue: ProductCategoryService(networkManager: NetworkManager(baseURL: "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app", publishableKey: "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a")))
        _productCollectionService = StateObject(wrappedValue: ProductCollectionService(networkManager: NetworkManager(baseURL: "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app", publishableKey: "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a")))
        _productService = StateObject(wrappedValue: ProductService(networkManager: NetworkManager(baseURL: "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app", publishableKey: "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a")))
    }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .environmentObject(authService)

            ProductsView()
                .environmentObject(regionService)
                .environmentObject(cartService)
                .environmentObject(authService)
                .environmentObject(productService)
                .tabItem {
                    Image(systemName: "cube.box")
                    Text("Products")
                }

            ProductCategoriesView()
                .environmentObject(productCategoryService)
                .environmentObject(regionService)
                .environmentObject(cartService)
                .environmentObject(authService)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("Categories")
                }

            ProductCollectionsView()
                .environmentObject(productCollectionService)
                .environmentObject(regionService)
                .environmentObject(cartService)
                .environmentObject(authService)
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
            StripeAPI.defaultPublishableKey = "pk_test_51Pzad704q0B7q2wz8zASldczqkHqbIvXsB2DBO20OEkAC9q7RUvoiBcZ9NVOakZMTWtg2vxgcJQN0mUpXtrThg2D00fHtuTwvj"
            authService.setCartService(cartService)
            cartService.setAuthService(authService)
            
            if regionService.hasSelectedRegion, cartService.currentCart == nil {
                if let regionId = regionService.selectedRegionId {
                    cartService.createCartIfNeeded(regionId: regionId)
                }
            }
        }
        .onChange(of: regionService.selectedCountry) { newCountry in
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
            if isAuthenticated {
                print("👤 User logged in, cart service will handle association")
            } else {
                print("👤 User logged out, cart service will handle cleanup")
            }
        }
    }
}

#Preview {
    MainTabView()
}
