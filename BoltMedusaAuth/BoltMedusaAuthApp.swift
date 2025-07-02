//
//  BoltMedusaAuthApp.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI
import SwiftData
import Stripe

@main
struct BoltMedusaAuthApp: App {
    @StateObject private var authService = AuthService()

    init() {
        // Configure Stripe with your publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51Pzad704q0B7q2wz8zASldczqkHqbIvXsB2DBO20OEkAC9q7RUvoiBcZ9NVOakZMTWtg2vxgcJQN0mUpXtrThg2D00fHtuTwvj"
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
        .modelContainer(sharedModelContainer)
    }
}
