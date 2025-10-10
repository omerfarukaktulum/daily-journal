//
//  MemoraApp.swift
//  Memora
//
//  AI-Powered Personal & Family Journal
//  "Your memories, reimagined by AI."
//

import SwiftUI

@main
struct MemoraApp: App {
    @StateObject private var dataController = DataController()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(appState)
        }
    }
}


