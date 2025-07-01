//
//  DebugView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import SwiftUI
import Foundation

struct DebugView: View {
    @State private var cartData: String = "No cart data found"
    @State private var customerData: String = "No customer data found"
    @State private var authToken: String = "No auth token found"
    @State private var selectedCountryData: String = "No selected country data found"
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "ladybug")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Debug Information")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Refresh Button
                    Button(action: {
                        loadDebugData()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Data")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Cart Data Section
                    DebugSection(
                        title: "Cart Data (medusa_cart)",
                        icon: "cart",
                        data: cartData,
                        color: .blue
                    )
                    
                    // Customer Data Section
                    DebugSection(
                        title: "Customer Data (customer)",
                        icon: "person.circle",
                        data: customerData,
                        color: .green
                    )
                    
                    // Auth Token Section
                    DebugSection(
                        title: "Auth Token (auth_token)",
                        icon: "key",
                        data: authToken,
                        color: .purple
                    )
                    
                    // Selected Country Section
                    DebugSection(
                        title: "Selected Country (selected_country)",
                        icon: "globe",
                        data: selectedCountryData,
                        color: .orange
                    )
                    
                    // UserDefaults Keys Section
                    UserDefaultsKeysSection()
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadDebugData()
            }
            .onChange(of: refreshTrigger) { _ in
                loadDebugData()
            }
        }
    }
    
    private func loadDebugData() {
        // Load Cart Data
        if let cartDataRaw = UserDefaults.standard.data(forKey: "medusa_cart") {
            if let cart = try? JSONDecoder().decode(Cart.self, from: cartDataRaw) {
                // Successfully decoded - show formatted data
                cartData = formatCartData(cart)
            } else {
                // Failed to decode - show raw JSON
                if let jsonString = String(data: cartDataRaw, encoding: .utf8) {
                    cartData = "Raw JSON (failed to decode as Cart):\n\n\(jsonString)"
                } else {
                    cartData = "Data exists but cannot be converted to string. Size: \(cartDataRaw.count) bytes"
                }
            }
        } else {
            cartData = "No cart data found in UserDefaults"
        }
        
        // Load Customer Data
        if let customerDataRaw = UserDefaults.standard.data(forKey: "customer") {
            if let customer = try? JSONDecoder().decode(Customer.self, from: customerDataRaw) {
                customerData = formatCustomerData(customer)
            } else {
                if let jsonString = String(data: customerDataRaw, encoding: .utf8) {
                    customerData = "Raw JSON (failed to decode as Customer):\n\n\(jsonString)"
                } else {
                    customerData = "Data exists but cannot be converted to string. Size: \(customerDataRaw.count) bytes"
                }
            }
        } else {
            customerData = "No customer data found in UserDefaults"
        }
        
        // Load Auth Token
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            authToken = "Token exists: \(token.prefix(20))...\n\nFull token:\n\(token)"
        } else {
            authToken = "No auth token found in UserDefaults"
        }
        
        // Load Selected Country Data
        if let countryDataRaw = UserDefaults.standard.data(forKey: "selected_country") {
            if let country = try? JSONDecoder().decode(CountrySelection.self, from: countryDataRaw) {
                selectedCountryData = formatCountryData(country)
            } else {
                if let jsonString = String(data: countryDataRaw, encoding: .utf8) {
                    selectedCountryData = "Raw JSON (failed to decode as CountrySelection):\n\n\(jsonString)"
                } else {
                    selectedCountryData = "Data exists but cannot be converted to string. Size: \(countryDataRaw.count) bytes"
                }
            }
        } else {
            selectedCountryData = "No selected country data found in UserDefaults"
        }
    }
    
    private func formatCartData(_ cart: Cart) -> String {
        var output = "CART INFORMATION:\n"
        output += "================\n\n"
        
        output += "Basic Info:\n"
        output += "- ID: \(cart.id)\n"
        output += "- Currency: \(cart.currencyCode)\n"
        output += "- Customer ID: \(cart.customerId ?? "nil")\n"
        output += "- Email: \(cart.email ?? "nil")\n"
        output += "- Region ID: \(cart.regionId ?? "nil")\n"
        output += "- Sales Channel ID: \(cart.salesChannelId ?? "nil")\n\n"
        
        output += "Timestamps:\n"
        output += "- Created: \(cart.createdAt ?? "nil")\n"
        output += "- Updated: \(cart.updatedAt ?? "nil")\n"
        output += "- Completed: \(cart.completedAt ?? "nil")\n\n"
        
        output += "Pricing (in cents):\n"
        output += "- Total: \(cart.total)\n"
        output += "- Subtotal: \(cart.subtotal)\n"
        output += "- Tax Total: \(cart.taxTotal)\n"
        output += "- Shipping Total: \(cart.shippingTotal) ⭐\n"
        output += "- Discount Total: \(cart.discountTotal)\n"
        output += "- Item Total: \(cart.itemTotal)\n\n"
        
        output += "Formatted Prices:\n"
        output += "- Total: \(cart.formattedTotal) ⭐\n"
        output += "- Subtotal: \(cart.formattedSubtotal)\n"
        output += "- Tax: \(cart.formattedTaxTotal)\n"
        output += "- Shipping: \(cart.formattedShippingTotal) ⭐\n"
        output += "- Discount: \(cart.formattedDiscountTotal)\n\n"
        
        output += "Items (\(cart.items?.count ?? 0)):\n"
        if let items = cart.items {
            for (index, item) in items.enumerated() {
                output += "  \(index + 1). \(item.title)\n"
                output += "     - ID: \(item.id)\n"
                output += "     - Variant ID: \(item.variantId)\n"
                output += "     - Product ID: \(item.productId)\n"
                output += "     - Quantity: \(item.quantity)\n"
                output += "     - Unit Price: \(item.unitPrice) (\(item.formattedUnitPrice))\n"
                output += "     - Total: \(item.calculatedTotal) (\(item.formattedTotal))\n"
                output += "     - SKU: \(item.variantSku ?? "nil")\n"
                output += "     - Thumbnail: \(item.thumbnail ?? "nil")\n\n"
            }
        } else {
            output += "  No items\n\n"
        }
        
        output += "Addresses:\n"
        if let shippingAddress = cart.shippingAddress {
            output += "  Shipping Address:\n"
            output += "    - Name: \(shippingAddress.fullName)\n"
            output += "    - Address: \(shippingAddress.singleLineAddress)\n"
            output += "    - Phone: \(shippingAddress.phone ?? "nil")\n\n"
        } else {
            output += "  No shipping address\n\n"
        }
        
        if let billingAddress = cart.billingAddress {
            output += "  Billing Address:\n"
            output += "    - Name: \(billingAddress.fullName)\n"
            output += "    - Address: \(billingAddress.singleLineAddress)\n"
            output += "    - Phone: \(billingAddress.phone ?? "nil")\n\n"
        } else {
            output += "  No billing address\n\n"
        }
        
        output += "Status Flags:\n"
        output += "- Is Empty: \(cart.isEmpty)\n"
        output += "- Has Customer: \(cart.isAssociatedWithCustomer)\n"
        output += "- Has Shipping Address: \(cart.hasShippingAddress)\n"
        output += "- Has Billing Address: \(cart.hasBillingAddress)\n"
        output += "- Ready for Checkout: \(cart.isReadyForCheckout)\n\n"
        
        output += "SHIPPING METHOD STATUS:\n"
        output += "======================\n"
        output += "- Shipping Total > 0: \(cart.shippingTotal > 0 ? "YES ✅" : "NO ❌")\n"
        output += "- Shipping Amount: \(cart.shippingTotal) cents\n"
        output += "- Formatted Shipping: \(cart.formattedShippingTotal)\n"
        if cart.shippingTotal > 0 {
            output += "- Status: Shipping method has been added to cart ✅\n"
        } else {
            output += "- Status: No shipping method selected ⚠️\n"
        }
        
        return output
    }
    
    private func formatCustomerData(_ customer: Customer) -> String {
        var output = "CUSTOMER INFORMATION:\n"
        output += "====================\n\n"
        
        output += "Basic Info:\n"
        output += "- ID: \(customer.id)\n"
        output += "- Email: \(customer.email)\n"
        output += "- First Name: \(customer.firstName ?? "nil")\n"
        output += "- Last Name: \(customer.lastName ?? "nil")\n"
        output += "- Company: \(customer.companyName ?? "nil")\n"
        output += "- Phone: \(customer.phone ?? "nil")\n\n"
        
        output += "Default Addresses:\n"
        output += "- Default Billing: \(customer.defaultBillingAddressId ?? "nil")\n"
        output += "- Default Shipping: \(customer.defaultShippingAddressId ?? "nil")\n\n"
        
        output += "Timestamps:\n"
        output += "- Created: \(customer.createdAt)\n"
        output += "- Updated: \(customer.updatedAt)\n"
        output += "- Deleted: \(customer.deletedAt ?? "nil")\n\n"
        
        output += "Addresses (\(customer.addresses?.count ?? 0)):\n"
        if let addresses = customer.addresses {
            for (index, address) in addresses.enumerated() {
                output += "  \(index + 1). \(address.addressName ?? "Unnamed Address")\n"
                output += "     - ID: \(address.id)\n"
                output += "     - Name: \(address.firstName ?? "") \(address.lastName ?? "")\n"
                output += "     - Company: \(address.company ?? "nil")\n"
                output += "     - Address: \(address.address1)\n"
                if let address2 = address.address2 {
                    output += "     - Address 2: \(address2)\n"
                }
                output += "     - City: \(address.city)\n"
                output += "     - Province: \(address.province ?? "nil")\n"
                output += "     - Postal Code: \(address.postalCode)\n"
                output += "     - Country: \(address.countryCode)\n"
                output += "     - Phone: \(address.phone ?? "nil")\n"
                output += "     - Default Shipping: \(address.isDefaultShipping)\n"
                output += "     - Default Billing: \(address.isDefaultBilling)\n\n"
            }
        } else {
            output += "  No addresses\n"
        }
        
        return output
    }
    
    private func formatCountryData(_ country: CountrySelection) -> String {
        var output = "SELECTED COUNTRY:\n"
        output += "================\n\n"
        
        output += "- Country Code: \(country.country)\n"
        output += "- Label: \(country.label)\n"
        output += "- Currency Code: \(country.currencyCode)\n"
        output += "- Region ID: \(country.regionId)\n"
        output += "- Flag Emoji: \(country.flagEmoji)\n"
        output += "- Formatted Currency: \(country.formattedCurrency)\n"
        output += "- Display Text: \(country.displayText)\n"
        
        return output
    }
}

struct DebugSection: View {
    let title: String
    let icon: String
    let data: String
    let color: Color
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(color.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ScrollView {
                    Text(data)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal)
    }
}

struct UserDefaultsKeysSection: View {
    @State private var allKeys: [String] = []
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                    if isExpanded {
                        loadAllKeys()
                    }
                }
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.gray)
                        .font(.title2)
                    
                    Text("All UserDefaults Keys")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(allKeys, id: \.self) { key in
                            HStack {
                                Text("• \(key)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if let value = UserDefaults.standard.object(forKey: key) {
                                    Text("\(type(of: value))")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(.horizontal)
    }
    
    private func loadAllKeys() {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        allKeys = Array(dictionary.keys).sorted()
    }
}

#Preview {
    DebugView()
}
