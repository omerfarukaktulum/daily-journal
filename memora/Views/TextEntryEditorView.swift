//
//  TextEntryEditorView.swift
//  Memora
//
//  Text-based journal entry editor with AI improvements
//

import SwiftUI

struct TextEntryEditorView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    
    @State private var showingAIImprovement = false
    @State private var aiSuggestions: [String] = []
    @State private var isLoadingAI = false
    @State private var showingAILimitAlert = false
    
    @StateObject private var aiService = AIService()
    
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
        
        if !tags.isEmpty {
            if let jsonData = try? JSONEncoder().encode(tags),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.tags = jsonString
            }
        }
        
        do {
            try managedObjectContext.save()
            dismiss()
        } catch {
            print("Failed to save entry: \(error)")
        }
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


