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
    @EnvironmentObject var appState: AppState
    
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
        .onChange(of: appState.shouldNavigateToJournal) { shouldNavigate in
            if shouldNavigate {
                selectedTab = 2 // Switch to Journal tab
                appState.shouldNavigateToJournal = false // Reset flag
            }
        }
        .onChange(of: appState.shouldNavigateToNewEntry) { shouldNavigate in
            if shouldNavigate {
                selectedTab = 1 // Switch to NewEntry tab
                appState.shouldNavigateToNewEntry = false // Reset flag
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
