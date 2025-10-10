//
//  ContentView.swift
//  memora
//
//  Main navigation structure
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            NewEntryView()
                .tabItem {
                    Label("New Entry", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            BookView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.purple)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
