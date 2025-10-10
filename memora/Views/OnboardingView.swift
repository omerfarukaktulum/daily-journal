//
//  OnboardingView.swift
//  Memora
//
//  Onboarding flow with journal mode selection
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                
                FeaturePage(
                    icon: "pencil.and.list.clipboard",
                    title: "Write Your Story",
                    description: "Capture your thoughts through text, voice, or photos. Let AI help you express yourself beautifully."
                )
                .tag(1)
                
                FeaturePage(
                    icon: "sparkles",
                    title: "AI-Powered Reflection",
                    description: "Get intelligent suggestions to improve your writing and gain insights from your memories."
                )
                .tag(2)
                
                FeaturePage(
                    icon: "book.closed.fill",
                    title: "Beautiful Journals",
                    description: "Your entries are organized into stunning book-style pages that you'll love to revisit."
                )
                .tag(3)
                
                JournalModeSelectionPage()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Welcome to Memora")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("Your memories, reimagined by AI")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

struct FeaturePage: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

struct JournalModeSelectionPage: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMode: JournalMode = .personal
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Who is this journal for?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                ModeSelectionCard(
                    icon: "person.fill",
                    title: "Myself",
                    description: "A personal space for your thoughts and reflections",
                    isSelected: selectedMode == .personal,
                    action: { selectedMode = .personal }
                )
                
                ModeSelectionCard(
                    icon: "figure.and.child.holdinghands",
                    title: "My Child",
                    description: "Document precious moments and milestones",
                    isSelected: selectedMode == .child,
                    action: { selectedMode = .child }
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                appState.journalMode = selectedMode
                appState.hasCompletedOnboarding = true
            }) {
                Text("Get Started")
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
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

struct ModeSelectionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.purple : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}


