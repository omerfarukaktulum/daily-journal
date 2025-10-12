//
//  BookView.swift
//  Memora
//
//  Journal overview with stats, filters, and entries
//

import SwiftUI
import CoreData

struct BookView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.createdAt, ascending: false)],
        animation: .default
    ) var entries: FetchedResults<DiaryEntry>
    
    @State private var selectedEntry: DiaryEntry?
    @State private var showingEntryDetail = false
    @State private var selectedFilters: Set<String> = []
    @State private var selectionOrder: [String] = [] // Track order of selections
    @State private var selectedEntryType: String? = nil // "text", "photo", "voice", or nil for all
    @State private var isTagsExpanded = false // For tag expansion
    @State private var refreshTrigger = UUID() // Force refresh after edit
    
    var filteredEntries: [DiaryEntry] {
        var result = Array(entries)
        
        // Filter by entry type first
        if let entryType = selectedEntryType {
            if entryType == "photo" {
                // For photo filter, show any entry that has photos
                result = result.filter { entry in
                    guard let photoURLs = entry.photoURLsArray else { return false }
                    return !photoURLs.isEmpty
                }
            } else {
                // For other types, filter by entryType
                result = result.filter { $0.entryType == entryType }
            }
        }
        
        // Then filter by tags only (AND logic, no locations)
        if !selectedFilters.isEmpty {
            result = result.filter { entry in
                let entryTags = entry.tagsArray ?? []
                
                // Entry must have ALL selected tags
                for filter in selectedFilters {
                    if !entryTags.contains(filter) {
                        return false
                    }
                }
                return true
            }
        }
        
        return result
    }
    
    var uniqueTags: [(tag: String, count: Int, lastUsed: Date)] {
        var tagInfo: [String: (count: Int, lastUsed: Date)] = [:]
        
        for entry in entries {
            if let entryTags = entry.tagsArray {
                for tag in entryTags {
                    let existingInfo = tagInfo[tag]
                    let newCount = (existingInfo?.count ?? 0) + 1
                    let latestDate = max(existingInfo?.lastUsed ?? .distantPast, entry.createdAt ?? .distantPast)
                    tagInfo[tag] = (count: newCount, lastUsed: latestDate)
                }
            }
        }
        
        // Sort by count descending, then by latest use if count is equal
        return tagInfo
            .sorted { first, second in
                if first.value.count == second.value.count {
                    return first.value.lastUsed > second.value.lastUsed
                }
                return first.value.count > second.value.count
            }
            .map { (tag: $0.key, count: $0.value.count, lastUsed: $0.value.lastUsed) }
    }
    
    var orderedTags: [(tag: String, count: Int, lastUsed: Date)] {
        // Selected tags (in selection order) come first, then unselected tags
        let selectedTags = selectionOrder.compactMap { selectedTag in
            uniqueTags.first { $0.tag == selectedTag }
        }
        let unselectedTags = uniqueTags.filter { !selectionOrder.contains($0.tag) }
        return selectedTags + unselectedTags
    }
    
    var uniqueLocations: [(location: String, count: Int)] {
        var locationCounts: [String: Int] = [:]
        
        for entry in entries {
            if let location = entry.location, !location.isEmpty {
                locationCounts[location, default: 0] += 1
            }
        }
        
        return locationCounts.map { (location: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }
    
    // Computed properties for entry counts (helps compiler)
    var totalEntriesCount: Int { entries.count }
    var photoEntriesCount: Int { 
        entries.filter { entry in
            guard let photoURLs = entry.photoURLsArray else { return false }
            return !photoURLs.isEmpty
        }.count
    }
    var voiceEntriesCount: Int { entries.filter { $0.entryType == "voice" }.count }
    var textEntriesCount: Int { entries.filter { $0.entryType == "text" }.count }
    var aiImprovedCount: Int { entries.filter { $0.aiImproved }.count }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tag Filters (2-line limit, no locations)
                    if !entries.isEmpty {
                        if !uniqueTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                FlowLayout(spacing: 10) {
                                    // All filter (default) - no count badge
                                    FilterChip(
                                        icon: "line.3.horizontal.decrease.circle",
                                        label: "All",
                                        count: nil,
                                        isSelected: selectedFilters.isEmpty,
                                        action: {
                                            selectedFilters.removeAll()
                                            selectionOrder.removeAll()
                                        }
                                    )
                                    
                                    // Tag filters (ordered: selected first in selection order, then unselected by count)
                                    ForEach(Array(orderedTags.prefix(isTagsExpanded ? orderedTags.count : 8).enumerated()), id: \.element.tag) { index, item in
                                        FilterChip(
                                            icon: "tag.fill",
                                            label: item.tag,
                                            count: item.count,
                                            isSelected: selectedFilters.contains(item.tag),
                                            action: {
                                                if selectedFilters.contains(item.tag) {
                                                    selectedFilters.remove(item.tag)
                                                    selectionOrder.removeAll { $0 == item.tag }
                                                } else {
                                                    selectedFilters.insert(item.tag)
                                                    selectionOrder.append(item.tag)
                                                }
                                            }
                                        )
                                    }
                                    
                                    // Show More / Show Less button
                                    if orderedTags.count > 8 {
                                        Button(action: {
                                            withAnimation {
                                                isTagsExpanded.toggle()
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: isTagsExpanded ? "chevron.up.circle.fill" : "plus.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.purple)
                                                
                                                Text(isTagsExpanded ? "Show Less" : "+\(orderedTags.count - 8)")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.purple)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.purple.opacity(0.15))
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Entries List
                    if filteredEntries.isEmpty && !entries.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tag.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.purple.opacity(0.5))
                            
                            Text("No entries match selected filters")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else if entries.isEmpty {
                    EmptyBookView()
                            .padding(.top, 40)
                } else {
                        LazyVStack(spacing: 15) {
                            ForEach(Array(filteredEntries.prefix(20)), id: \.id) { entry in
                                Button(action: {
                                    selectedEntry = entry
                                    showingEntryDetail = true
                                }) {
                                    JournalEntryCard(entry: entry)
                                        .id("\(entry.id)-\(entry.modifiedAt.timeIntervalSince1970)") // Force refresh on edit
                                }
                                .buttonStyle(PlainButtonStyle())
                                }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingEntryDetail) {
                if let entry = selectedEntry {
                    EntryDetailView(entry: entry)
                }
            }
            .onChange(of: showingEntryDetail) { oldValue, newValue in
                // When sheet closes, refresh the entries to show any edits
                if oldValue == true && newValue == false {
                    // Refresh all entries to pick up changes
                    if let entry = selectedEntry {
                        managedObjectContext.refresh(entry, mergeChanges: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    var statsOverviewGrid: some View {
        HStack(spacing: 10) {
            // All entries
            StatFilterChip(
                icon: "square.grid.2x2",
                label: "All",
                count: totalEntriesCount,
                isSelected: selectedEntryType == nil,
                gradient: [.purple, .pink],
                action: {
                    selectedEntryType = nil
                }
            )
            
            // Photo entries
            StatFilterChip(
                icon: "photo.fill",
                label: "Photos",
                count: photoEntriesCount,
                isSelected: selectedEntryType == "photo",
                gradient: [.blue, .cyan],
                action: {
                    selectedEntryType = selectedEntryType == "photo" ? nil : "photo"
                }
            )
            
            // Voice entries
            StatFilterChip(
                icon: "mic.fill",
                label: "Voice",
                count: voiceEntriesCount,
                isSelected: selectedEntryType == "voice",
                gradient: [.pink, .orange],
                action: {
                    selectedEntryType = selectedEntryType == "voice" ? nil : "voice"
                }
            )
            
            // Text entries
            StatFilterChip(
                icon: "doc.text.fill",
                label: "Text",
                count: textEntriesCount,
                isSelected: selectedEntryType == "text",
                gradient: [.purple, .indigo],
                action: {
                    selectedEntryType = selectedEntryType == "text" ? nil : "text"
                }
            )
            
            // AI improved
            StatFilterChip(
                icon: "sparkles",
                label: "AI",
                count: aiImprovedCount,
                isSelected: false,
                gradient: [.orange, .yellow],
                action: {
                    // TODO: Could add AI filter if needed
                }
            )
        }
    }
}

// MARK: - Supporting Views

struct StatFilterChip: View {
    let icon: String
    let label: String
    let count: Int
    let isSelected: Bool
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .purple)
                
                // Label and Count on same line
                HStack(spacing: 4) {
                    Text(label)
                        .font(.caption.bold())
                        .foregroundColor(isSelected ? .white : .purple)
                    
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .purple.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.7) : Color.purple.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let icon: String
    let label: String
    let count: Int? // Optional count - nil means don't show count badge
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .purple)
                
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : .purple)
                    .lineLimit(1)
                
                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .purple.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple.opacity(0.7) : Color.purple.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct JournalEntryCard: View {
    let entry: DiaryEntry
    
    var contentPreview: String {
        // For photo entries, return content text only (not photo URLs)
        guard !entry.content.isEmpty else { return "No content" }
        return entry.content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Date + Time on left, Mood + AI badge on right
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                Text(entry.createdAt, style: .date)
                    .font(.subheadline.bold())
                
                Text(entry.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
                
                Spacer()
                
                // Right side: Mood and AI badge
                HStack(spacing: 8) {
                    if let mood = entry.mood, !mood.isEmpty {
                        Text(mood.prefix(2))
                            .font(.body)
                    }
                    
                    if entry.aiImproved {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(5)
                            .background(Circle().fill(Color.orange.opacity(0.1)))
                    }
                }
            }
            
            // Title (if exists)
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                    .font(.callout.bold())
                            .foregroundColor(.primary)
                    .lineLimit(1)
                    }
                    
            // Content Preview (text only for photo entries)
            if !contentPreview.isEmpty {
                Text(contentPreview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Divider()
            
            // Footer: Tags and Location
            HStack(spacing: 12) {
                if let tags = entry.tagsArray, !tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text(tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                                .font(.caption)
                            .foregroundColor(.purple)
                            .lineLimit(1)
                        if tags.count > 3 {
                            Text("+\(tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let location = entry.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(location)
                                    .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
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

struct EmptyBookView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("Your journal is empty")
                .font(.title2.bold())
            
            Text("Start writing to see your entries here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct EntryDetailView: View {
    let entry: DiaryEntry
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingEditSheet = false
    @State private var showingSuccessFeedback = false
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                    BookPageView(entry: entry)
                    .padding()
                    .id(refreshTrigger) // Force refresh when this changes
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Edit button
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title3)
                        }
                        
                        // Share button
                        Button(action: shareEntry) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title3)
                        }
                        
                        // Delete button
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title3)
                        }
                    }
                }
            }
            .alert("Delete Entry?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [createShareText()])
            }
            .sheet(isPresented: $showingEditSheet) {
                EditEntryView(entry: entry, onSave: {
                    // Refresh the entry display
                    managedObjectContext.refresh(entry, mergeChanges: true)
                    refreshTrigger = UUID()
                    
                    // Show success feedback after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            showingSuccessFeedback = true
                        }
                        
                        // Hide after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showingSuccessFeedback = false
                            }
                        }
                    }
                })
                .environment(\.managedObjectContext, managedObjectContext)
            }
            .overlay(
                Group {
                    if showingSuccessFeedback {
                        VStack {
                            SuccessFeedbackViewTop()
                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            )
        }
    }
    
    func shareEntry() {
        showingShareSheet = true
    }
    
    func createShareText() -> String {
        var text = ""
        
        // Date
        text += entry.createdAt.formatted(date: .long, time: .shortened)
        text += "\n\n"
        
        // Title
        if let title = entry.title, !title.isEmpty {
            text += title + "\n\n"
        }
        
        // Content
        if !entry.content.isEmpty {
            text += entry.content
            text += "\n\n"
        }
        
        // Tags
        if let tags = entry.tagsArray, !tags.isEmpty {
            text += tags.map { "#\($0)" }.joined(separator: " ")
            text += "\n"
        }
        
        // Location
        if let location = entry.location, !location.isEmpty {
            text += "📍 \(location)\n"
        }
        
        text += "\n— Memora Journal"
        
        return text
    }
    
    func deleteEntry() {
        managedObjectContext.delete(entry)
        
        do {
            try managedObjectContext.save()
            dismiss()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
}

// Success Feedback at Top
struct SuccessFeedbackViewTop: View {
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
        .padding(.top, 8)
    }
}

// Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct BookPageView: View {
    let entry: DiaryEntry
    @State private var currentPhotoIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Date Header
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.createdAt, style: .date)
                    .font(.title2.bold())
                    .foregroundColor(.purple)
                
                Text(entry.createdAt, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Photos Carousel
            if let photoURLs = entry.photoURLsArray, !photoURLs.isEmpty {
                PhotoCarousel(photoURLs: photoURLs, currentIndex: $currentPhotoIndex)
            }
            
            // Title
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.title.bold())
            }
            
            // Content
            Text(entry.content)
                .font(.body)
                .lineSpacing(8)
            
            // Metadata
            VStack(alignment: .leading, spacing: 10) {
                if let mood = entry.mood, !mood.isEmpty {
                    HStack {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.purple)
                        Text(mood)
                            .font(.body)
                    }
                }
                
                if let location = entry.location, !location.isEmpty {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.purple)
                        Text(location)
                            .font(.body)
                    }
                }
                
                if entry.aiImproved {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("Enhanced with AI")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 10)
            
            // Tags
            if let tags = entry.tagsArray, !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.purple.opacity(0.2)))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    func loadImage(from url: URL) -> UIImage? {
        let fileManager = FileManager.default
        
        // Check if file exists
        if !fileManager.fileExists(atPath: url.path) {
            print("❌ File doesn't exist: \(url.path)")
            return nil
        }
        
        // Try to load the data
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            print("❌ Failed to load image data from: \(url.path)")
            return nil
        }
        
        print("✅ Loaded image from: \(url.lastPathComponent)")
        return image
    }
}

