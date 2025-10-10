//
//  NewEntryView.swift
//  Memora
//
//  Entry type selection view
//

import SwiftUI

struct NewEntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingTextEditor = false
    @State private var showingPhotoEditor = false
    @State private var showingVoiceRecorder = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("How would you like to journal?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        EntryTypeCard(
                            icon: "doc.text.fill",
                            title: "Write",
                            description: "Express yourself with words",
                            color: .purple,
                            action: { showingTextEditor = true }
                        )
                        
                        EntryTypeCard(
                            icon: "camera.fill",
                            title: "Photo",
                            description: "Capture a moment with images",
                            color: .blue,
                            action: { showingPhotoEditor = true }
                        )
                        
                        EntryTypeCard(
                            icon: "mic.fill",
                            title: "Voice",
                            description: "Record your thoughts",
                            color: .pink,
                            action: { showingVoiceRecorder = true }
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTextEditor) {
                TextEntryEditorView()
            }
            .sheet(isPresented: $showingPhotoEditor) {
                PhotoEntryEditorView()
            }
            .sheet(isPresented: $showingVoiceRecorder) {
                VoiceEntryRecorderView()
            }
        }
    }
}

struct EntryTypeCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewEntryView()
        .environmentObject(AppState())
}


