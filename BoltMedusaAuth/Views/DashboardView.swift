//
//  DashboardView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var authService: AuthService
    @State private var showingAddAddress = false
    @State private var selectedAddress: Address?
    @State private var showingEditAddress = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        if let customer = authService.currentCustomer {
                            Text("Welcome, \(customer.firstName ?? "User")!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(customer.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Customer details card
                    if let customer = authService.currentCustomer {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(title: "Email", value: customer.email)
                                
                                if let firstName = customer.firstName {
                                    DetailRow(title: "First Name", value: firstName)
                                }
                                
                                if let lastName = customer.lastName {
                                    DetailRow(title: "Last Name", value: lastName)
                                }
                                
                                if let companyName = customer.companyName {
                                    DetailRow(title: "Company", value: companyName)
                                }
                                
                                if let phone = customer.phone {
                                    DetailRow(title: "Phone", value: phone)
                                }
                                
                                DetailRow(title: "Member Since", value: formatDate(customer.createdAt))
                                
                                if let addresses = customer.addresses, !addresses.isEmpty {
                                    DetailRow(title: "Addresses", value: "\(addresses.count) address(es)")
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Addresses section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Addresses")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddAddress = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Address")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        if let customer = authService.currentCustomer,
                           let addresses = customer.addresses,
                           !addresses.isEmpty {
                            
                            ForEach(addresses) { address in
                                AddressCard(address: address) {
                                    selectedAddress = address
                                    showingEditAddress = true
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "location.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                
                                Text("No addresses added yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Add your first address to get started")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Logout button
                    Button(action: {
                        authService.logout()
                    }) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Refresh customer data when view appears
                authService.fetchCustomerProfile()
            }
        }
        .sheet(isPresented: $showingAddAddress) {
            AddAddressView(authService: authService)
        }
        .sheet(isPresented: $showingEditAddress) {
            if let address = selectedAddress {
                EditAddressView(authService: authService, address: address)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}


struct AddressCard: View {
    let address: Address
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let addressName = address.addressName {
                        Text(addressName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    } else {
                        Text("Address")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        if address.isDefaultBilling {
                            Text("Billing")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if address.isDefaultShipping {
                            Text("Shipping")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let company = address.company {
                        Text(company)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let firstName = address.firstName, let lastName = address.lastName {
                        Text("\(firstName) \(lastName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(address.address1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let address2 = address.address2 {
                        Text(address2)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(address.city), \(address.province ?? "") \(address.postalCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(address.countryCode.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let phone = address.phone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    let authService = AuthService()
    return DashboardView(authService: authService)
}
