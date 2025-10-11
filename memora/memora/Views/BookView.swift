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
    
    var filteredEntries: [DiaryEntry] {
        if selectedFilters.isEmpty {
            return Array(entries)
        }
        
        return entries.filter { entry in
            let entryTags = entry.tagsArray ?? []
            let entryLocation = entry.location ?? ""
            
            // Check if any selected filter matches entry's tags or location
            for filter in selectedFilters {
                if entryTags.contains(filter) || entryLocation == filter {
                    return true
                }
            }
            return false
        }
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Overview - Improved Design
                    if !entries.isEmpty {
                        StatsOverviewCard(
                            totalEntries: entries.count,
                            photoEntries: entries.filter { $0.entryType == "photo" }.count,
                            voiceEntries: entries.filter { $0.entryType == "voice" }.count,
                            aiImproved: entries.filter { $0.aiImproved }.count
                        )
                        .padding(.horizontal)
                        
                        // Unified Filters - Tags + Locations
                        if !uniqueTags.isEmpty || !uniqueLocations.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
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
                                    ForEach(orderedTags, id: \.tag) { item in
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
                                    
                                    // Location filters
                                    ForEach(uniqueLocations, id: \.location) { item in
                                        FilterChip(
                                            icon: "location.fill",
                                            label: item.location,
                                            count: item.count,
                                            isSelected: selectedFilters.contains(item.location),
                                            action: {
                                                if selectedFilters.contains(item.location) {
                                                    selectedFilters.remove(item.location)
                                                    selectionOrder.removeAll { $0 == item.location }
                                                } else {
                                                    selectedFilters.insert(item.location)
                                                    selectionOrder.append(item.location)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
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
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("Export as PDF", systemImage: "doc.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingEntryDetail) {
                if let entry = selectedEntry {
                    EntryDetailView(entry: entry)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatsOverviewCard: View {
    let totalEntries: Int
    let photoEntries: Int
    let voiceEntries: Int
    let aiImproved: Int
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "doc.text.fill",
                value: "\(totalEntries)",
                label: "Entries",
                color: .purple
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "photo.fill",
                value: "\(photoEntries)",
                label: "Photos",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "mic.fill",
                value: "\(voiceEntries)",
                label: "Voice",
                color: .pink
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "sparkles",
                value: "\(aiImproved)",
                label: "AI",
                color: .orange
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
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
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .purple)
                    .lineLimit(1)
                
                if let count = count {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.purple.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple : Color.purple.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct JournalEntryCard: View {
    let entry: DiaryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Entry type icon
                Image(systemName: iconForEntryType(entry.entryType))
                    .foregroundColor(.purple)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.createdAt, style: .date)
                        .font(.subheadline.bold())
                    
                    Text(entry.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                Spacer()
                
                // Labels
                HStack(spacing: 6) {
                    if let mood = entry.mood, !mood.isEmpty {
                        Text(mood.prefix(2))
                                .font(.caption)
                        }
                        
                        if entry.aiImproved {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
            }
            
            // Title
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            // Content Preview
            Text(entry.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags & Location
            HStack {
                    if let tags = entry.tagsArray, !tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text(tags.prefix(2).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.purple)
                        if tags.count > 2 {
                            Text("+\(tags.count - 2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let location = entry.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                    BookPageView(entry: entry)
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {}) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: {}) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct BookPageView: View {
    let entry: DiaryEntry
    
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
            
            // Photos
            if let photoURLs = entry.photoURLsArray, !photoURLs.isEmpty {
                TabView {
                    ForEach(photoURLs, id: \.self) { url in
                        if let image = loadImage(from: url) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(15)
                        }
                    }
                }
                .frame(height: 300)
                .tabViewStyle(.page)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

#Preview {
    BookView()
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}
