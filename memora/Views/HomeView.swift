//
//  HomeView.swift
//  Memora
//
//  Home dashboard with recent entries and quick actions
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.createdAt, ascending: false)],
        predicate: nil,
        animation: .default
    ) var entries: FetchedResults<DiaryEntry>
    
    var recentEntries: [DiaryEntry] {
        Array(entries.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welcome Back")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        
                        Text(greetingMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Stats Card
                    StatsCard(entryCount: entries.count)
                        .padding(.horizontal)
                    
                    // Recent Entries
                    if !recentEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Entries")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            ForEach(recentEntries, id: \.id) { entry in
                                EntryPreviewCard(entry: entry)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        EmptyStateView()
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let mode = appState.journalMode == .child ? "your child's memories" : "your thoughts"
        
        switch hour {
        case 0..<12:
            return "Good morning! Ready to capture \(mode)?"
        case 12..<17:
            return "Good afternoon! How's your day going?"
        default:
            return "Good evening! Time to reflect on your day?"
        }
    }
}

struct StatsCard: View {
    let entryCount: Int
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "doc.text.fill",
                value: "\(entryCount)",
                label: "Entries"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "flame.fill",
                value: "\(calculateStreak())",
                label: "Day Streak"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "heart.fill",
                value: "♥︎",
                label: "Keep Going"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    func calculateStreak() -> Int {
        // Simplified streak calculation - would need actual implementation
        return min(entryCount, 7)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EntryPreviewCard: View {
    let entry: DiaryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconForEntryType(entry.entryType))
                    .foregroundColor(.purple)
                
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if entry.aiImproved {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Text(entry.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    func iconForEntryType(_ type: String) -> String {
        switch type {
        case "text": return "doc.text"
        case "photo": return "photo"
        case "voice": return "mic"
        default: return "doc"
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No entries yet")
                .font(.title2.bold())
            
            Text("Tap the + button below to create your first journal entry")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}


