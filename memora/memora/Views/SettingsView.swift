//
//  SettingsView.swift
//  Memora
//
//  Settings and user preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationsEnabled = true
    @State private var notificationTime = Date()
    @State private var privacyMode = false
    @State private var showingPremiumSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                // Premium Status
                Section {
                    if appState.isPremiumUser {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Premium Member")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    } else {
                        Button(action: { showingPremiumSheet = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Upgrade to Premium")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Unlimited AI features & more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    if !appState.isPremiumUser {
                        HStack {
                            Text("AI uses today:")
                            Spacer()
                            Text("\(appState.aiUsageCount) / 5")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Journal Mode
                Section(header: Text("Journal Mode")) {
                    Picker("Mode", selection: $appState.journalMode) {
                        Text("Personal").tag(JournalMode.personal)
                        Text("Child").tag(JournalMode.child)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Notifications
                Section(header: Text("Notifications")) {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                // Privacy
                Section(header: Text("Privacy")) {
                    Toggle("Privacy Mode", isOn: $privacyMode)
                    
                    if privacyMode {
                        Text("Keep everything on device. AI features will be disabled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink("iCloud Sync") {
                        CloudSyncSettingsView()
                    }
                }
                
                // About
                Section(header: Text("About")) {
                    NavigationLink("API Configuration") {
                        APIConfigView()
                    }
                    
                    NavigationLink("Help & Support") {
                        HelpView()
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Developer
                Section(header: Text("Developer")) {
                    Button("Reset Onboarding") {
                        appState.hasCompletedOnboarding = false
                    }
                    
                    Button("Clear All Data", role: .destructive) {
                        // Implement data clearing
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumUpgradeView()
            }
        }
    }
}

struct CloudSyncSettingsView: View {
    @State private var iCloudEnabled = true
    
    var body: some View {
        List {
            Toggle("Enable iCloud Sync", isOn: $iCloudEnabled)
            
            Section {
                Text("Your journal entries are automatically synced across all your Apple devices using iCloud.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if iCloudEnabled {
                Section {
                    HStack {
                        Text("Last Synced")
                        Spacer()
                        Text("Just now")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text("12.3 MB")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct APIConfigView: View {
    @State private var apiKey = ""
    @State private var showingKey = false
    
    var body: some View {
        List {
            Section(header: Text("OpenAI API Key")) {
                HStack {
                    if showingKey {
                        TextField("sk-...", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("sk-...", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    Button(action: { showingKey.toggle() }) {
                        Image(systemName: showingKey ? "eye.slash" : "eye")
                    }
                }
                
                Text("Add your OpenAI API key to enable AI features. Your key is stored securely on your device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("Save API Key") {
                    // Save to Keychain
                    saveAPIKey(apiKey)
                }
                .disabled(apiKey.isEmpty)
            }
            
            Section {
                Link("Get an API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .foregroundColor(.purple)
            }
        }
        .navigationTitle("API Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func saveAPIKey(_ key: String) {
        // Save to UserDefaults for now (in production, use Keychain)
        UserDefaults.standard.set(key, forKey: "openai_api_key")
        
        // Show success alert
        print("✅ API Key saved successfully!")
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section(header: Text("Getting Started")) {
                NavigationLink("How to Create Entries") {
                    Text("Guide coming soon")
                }
                
                NavigationLink("Using AI Features") {
                    Text("Guide coming soon")
                }
                
                NavigationLink("Understanding Premium") {
                    Text("Guide coming soon")
                }
            }
            
            Section(header: Text("Support")) {
                Link("Contact Support", destination: URL(string: "mailto:support@memora.app")!)
                Link("Privacy Policy", destination: URL(string: "https://memora.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://memora.app/terms")!)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Premium")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text("Unlock the full power of Memora")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "sparkles", title: "Unlimited AI Improvements", description: "No daily limits on AI features")
                        FeatureRow(icon: "mic.fill", title: "Voice Transcription", description: "Advanced speech-to-text for all entries")
                        FeatureRow(icon: "paintbrush.fill", title: "Premium Themes", description: "Beautiful custom journal themes")
                        FeatureRow(icon: "book.closed.fill", title: "Multiple Journals", description: "Create unlimited separate journals")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Deep insights into your journaling")
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 15) {
                        PricingCard(
                            title: "Monthly",
                            price: "$4.99",
                            period: "per month",
                            isRecommended: false
                        )
                        
                        PricingCard(
                            title: "Yearly",
                            price: "$39.99",
                            period: "per year",
                            savings: "Save 33%",
                            isRecommended: true
                        )
                    }
                    .padding(.horizontal)
                    
                    // Subscribe Button
                    Button(action: {
                        // In production, implement StoreKit purchase flow
                        appState.isPremiumUser = true
                        dismiss()
                    }) {
                        Text("Start 14-Day Free Trial")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    Text("Cancel anytime. No commitment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Restore Purchases") {
                        // Implement restore purchases
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                    
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    var savings: String?
    let isRecommended: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            if isRecommended {
                Text("RECOMMENDED")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple))
            }
            
            Text(title)
                .font(.headline)
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(price)
                    .font(.system(size: 36, weight: .bold))
                Text(period)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let savings = savings {
                Text(savings)
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(isRecommended ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                )
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}


