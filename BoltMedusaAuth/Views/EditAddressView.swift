//
//  EditAddressView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct EditAddressView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    
    let address: Address
    
    @State private var addressName: String
    @State private var company: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var address1: String
    @State private var address2: String
    @State private var city: String
    @State private var countryCode: String
    @State private var province: String
    @State private var postalCode: String
    @State private var phone: String
    @State private var isDefaultShipping: Bool
    @State private var isDefaultBilling: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false
    
    init(authService: AuthService, address: Address) {
        self.authService = authService
        self.address = address
        
        // Initialize state variables with current address values
        _addressName = State(initialValue: address.addressName ?? "")
        _company = State(initialValue: address.company ?? "")
        _firstName = State(initialValue: address.firstName ?? "")
        _lastName = State(initialValue: address.lastName ?? "")
        _address1 = State(initialValue: address.address1)
        _address2 = State(initialValue: address.address2 ?? "")
        _city = State(initialValue: address.city)
        _countryCode = State(initialValue: address.countryCode)
        _province = State(initialValue: address.province ?? "")
        _postalCode = State(initialValue: address.postalCode)
        _phone = State(initialValue: address.phone ?? "")
        _isDefaultShipping = State(initialValue: address.isDefaultShipping)
        _isDefaultBilling = State(initialValue: address.isDefaultBilling)
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !address1.isEmpty &&
        !city.isEmpty &&
        !countryCode.isEmpty &&
        !postalCode.isEmpty
    }
    
    private var hasChanges: Bool {
        addressName != (address.addressName ?? "") ||
        company != (address.company ?? "") ||
        firstName != (address.firstName ?? "") ||
        lastName != (address.lastName ?? "") ||
        address1 != address.address1 ||
        address2 != (address.address2 ?? "") ||
        city != address.city ||
        countryCode != address.countryCode ||
        province != (address.province ?? "") ||
        postalCode != address.postalCode ||
        phone != (address.phone ?? "") ||
        isDefaultShipping != address.isDefaultShipping ||
        isDefaultBilling != address.isDefaultBilling
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Edit Address")
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
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Update Address button
                        Button(action: {
                            updateAddress()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text("Update Address")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((isFormValid && hasChanges) ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || !hasChanges || isLoading)
                        
                        // Delete Address button
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Address")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Delete Address", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAddress()
            }
        } message: {
            Text("Are you sure you want to delete this address? This action cannot be undone.")
        }
    }
    
    private func updateAddress() {
        isLoading = true
        errorMessage = nil
        
        authService.updateAddress(
            addressId: address.id,
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
                    self.errorMessage = error ?? "Failed to update address"
                }
            }
        }
    }
    
    private func deleteAddress() {
        isLoading = true
        errorMessage = nil
        
        authService.deleteAddress(addressId: address.id) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    self.errorMessage = error ?? "Failed to delete address"
                }
            }
        }
    }
}

#Preview {
    let sampleAddress = Address(
        id: "addr_01",
        addressName: "Home",
        isDefaultShipping: true,
        isDefaultBilling: false,
        customerId: "cus_01",
        company: "Acme Corp",
        firstName: "John",
        lastName: "Doe",
        address1: "123 Main St",
        address2: "Apt 4B",
        city: "New York",
        countryCode: "US",
        province: "NY",
        postalCode: "10001",
        phone: "+1234567890",
        createdAt: "2023-01-01T00:00:00Z",
        updatedAt: "2023-01-01T00:00:00Z"
    )
    
    EditAddressView(authService: AuthService(), address: sampleAddress)
}