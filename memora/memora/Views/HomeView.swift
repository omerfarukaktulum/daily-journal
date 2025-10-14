//
//  HomeView.swift
//  Memora
//
//  Home dashboard with insights and quick actions
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
    
    @State private var showingNewEntry = false
    @State private var selectedQuickAction: QuickActionType? = nil
    
    var thisWeekEntries: [DiaryEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.createdAt >= weekAgo }
    }
    
    var memoriesFromThisDay: [DiaryEntry] {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.month, .day], from: today)
        
        return entries.filter { entry in
            let entryComponents = calendar.dateComponents([.month, .day], from: entry.createdAt)
            return entryComponents.month == todayComponents.month &&
                   entryComponents.day == todayComponents.day &&
                   !calendar.isDate(entry.createdAt, inSameDayAs: today)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Personalized Header
                    headerSection
                    
                    // Quick Stats Overview
                    statsOverviewSection
                        .padding(.horizontal)
                    
                    // Quick Actions
                    quickActionsSection
                                .padding(.horizontal)
                            
                    // Activity This Week
                    if !thisWeekEntries.isEmpty {
                        activityThisWeekSection
                    }
                    
                    // Memories from This Day
                    if !memoriesFromThisDay.isEmpty {
                        memoriesSection
                    }
                    
                    // Motivational Prompt
                    if entries.isEmpty {
                        EmptyStateView()
                            .padding(.horizontal)
                    } else {
                        motivationalPromptSection
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedQuickAction) { action in
                quickActionSheet(for: action)
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(greetingTitle)
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            Text(greetingMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var greetingMessage: String {
        if entries.isEmpty {
            return "Start your journaling journey today!"
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let mode = appState.journalMode == .child ? "your child's precious moments" : "your thoughts and feelings"
        
        switch hour {
        case 0..<12:
            return "Ready to capture \(mode)?"
        case 12..<17:
            return "Take a moment to reflect on your day"
        default:
            return "How was your day? Let's journal about it"
        }
    }
    
    // MARK: - Stats Overview Section
    var statsOverviewSection: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "doc.text.fill",
                value: "\(entries.count)",
                label: "Entries",
                color: .purple
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "flame.fill",
                value: "\(calculateStreak())",
                label: "Day Streak",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "sparkles",
                value: "\(aiImprovedCount)",
                label: "AI Enhanced",
                color: .yellow
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Quick Actions Section
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title3.bold())
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "pencil.circle.fill",
                    title: "Write",
                    color: .purple
                ) {
                    selectedQuickAction = .write
                }
                
                QuickActionButton(
                    icon: "camera.circle.fill",
                    title: "Photo",
                    color: .orange
                ) {
                    selectedQuickAction = .photo
                }
                
                QuickActionButton(
                    icon: "mic.circle.fill",
                    title: "Voice",
                    color: .pink
                ) {
                    selectedQuickAction = .voice
                }
            }
        }
    }
    
    // MARK: - Activity This Week Section
    var activityThisWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week's Activity")
                    .font(.title3.bold())
                    .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(destination: BookView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .padding(.horizontal)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(getLast7Days(), id: \.self) { date in
                        DayActivityCard(
                            date: date,
                            entryCount: entriesCount(for: date),
                            isToday: Calendar.current.isDateInToday(date)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Memories Section
    var memoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.purple)
                Text("On This Day")
                    .font(.title3.bold())
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(memoriesFromThisDay.prefix(5), id: \.id) { entry in
                        NavigationLink(destination: EntryDetailView(entry: entry, onDelete: {
                            // Handle deletion from home view
                            // The entry will be deleted from Core Data
                            // and the home view will refresh automatically
                        })) {
                            MemoryCard(entry: entry)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Motivational Prompt Section
    var motivationalPromptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Today's Prompt")
                    .font(.headline)
            }
            
            Text(dailyPrompt)
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
            
            Button(action: {
                selectedQuickAction = .write
            }) {
                Text("Start Writing")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    var dailyPrompt: String {
        let prompts = [
            "What made you smile today?",
            "Describe a moment that brought you peace",
            "What are you grateful for right now?",
            "What's something new you learned today?",
            "Who made a positive impact on your day?",
            "What challenge did you overcome recently?",
            "Describe your perfect day",
            "What's a goal you're working towards?",
            "Write about a favorite childhood memory",
            "What does happiness mean to you today?"
        ]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return prompts[dayOfYear % prompts.count]
    }
    
    // MARK: - Helper Functions
    func calculateStreak() -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.createdAt)
            
            if calendar.isDate(entryDate, inSameDayAs: currentDate) ||
               calendar.isDate(entryDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                if !calendar.isDate(entryDate, inSameDayAs: currentDate) {
                    streak += 1
                    currentDate = entryDate
                }
            } else {
                break
            }
        }
        
        // Check if there's an entry today
        if sortedEntries.first.map({ calendar.isDateInToday($0.createdAt) }) == true {
            streak += 1
        }
        
        return streak
    }
    
    var aiImprovedCount: Int {
        entries.filter { $0.aiImproved }.count
    }
    
    func getLast7Days() -> [Date] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: Date())
        }
    }
    
    func entriesCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }.count
    }
    
    func quickActionSheet(for action: QuickActionType) -> some View {
        Group {
            switch action {
            case .write:
                TextEntryEditorView()
            case .photo:
                PhotoEntryEditorView()
            case .voice:
                VoiceEntryRecorderView()
            }
        }
    }
}

// MARK: - Quick Action Type
enum QuickActionType: Identifiable {
    case write, photo, voice
    
    var id: String {
        switch self {
        case .write: return "write"
        case .photo: return "photo"
        case .voice: return "voice"
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .purple
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayActivityCard: View {
    let date: Date
    let entryCount: Int
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayOfWeek)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 50, height: 50)
                
                if entryCount > 0 {
                    Text("\(entryCount)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("\(dayNumber)")
                .font(.caption2.bold())
                .foregroundColor(isToday ? .purple : .primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isToday ? Color.purple.opacity(0.1) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var circleColor: Color {
        if entryCount == 0 {
            return Color.gray.opacity(0.2)
        } else if entryCount == 1 {
            return Color.blue.opacity(0.7)
        } else if entryCount == 2 {
            return Color.purple.opacity(0.8)
        } else {
            return Color.purple
        }
    }
}

struct MemoryCard: View {
    let entry: DiaryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Text(yearAgo)
                    .font(.caption.bold())
                    .foregroundColor(.purple)
            }
            
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }
            
            Text(entry.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if let mood = entry.mood, !mood.isEmpty {
                Text(mood)
                    .font(.caption)
            }
        }
        .padding()
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
    }
    
    var yearAgo: String {
        let calendar = Calendar.current
        let years = calendar.dateComponents([.year], from: entry.createdAt, to: Date()).year ?? 0
        if years == 1 {
            return "1 year ago"
        } else {
            return "\(years) years ago"
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
            }
            
            Text("Start Your Journey")
                .font(.title2.bold())
            
            Text("Your journal is empty. Tap the + button below to create your first entry and begin capturing your memories.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// We need to reference BookView and EntryDetailView, which are defined elsewhere
// These should already be imported through the project

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}


