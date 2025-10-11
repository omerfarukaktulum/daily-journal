//
//  EditEntryView.swift
//  Memora
//
//  Edit existing journal entry
//

import SwiftUI
import CoreData

struct EditEntryView: View {
    let entry: DiaryEntry
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var location: String = ""
    
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
                        Text("Location (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Where are you?", text: $location)
                            .textFieldStyle(.roundedBorder)
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
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                loadEntryData()
            }
        }
    }
    
    func loadEntryData() {
        title = entry.title ?? ""
        content = entry.content
        mood = entry.mood ?? ""
        location = entry.location ?? ""
        tags = entry.tagsArray ?? []
    }
    
    func saveChanges() {
        entry.title = title.isEmpty ? nil : title
        entry.content = content
        entry.mood = mood.isEmpty ? nil : mood
        entry.location = location.isEmpty ? nil : location
        entry.modifiedAt = Date()
        
        if !tags.isEmpty {
            if let jsonData = try? JSONEncoder().encode(tags),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.tags = jsonString
            }
        } else {
            entry.tags = nil
        }
        
        do {
            try managedObjectContext.save()
            
            // Dismiss first, then parent will show feedback
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

// MARK: - Success Feedback View (shared component)
struct EditSuccessFeedbackView: View {
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
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

