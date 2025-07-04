//
//  ProductsView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct ProductsView: View {
    @StateObject private var productService = ProductService()
    @EnvironmentObject var regionService: RegionService
    @EnvironmentObject var cartService: CartServiceReview
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    
    @State private var showingCountrySelector = false
    
    private var filteredProducts: [ProductWithPrice] {
        if searchText.isEmpty {
            return productService.productsWithPrice
        } else {
            return productService.productsWithPrice.filter { product in
                product.title.localizedCaseInsensitiveContains(searchText) ||
                (product.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Country Selector Header
                SharedCountryHeaderView(
                    regionService: regionService,
                    showingCountrySelector: $showingCountrySelector,
                    title: "Shopping Country"
                )
                
                // Search Bar
                SearchBarView(searchText: $searchText)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                // Products Grid
                if productService.isLoading {
                    LoadingProductsView()
                } else if filteredProducts.isEmpty {
                    EmptyProductsView(
                        searchText: searchText,
                        onClearSearch: { searchText = "" }
                    )
                } else {
                    ProductsGridView(
                        products: filteredProducts,
                        regionService: regionService
                    )
                }
                
                // Error messages
                ErrorMessagesView(
                    productService: productService,
                    regionService: regionService
                )
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                if let selectedCountry = regionService.selectedCountry {
                    productService.fetchProductsWithPrice(regionId: selectedCountry.regionId)
                }
                regionService.refreshRegions()
            }
        }
        
        
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty && newValue.count > 2 {
                // Debounce search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue, let regionId = regionService.selectedCountry?.regionId {
                        productService.searchProducts(query: newValue, regionId: regionId)
                    }
                }
            } else if newValue.isEmpty {
                productService.fetchProducts()
            }
        }
        .onChange(of: regionService.selectedCountry) { newCountry in
            if let newCountry = newCountry {
                productService.fetchProductsWithPrice(regionId: newCountry.regionId)
            }
        }
        .onAppear {
            if let selectedCountry = regionService.selectedCountry {
                productService.fetchProductsWithPrice(regionId: selectedCountry.regionId)
            }
        }
        .sheet(isPresented: $showingCountrySelector) {
            NavigationView {
                SharedCountrySelectorView(regionService: regionService)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Shared Components

struct SharedCountryHeaderView: View {
    @ObservedObject var regionService: RegionService
    @Binding var showingCountrySelector: Bool
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingCountrySelector = true
                    }) {
                        HStack {
                            if let selectedCountry = regionService.selectedCountry {
                                Text(selectedCountry.flagEmoji)
                                Text(selectedCountry.label)
                                    .fontWeight(.medium)
                                Text("(\(selectedCountry.formattedCurrency))")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select Country")
                                    .foregroundColor(.blue)
                            }
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                if regionService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct SharedCountrySelectorView: View {
    @ObservedObject var regionService: RegionService
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    private var filteredCountries: [CountrySelection] {
        if searchText.isEmpty {
            return regionService.countryList
        } else {
            return regionService.countryList.filter { country in
                country.label.localizedCaseInsensitiveContains(searchText) ||
                country.country.localizedCaseInsensitiveContains(searchText) ||
                country.formattedCurrency.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBarView(searchText: $searchText)
                .padding()
            
            if regionService.isLoading {
                LoadingCountriesView()
            } else if filteredCountries.isEmpty {
                EmptyCountriesView(
                    searchText: searchText,
                    onClearSearch: { searchText = "" },
                    onRetry: { regionService.refreshRegions() }
                )
            } else {
                List {
                    ForEach(filteredCountries) { country in
                        CountryRowView(
                            country: country,
                            isSelected: regionService.selectedCountry?.id == country.id
                        ) {
                            regionService.selectCountry(country)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            
            if let errorMessage = regionService.errorMessage {
                ErrorBannerView(
                    message: errorMessage,
                    onRetry: { regionService.refreshRegions() }
                )
            }
        }
        .navigationTitle("Select Country")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct CountryRowView: View {
    let country: CountrySelection
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(country.flagEmoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(country.label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(country.formattedCurrency)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(country.country.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct LoadingProductsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading products...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingCountriesView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading countries...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyProductsView: View {
    let searchText: String
    let onClearSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.box")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No products found")
                .font(.title2)
                .fontWeight(.medium)
            
            if !searchText.isEmpty {
                Text("Try adjusting your search")
                    .foregroundColor(.secondary)
                
                Button("Clear Search", action: onClearSearch)
                    .foregroundColor(.blue)
            } else {
                Text("No products available")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyCountriesView: View {
    let searchText: String
    let onClearSearch: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No countries available")
                .font(.title2)
                .fontWeight(.medium)
            
            if !searchText.isEmpty {
                Text("Try adjusting your search")
                    .foregroundColor(.secondary)
                
                Button("Clear Search", action: onClearSearch)
                    .foregroundColor(.blue)
            } else {
                Button("Retry", action: onRetry)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProductsGridView: View {
    let products: [ProductWithPrice]
    @ObservedObject var regionService: RegionService
    @EnvironmentObject var cartService: CartServiceReview

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 16) {
                ForEach(products) { product in
                    NavigationLink(destination: ProductDetailView(product: product, regionService: regionService).environmentObject(cartService)) {
                        ProductCard(
                            product: product,
                            currencyCode: regionService.selectedCountry?.currencyCode ?? "USD"
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct ErrorMessagesView: View {
    @ObservedObject var productService: ProductService
    @ObservedObject var regionService: RegionService
    
    var body: some View {
        VStack(spacing: 8) {
            if let errorMessage = productService.errorMessage {
                ErrorBannerView(
                    message: errorMessage,
                    onRetry: {
                        if let regionId = regionService.selectedCountry?.regionId {
                            productService.fetchProductsWithPrice(regionId: regionId)
                        }
                    }
                )
            }
            
            if let errorMessage = regionService.errorMessage {
                ErrorBannerView(
                    message: "Region Error: \(errorMessage)",
                    onRetry: { regionService.refreshRegions() }
                )
            }
        }
    }
}

struct ErrorBannerView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retry", action: onRetry)
                .foregroundColor(.blue)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ProductCard: View {
    let product: ProductWithPrice
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            AsyncImage(url: URL(string: product.thumbnail ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(8)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = product.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if let calculatedPrice = product.variants?.first?.calculatedPrice {
                        Text(formatPrice(calculatedPrice.calculatedAmount, currencyCode: calculatedPrice.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    } else {
                        Text("Price not available")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Assuming isAvailable logic needs to be re-evaluated for ProductWithPrice
                    // For now, removing it or adapting based on new model structure
                    // if !product.isAvailable {
                    //     Text("Contact Us")
                    //         .font(.caption)
                    //         .padding(.horizontal, 6)
                    //         .padding(.vertical, 2)
                    //         .background(Color.orange.opacity(0.2))
                    //         .foregroundColor(.orange)
                    //         .cornerRadius(4)
                    // }
                }
                
                // Status indicator (assuming ProductWithPrice doesn't have status directly)
                // if let status = product.status {
                //     Text(status.rawValue.capitalized)
                //         .font(.caption2)
                //         .padding(.horizontal, 4)
                //         .padding(.vertical, 2)
                //         .background(statusColor(for: status).opacity(0.2))
                //         .foregroundColor(statusColor(for: status))
                //         .cornerRadius(3)
                // }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ProductsView()
        .environmentObject(RegionService())
        .environmentObject(CartServiceReview())
        .environmentObject(AuthService())
}
