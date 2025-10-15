//
//  SettingsView.swift
//  Memora
//
//  Settings and user preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
    @State private var notificationTime = Date()
    @State private var privacyMode = false
    @State private var showingPremiumSheet = false
    
    init() {
        // Load notification time from UserDefaults
        if let savedTime = UserDefaults.standard.object(forKey: "notification_time") as? Date {
            _notificationTime = State(initialValue: savedTime)
        } else {
            // Default to 8 PM
            let calendar = Calendar.current
            let components = DateComponents(hour: 20, minute: 0)
            let defaultTime = calendar.date(from: components) ?? Date()
            _notificationTime = State(initialValue: defaultTime)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Premium Banner
                    if appState.isPremiumUser {
                        premiumBanner
                    } else {
                        upgradeBanner
                    }
                    
                    // Preferences Section
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .purple,
                            title: "Daily Reminders",
                            showToggle: true,
                            isToggled: $notificationsEnabled
                        )
                        .onChange(of: notificationsEnabled) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "notifications_enabled")
                            if newValue {
                                scheduleNotification()
                            }
                        }
                        
                        if notificationsEnabled {
                            Divider()
                                .padding(.leading, 56)
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 32, height: 32)
                                
                                DatePicker(
                                    "Reminder Time",
                                    selection: $notificationTime,
                                    displayedComponents: .hourAndMinute
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .onChange(of: notificationTime) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "notification_time")
                                scheduleNotification()
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        SettingsRow(
                            icon: "lock.shield.fill",
                            iconColor: .green,
                            title: "Privacy Mode",
                            subtitle: privacyMode ? "AI features disabled" : nil,
                            showToggle: true,
                            isToggled: $privacyMode
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // Data & Sync Section
                    VStack(spacing: 0) {
                        NavigationLink(destination: CloudSyncSettingsView()) {
                            SettingsRow(
                                icon: "icloud.fill",
                                iconColor: .blue,
                                title: "iCloud Sync",
                                subtitle: "Sync across devices",
                                showChevron: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // Support & About Section
                    VStack(spacing: 0) {
                        NavigationLink(destination: HelpView()) {
                            SettingsRow(
                                icon: "questionmark.circle.fill",
                                iconColor: .orange,
                                title: "Help & Support",
                                subtitle: "Guides and FAQs",
                                showChevron: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .gray,
                            title: "Version",
                            value: "1.0.0"
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // Developer Section
                    VStack(spacing: 0) {
                        Button(action: {
                            appState.hasCompletedOnboarding = false
                        }) {
                            SettingsRow(
                                icon: "arrow.counterclockwise.circle.fill",
                                iconColor: .purple,
                                title: "Reset Onboarding"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        Button(action: {
                            // Reset AI quota to 5 for testing
                            appState.aiUsageCount = 0
                        }) {
                            SettingsRow(
                                icon: "arrow.clockwise.circle.fill",
                                iconColor: .blue,
                                title: "Reset AI Quota (Testing)",
                                subtitle: "Reset to 5 free uses"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        Button(action: {
                            // Implement data clearing
                        }) {
                            SettingsRow(
                                icon: "trash.circle.fill",
                                iconColor: .red,
                                title: "Clear All Data",
                                titleColor: .red
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumUpgradeView()
            }
        }
    }
    
    // MARK: - Premium Banner
    var premiumBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Premium Member")
                    .font(.headline)
                
                Text("Thank you for your support!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Upgrade Banner
    var upgradeBanner: some View {
        Button(action: { showingPremiumSheet = true }) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Unlimited AI • Advanced features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                
                // AI Usage Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("AI uses today")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(appState.aiUsageCount) / 5")
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (CGFloat(appState.aiUsageCount) / 5.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    func scheduleNotification() {
        // This would integrate with NotificationService
        print("📅 Notification scheduled for \(notificationTime)")
        // In production, call NotificationService to schedule actual notifications
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

struct HelpView: View {
    var body: some View {
        List {
            Section(header: Text("Getting Started")) {
                NavigationLink("How to Create Entries") {
                    HowToCreateEntriesView()
                }
                
                NavigationLink("Using AI Features") {
                    UsingAIFeaturesView()
                }
                
                NavigationLink("Understanding Premium") {
                    UnderstandingPremiumView()
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

struct HowToCreateEntriesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                        
                        Text("How to Create Entries")
                            .font(.title2.bold())
                    }
                    
                    Text("Memora offers three different ways to capture your memories and thoughts.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    GuideCard(
                        icon: "pencil.circle.fill",
                        iconColor: .purple,
                        title: "Write Entry",
                        steps: [
                            "Tap the + button at the bottom of the screen",
                            "Select 'Write' to start a text entry",
                            "Type your thoughts, feelings, or memories",
                            "Add a title (optional) to make it easier to find later",
                            "Select your mood from the emoji picker",
                            "Add tags to organize your entries (e.g., #family, #travel)",
                            "Use 'Improve with AI' to enhance your writing",
                            "Tap 'Save' when you're done"
                        ]
                    )
                    
                    GuideCard(
                        icon: "camera.circle.fill",
                        iconColor: .purple,
                        title: "Photo Entry",
                        steps: [
                            "Tap the + button and select 'Photo'",
                            "Choose photos from your library or take a new one",
                            "You can add up to 10 photos per entry",
                            "Use 'Generate Caption with AI' for automatic descriptions",
                            "Add your own caption or thoughts about the photos",
                            "Include location to remember where it happened",
                            "Add tags and mood to organize your memories",
                            "Swipe through photos in the entry view"
                        ]
                    )
                    
                    GuideCard(
                        icon: "mic.circle.fill",
                        iconColor: .purple,
                        title: "Voice Entry",
                        steps: [
                            "Tap the + button and select 'Voice'",
                            "Grant microphone permission if prompted",
                            "Tap the record button to start recording",
                            "Speak naturally about your day or thoughts",
                            "Tap stop when you're finished",
                            "The app will automatically transcribe your speech",
                            "Edit the transcription if needed",
                            "Use AI to improve and polish the text",
                            "Add mood, tags, and location before saving"
                        ]
                    )
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("💡 Pro Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TipCard(text: "Use tags consistently to easily filter and find entries later")
                    TipCard(text: "The AI features work best when you provide clear, detailed content")
                    TipCard(text: "Add locations to create a map of your memories over time")
                    TipCard(text: "Free users get 5 AI uses per day - Premium users get unlimited")
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UsingAIFeaturesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundColor(.yellow)
                        
                        Text("Using AI Features")
                            .font(.title2.bold())
                    }
                    
                    Text("Memora uses AI to help you write better and capture memories more beautifully.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    GuideCard(
                        icon: "wand.and.stars",
                        iconColor: .purple,
                        title: "Improve with AI (Text & Voice)",
                        steps: [
                            "Write or record your entry as you normally would",
                            "Tap 'Improve with AI' button",
                            "The AI will enhance grammar, clarity, and flow",
                            "Review the improved version",
                            "Choose to keep the improvement or stick with your original",
                            "Each use counts toward your daily limit (free: 5/day)"
                        ]
                    )
                    
                    GuideCard(
                        icon: "photo.badge.plus",
                        iconColor: .purple,
                        title: "Generate Caption with AI (Photos)",
                        steps: [
                            "Add one or more photos to your entry",
                            "Tap 'Generate Caption with AI'",
                            "The AI analyzes your photos and creates a description",
                            "The caption captures what's in the photo and the mood",
                            "Edit the caption to add your personal touch",
                            "Add location and people for more context"
                        ]
                    )
                    
                    GuideCard(
                        icon: "mic.badge.plus",
                        iconColor: .purple,
                        title: "Voice Transcription",
                        steps: [
                            "Record your voice entry",
                            "Advanced AI transcribes your speech to text",
                            "Works in real-time as you speak",
                            "Handles different accents and speaking styles",
                            "Edit transcription to fix any errors",
                            "Then use 'Improve with AI' to polish it further"
                        ]
                    )
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("⚡ AI Usage Limits")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.purple)
                            Text("Free Users")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("5 uses/day")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Premium Users")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("Unlimited")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UnderstandingPremiumView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                        
                        Text("Understanding Premium")
                            .font(.title2.bold())
                    }
                    
                    Text("Unlock the full potential of Memora with Premium features.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Premium Features")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    PremiumFeatureCard(
                        icon: "sparkles",
                        title: "Unlimited AI",
                        description: "Use AI features as many times as you want without daily limits"
                    )
                    
                    PremiumFeatureCard(
                        icon: "mic.fill",
                        title: "Enhanced Voice Transcription",
                        description: "Better accuracy and support for multiple languages"
                    )
                    
                    PremiumFeatureCard(
                        icon: "paintbrush.fill",
                        title: "Premium Themes",
                        description: "Customize your journal with beautiful themes and colors"
                    )
                    
                    PremiumFeatureCard(
                        icon: "book.closed.fill",
                        title: "Multiple Journals",
                        description: "Create separate journals for different aspects of your life"
                    )
                    
                    PremiumFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Advanced Analytics",
                        description: "Insights into your journaling habits and mood trends"
                    )
                    
                    PremiumFeatureCard(
                        icon: "lock.shield.fill",
                        title: "Priority Support",
                        description: "Get help faster with priority customer support"
                    )
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("💰 Pricing")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Monthly Plan")
                                    .font(.subheadline.bold())
                                Text("Cancel anytime")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("$4.99/month")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Yearly Plan")
                                        .font(.subheadline.bold())
                                    Text("SAVE 33%")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.green))
                                }
                                Text("Best value")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("$39.99/year")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("❓ FAQ")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    FAQCard(
                        question: "Can I try Premium before buying?",
                        answer: "Yes! All new Premium subscriptions come with a 14-day free trial."
                    )
                    
                    FAQCard(
                        question: "Can I cancel anytime?",
                        answer: "Absolutely. Cancel anytime from Settings. No questions asked."
                    )
                    
                    FAQCard(
                        question: "What happens to my data if I cancel?",
                        answer: "All your entries remain accessible. You'll just lose Premium features."
                    )
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

struct GuideCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(step)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct TipCard: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct FAQCard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline.bold())
            
            Text(answer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("Unlock the full power of Memora")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Limit Reached Message
                    // VStack(spacing: 12) {
                    //     HStack(spacing: 12) {
                    //         Image(systemName: "exclamationmark.triangle.fill")
                    //             .font(.title2)
                    //             .foregroundColor(.orange)
                            
                    //         VStack(alignment: .leading, spacing: 4) {
                    //             Text("AI Limit Reached")
                    //                 .font(.headline)
                    //                 .foregroundColor(.primary)
                                
                    //             Text(appState.isPremiumUser ? 
                    //                  "You've used all 3 AI improvements for today. Come back tomorrow!" :
                    //                  "You've used all 5 free AI improvements. Upgrade to Premium for 3 AI uses per day!")
                    //                 .font(.subheadline)
                    //                 .foregroundColor(.secondary)
                    //         }
                            
                    //         Spacer()
                    //     }
                    //     .padding()
                    //     .background(
                    //         RoundedRectangle(cornerRadius: 15)
                    //             .fill(Color.orange.opacity(0.1))
                    //             .overlay(
                    //                 RoundedRectangle(cornerRadius: 15)
                    //                     .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    //             )
                    //     )
                    // }
                    // .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "sparkles", title: "3 AI Improvements Per Day", description: "Daily refreshed AI features")
                        FeatureRow(icon: "mic.fill", title: "Voice Transcription", description: "Advanced speech-to-text for all entries")
                        FeatureRow(icon: "paintbrush.fill", title: "Premium Themes", description: "Beautiful custom journal themes")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Deep insights into your journaling")
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 10) {
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

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var titleColor: Color = .primary
    var subtitle: String? = nil
    var value: String? = nil
    var showToggle: Bool = false
    @Binding var isToggled: Bool
    var showChevron: Bool = false
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        titleColor: Color = .primary,
        subtitle: String? = nil,
        value: String? = nil,
        showToggle: Bool = false,
        isToggled: Binding<Bool> = .constant(false),
        showChevron: Bool = false
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.titleColor = titleColor
        self.subtitle = subtitle
        self.value = value
        self.showToggle = showToggle
        self._isToggled = isToggled
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(titleColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Right Side Content
            if showToggle {
                Toggle("", isOn: $isToggled)
                    .labelsHidden()
            } else if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}


