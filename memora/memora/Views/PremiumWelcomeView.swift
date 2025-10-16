import SwiftUI

struct PremiumWelcomeView: View {
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
                        
                        Text("Welcome to Premium!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "sparkles", title: "5 AI Improvements Per Day", description: "Daily refreshed AI features")
                        FeatureRow(icon: "mic.fill", title: "Voice Transcription", description: "Advanced speech-to-text for all entries")
                        FeatureRow(icon: "paintbrush.fill", title: "Premium Themes", description: "Beautiful custom journal themes")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Deep insights into your journaling")
                    }
                    .padding(.horizontal)
                    
                    // Action Button
                    Button(action: {
                        dismiss()
                        // Navigate to NewEntry tab
                        appState.shouldNavigateToNewEntry = true
                    }) {
                        Text("Start Exploring")
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


#Preview {
    PremiumWelcomeView()
        .environmentObject(AppState())
}
