//
//  DashboardView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var authService: AuthService
    
    var body: some View {
        NavigationView {
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
                .padding(.top, 40)
                
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
                            
                            if let phone = customer.phone {
                                DetailRow(title: "Phone", value: phone)
                            }
                            
                            DetailRow(title: "Account Status", value: customer.hasAccount ? "Active" : "Inactive")
                            DetailRow(title: "Member Since", value: formatDate(customer.createdAt))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
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
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
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