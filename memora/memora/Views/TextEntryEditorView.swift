//
//  TextEntryEditorView.swift
//  Memora
//
//  Text-based journal entry editor with AI improvements
//

import SwiftUI
import CoreData
import CoreLocation
import MapKit

struct TextEntryEditorView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.createdAt, ascending: false)],
        animation: .default
    ) var existingEntries: FetchedResults<DiaryEntry>
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var location: String = ""
    @State private var isFetchingLocation = false
    @State private var showingLocationSuggestions = false
    
    @StateObject private var locationSearch = LocationSearchService()
    @State private var showingAIImprovement = false
    @State private var aiSuggestions: [String] = []
    @State private var isLoadingAI = false
    @State private var showingAILimitAlert = false
    
    @StateObject private var aiService = AIService()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Give your entry a title...", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .font(.headline)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Thoughts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // AI Improve Button
                    if !content.isEmpty {
                        Button(action: improveWithAI) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(isLoadingAI ? "Improving..." : "Improve with AI")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoadingAI)
                    }
                    
                    // Mood Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["😊 Happy", "😌 Calm", "😢 Sad", "😰 Anxious", "😴 Tired", "🎉 Excited"], id: \.self) { moodOption in
                                    MoodChip(
                                        label: moodOption,
                                        isSelected: mood == moodOption,
                                        action: { mood = moodOption }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Location (Optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: fetchCurrentLocation) {
                                HStack(spacing: 4) {
                                    Image(systemName: isFetchingLocation ? "arrow.clockwise" : "location.fill")
                                    Text(isFetchingLocation ? "Getting..." : "Use Current")
                                }
                                .font(.caption)
                                .foregroundColor(.purple)
                            }
                            .disabled(isFetchingLocation)
                        }
                        
                        TextField("Where are you?", text: $locationSearch.searchQuery)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: locationSearch.searchQuery) { oldValue, newValue in
                                location = newValue
                                showingLocationSuggestions = !newValue.isEmpty && !locationSearch.suggestions.isEmpty
                            }
                        
                        // Location suggestions
                        if showingLocationSuggestions && !locationSearch.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locationSearch.suggestions.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        location = suggestion
                                        locationSearch.searchQuery = suggestion
                                        showingLocationSuggestions = false
                                    }) {
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color(.systemGray6))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if suggestion != locationSearch.suggestions.prefix(5).last {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                TagChip(text: tag) {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Add a tag...", text: $newTag)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    if !newTag.isEmpty && !tags.contains(newTag) {
                                        tags.append(newTag)
                                        newTag = ""
                                    }
                                }
                            
                            Button(action: {
                                if !newTag.isEmpty && !tags.contains(newTag) {
                                    tags.append(newTag)
                                    newTag = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                            }
                            .disabled(newTag.isEmpty)
                        }
                        
                        // Tag Suggestions
                        if !suggestedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggested")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(suggestedTags, id: \.self) { tag in
                                        SuggestedTagChip(text: tag, isAdded: tags.contains(tag)) {
                                            if tags.contains(tag) {
                                                tags.removeAll { $0 == tag }
                                            } else {
                                                tags.append(tag)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .sheet(isPresented: $showingAIImprovement) {
                AIImprovementSheet(suggestions: aiSuggestions) { selectedVersion in
                    content = selectedVersion
                    showingAIImprovement = false
                }
            }
            .alert("AI Limit Reached", isPresented: $showingAILimitAlert) {
                Button("OK", role: .cancel) { }
                Button("Upgrade to Premium") {
                    // Navigate to premium subscription
                }
            } message: {
                Text("You've used all 5 free AI improvements for today. Upgrade to Premium for unlimited AI features!")
            }
        }
    }
    
    var suggestedTags: [String] {
        var tagCounts: [String: Int] = [:]
        
        for entry in existingEntries {
            if let entryTags = entry.tagsArray {
                for tag in entryTags {
                    tagCounts[tag, default: 0] += 1
                }
            }
        }
        
        // Return top 5 most used tags that aren't already added
        return tagCounts
            .sorted { $0.value > $1.value }
            .map { $0.key }
            .filter { !tags.contains($0) }
            .prefix(5)
            .map { $0 }
    }
    
    func fetchCurrentLocation() {
        isFetchingLocation = true
        locationManager.requestLocation()
        
        let timeout: TimeInterval = isSimulator() ? 5.0 : 2.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if let locationString = locationManager.locationString {
                location = locationString
                locationSearch.searchQuery = locationString
            } else {
                #if targetEnvironment(simulator)
                let message = "Set location in: Features → Location → Custom..."
                location = message
                locationSearch.searchQuery = message
                #else
                location = "Unable to get location"
                locationSearch.searchQuery = "Unable to get location"
                #endif
            }
            isFetchingLocation = false
            showingLocationSuggestions = false
        }
    }
    
    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    func improveWithAI() {
        guard appState.canUseAI() else {
            showingAILimitAlert = true
            return
        }
        
        isLoadingAI = true
        
        Task {
            do {
                let suggestions = try await aiService.improveText(content)
                await MainActor.run {
                    aiSuggestions = suggestions
                    appState.incrementAIUsage()
                    isLoadingAI = false
                    showingAIImprovement = true
                }
            } catch {
                await MainActor.run {
                    isLoadingAI = false
                    print("AI improvement failed: \(error)")
                }
            }
        }
    }
    
    func saveEntry() {
        let entry = DiaryEntry(
            context: managedObjectContext,
            entryType: .text,
            content: content,
            journalMode: appState.journalMode
        )
        
        entry.title = title.isEmpty ? nil : title
        entry.mood = mood.isEmpty ? nil : mood
        entry.location = location.isEmpty ? nil : location
        
        if !tags.isEmpty {
            if let jsonData = try? JSONEncoder().encode(tags),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.tags = jsonString
            }
        }
        
        do {
            try managedObjectContext.save()
            
            // Dismiss first, then show feedback from parent view
            dismiss()
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
}

// MARK: - Success Feedback View
struct SuccessFeedbackView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Entry Saved!")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Successfully saved to journal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .purple.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.top, 60) // Position near top
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct MoodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct TagChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(text)")
                .font(.caption)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.purple.opacity(0.2)))
        .foregroundColor(.purple)
    }
}

struct SuggestedTagChip: View {
    let text: String
    let isAdded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("#\(text)")
                    .font(.caption)
                
                Image(systemName: isAdded ? "xmark.circle.fill" : "plus.circle.fill")
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(isAdded ? Color.purple.opacity(0.2) : Color.purple.opacity(0.1)))
            .foregroundColor(isAdded ? .purple : .purple.opacity(0.7))
            .overlay(
                Capsule()
                    .strokeBorder(Color.purple.opacity(isAdded ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

struct AIImprovementSheet: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Version \(index + 1)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: { onSelect(suggestion) }) {
                                    Text("Use This")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.purple))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(suggestion)
                                .font(.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TextEntryEditorView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}


