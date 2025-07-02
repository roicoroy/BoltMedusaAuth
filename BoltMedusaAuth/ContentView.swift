//
//  ContentView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}

