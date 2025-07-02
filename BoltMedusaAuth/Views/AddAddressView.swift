//
//  AddAddressView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct AddAddressView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var addressName = ""
    @State private var company = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var countryCode = "US"
    @State private var province = ""
    @State private var postalCode = ""
    @State private var phone = ""
    @State private var isDefaultShipping = false
    @State private var isDefaultBilling = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !address1.isEmpty &&
        !city.isEmpty &&
        !countryCode.isEmpty &&
        !postalCode.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "location.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Add New Address")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Address Name (Optional)
                        FormField(
                            title: "Address Name",
                            placeholder: "Home, Work, etc. (Optional)",
                            text: $addressName
                        )
                        
                        // Company (Optional)
                        FormField(
                            title: "Company",
                            placeholder: "Company name (Optional)",
                            text: $company
                        )
                        
                        // First Name (Required)
                        FormField(
                            title: "First Name *",
                            placeholder: "Enter first name",
                            text: $firstName
                        )
                        
                        // Last Name (Required)
                        FormField(
                            title: "Last Name *",
                            placeholder: "Enter last name",
                            text: $lastName
                        )
                        
                        // Address Line 1 (Required)
                        FormField(
                            title: "Address Line 1 *",
                            placeholder: "Street address",
                            text: $address1
                        )
                        
                        // Address Line 2 (Optional)
                        FormField(
                            title: "Address Line 2",
                            placeholder: "Apartment, suite, etc. (Optional)",
                            text: $address2
                        )
                        
                        // City (Required)
                        FormField(
                            title: "City *",
                            placeholder: "Enter city",
                            text: $city
                        )
                        
                        // Country Code (Required)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Country *")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Country", selection: $countryCode) {
                                Text("United States").tag("US")
                                Text("Canada").tag("CA")
                                Text("United Kingdom").tag("GB")
                                Text("Germany").tag("DE")
                                Text("France").tag("FR")
                                Text("Spain").tag("ES")
                                Text("Italy").tag("IT")
                                Text("Australia").tag("AU")
                                Text("Japan").tag("JP")
                                Text("Brazil").tag("BR")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Province/State (Optional)
                        FormField(
                            title: "State/Province",
                            placeholder: "Enter state or province (Optional)",
                            text: $province
                        )
                        
                        // Postal Code (Required)
                        FormField(
                            title: "Postal Code *",
                            placeholder: "Enter postal/zip code",
                            text: $postalCode
                        )
                        
                        // Phone (Optional)
                        FormField(
                            title: "Phone",
                            placeholder: "Phone number (Optional)",
                            text: $phone,
                            keyboardType: .phonePad
                        )
                        
                        // Default Address Options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Default Address Options")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Button(action: {
                                        isDefaultShipping.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: isDefaultShipping ? "checkmark.square.fill" : "square")
                                                .foregroundColor(isDefaultShipping ? .blue : .gray)
                                            
                                            Text("Set as default shipping address")
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                                
                                HStack {
                                    Button(action: {
                                        isDefaultBilling.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: isDefaultBilling ? "checkmark.square.fill" : "square")
                                                .foregroundColor(isDefaultBilling ? .blue : .gray)
                                            
                                            Text("Set as default billing address")
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Add Address button
                    Button(action: {
                        addAddress()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Add Address")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("New Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func addAddress() {
        isLoading = true
        errorMessage = nil
        
        authService.addAddress(
            addressName: addressName.isEmpty ? nil : addressName,
            company: company.isEmpty ? nil : company,
            firstName: firstName,
            lastName: lastName,
            address1: address1,
            address2: address2.isEmpty ? nil : address2,
            city: city,
            countryCode: countryCode,
            province: province.isEmpty ? nil : province,
            postalCode: postalCode,
            phone: phone.isEmpty ? nil : phone,
            isDefaultShipping: isDefaultShipping,
            isDefaultBilling: isDefaultBilling
        ) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    self.errorMessage = error ?? "Failed to add address"
                }
            }
        }
    }
}

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .disableAutocorrection(keyboardType == .emailAddress)
        }
    }
}

#Preview {
    AddAddressView()
        .environmentObject(AuthService())
}