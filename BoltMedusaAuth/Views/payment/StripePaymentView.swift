
//
//  StripePaymentView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI
import StripePaymentSheet

struct StripePaymentView: View {
    @EnvironmentObject var cartService: CartServiceReview
    @State private var paymentSheet: PaymentSheet?
    @State private var isLoading = false
    @State private var paymentResult: PaymentSheetResult?
    @State private var orderCompleted = false

    var body: some View {
        VStack {
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
        guard let clientSecret = cartService.currentCart?.paymentCollection?.paymentSessions?.first?.data?["client_secret"]?.value as? String else {
            return
        }

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Bolt Medusa"
        // Add any other customizations here

        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
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
