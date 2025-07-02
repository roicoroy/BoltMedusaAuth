//
//  CompletedOrdersView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI

struct CompletedOrdersView: View {
    @StateObject private var ordersService = OrdersService()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            Group {
                if ordersService.isLoading {
                    ProgressView("Loading orders...")
                } else if let errorMessage = ordersService.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            ordersService.fetchOrders()
                        }
                    }
                } else if ordersService.orders.isEmpty {
                    VStack {
                        Image(systemName: "archivebox")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No completed orders found.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(ordersService.orders) {
                        order in
                        NavigationLink(destination: OrderDetailView(order: order)) {
                            OrderRowView(order: order)
                        }
                    }
                }
            }
            .navigationTitle("Completed Orders")
            .onAppear {
                if ordersService.orders.isEmpty && !ordersService.isLoading {
                    ordersService.fetchOrders()
                }
            }
        }
    }
}

struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order #\(order.id)")
                    .font(.headline)
                Spacer()
                Text(order.formattedTotal)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text("Status: \(order.displayStatus)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let createdAt = order.createdAt {
                Text("Date: \(formatDate(createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let items = order.items, !items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Items:")
                        .font(.caption)
                        .fontWeight(.medium)
                    ForEach(items) {
                        item in
                        Text("- \(item.title) (x\(item.quantity))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    CompletedOrdersView()
}