// MARK: - Photo Carousel Component
struct PhotoCarousel: View {
    let photoURLs: [URL]
    @Binding var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Main Photo Display with Swipe Gesture
            ZStack {
                // Current Photo
                if let image = loadImage(from: photoURLs[currentIndex]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if photoURLs.count > 1 {
                                        isDragging = true
                                        dragOffset = gesture.translation.width
                                    }
                                }
                                .onEnded { gesture in
                                    if photoURLs.count > 1 {
                                        let threshold: CGFloat = 50
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if gesture.translation.width < -threshold && currentIndex < photoURLs.count - 1 {
                                                // Swipe left -> next photo
                                                currentIndex += 1
                                            } else if gesture.translation.width > threshold && currentIndex > 0 {
                                                // Swipe right -> previous photo
                                                currentIndex -= 1
                                            }
                                            dragOffset = 0
                                            isDragging = false
                                        }
                                    }
                                }
                        )
                } else {
                    // Placeholder
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Image not available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .frame(height: 300)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            
            // Page Indicators & Counter (only show if multiple photos)
            if photoURLs.count > 1 {
                HStack(spacing: 12) {
                    // Swipe hint (show briefly)
                    if currentIndex == 0 && !isDragging {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.draw")
                                .font(.caption2)
                            Text("Swipe to navigate")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.gray.opacity(0.1)))
                        .transition(.opacity)
                    }
                    
                    // Dot Indicators
                    HStack(spacing: 6) {
                        ForEach(0..<photoURLs.count, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.purple : Color.gray.opacity(0.4))
                                .frame(width: currentIndex == index ? 8 : 6, height: currentIndex == index ? 8 : 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                    
                    // Photo Counter
                    Text("\(currentIndex + 1) / \(photoURLs.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.purple.opacity(0.1)))
                }
            }
        }
    }
    
    func loadImage(from url: URL) -> UIImage? {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: url.path) {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
}

#Preview {
    BookView()
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}
