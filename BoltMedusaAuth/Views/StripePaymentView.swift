
//
//  StripePaymentView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI
import StripePaymentSheet

struct StripePaymentView: View {
    @EnvironmentObject var cartService: CartService
    @State private var paymentSheet: PaymentSheet?
    @State private var isLoading = false
    @State private var paymentResult: PaymentSheetResult?
    @State private var orderCompleted = false

    var body: some View {
        VStack {
            Text("DEBUG: StripePaymentView body rendered.") // Added debug print
            if orderCompleted {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Thank you for your order!")
                        .font(.title)
                        .padding()
                }
            } else {
                if let paymentSheet = paymentSheet {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: handlePaymentCompletion
                    ) {
                        Text("Pay with Stripe")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Text("Loading Payment...")
                        .onAppear {
                            print("DEBUG: preparePaymentSheet() called from onAppear.") // Added debug print
                            preparePaymentSheet()
                        }
                }

                if let result = paymentResult {
                    switch result {
                    case .failed(let error):
                        Text("Payment failed: \(error.localizedDescription)")
                    case .canceled:
                        Text("Payment canceled.")
                    case .completed:
                        // This case is handled by the completion handler
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Stripe Payment")
    }

    func preparePaymentSheet() {
        print("DEBUG: Inside preparePaymentSheet().") // Added debug print
        guard let clientSecret = cartService.currentCart?.paymentCollection?.paymentSessions?.first?.data?["client_secret"]?.value as? String else {
            print("DEBUG: Client secret not available or not a String.") // Added debug print
            return
        }
        print("DEBUG: Client secret obtained: \(clientSecret.prefix(5))...") // Added debug print (partial for security)

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Bolt Medusa"
        // Add any other customizations here

        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        print("DEBUG: PaymentSheet initialized.") // Added debug print
    }

    func handlePaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
        if case .completed = result {
            cartService.completeCart { success in
                if success {
                    self.orderCompleted = true
                }
            }
        }
    }
}
