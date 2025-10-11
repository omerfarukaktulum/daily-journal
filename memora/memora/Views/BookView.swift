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
    
    @State private var selectedFilter: FilterType = .all
    @State private var searchText = ""
    @State private var selectedEntry: DiaryEntry?
    @State private var showingEntryDetail = false
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case text = "Text"
        case photo = "Photo"
        case voice = "Voice"
    }
    
    var filteredEntries: [DiaryEntry] {
        var result = Array(entries)
        
        // Filter by type
        if selectedFilter != .all {
            result = result.filter { $0.entryType == selectedFilter.rawValue.lowercased() }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                (entry.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
    }
    
    var uniqueTags: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        
        for entry in entries {
            if let tags = entry.tagsArray {
                for tag in tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
        }
        
        return tagCounts.map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
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
                    // Stats Overview
                    if !entries.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Overview")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    StatCard(
                                        icon: "doc.text.fill",
                                        title: "Total Entries",
                                        value: "\(entries.count)",
                                        color: .purple
                                    )
                                    
                                    StatCard(
                                        icon: "photo.fill",
                                        title: "Photo Entries",
                                        value: "\(entries.filter { $0.entryType == "photo" }.count)",
                                        color: .blue
                                    )
                                    
                                    StatCard(
                                        icon: "mic.fill",
                                        title: "Voice Entries",
                                        value: "\(entries.filter { $0.entryType == "voice" }.count)",
                                        color: .pink
                                    )
                                    
                                    StatCard(
                                        icon: "sparkles",
                                        title: "AI Improved",
                                        value: "\(entries.filter { $0.aiImproved }.count)",
                                        color: .orange
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Top Tags
                        if !uniqueTags.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Popular Tags")
                                    .font(.title3.bold())
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(uniqueTags, id: \.tag) { item in
                                            TagStatCard(tag: item.tag, count: item.count)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Top Locations
                        if !uniqueLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Frequent Places")
                                    .font(.title3.bold())
                                    .padding(.horizontal)
                                
                                VStack(spacing: 10) {
                                    ForEach(uniqueLocations, id: \.location) { item in
                                        LocationStatCard(location: item.location, count: item.count)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Filter Tabs
                    if !entries.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("All Entries")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            // Filter Picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(FilterType.allCases, id: \.self) { filter in
                                        FilterChip(
                                            title: filter.rawValue,
                                            isSelected: selectedFilter == filter,
                                            action: { selectedFilter = filter }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Search entries...", text: $searchText)
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Entries List
                    if filteredEntries.isEmpty {
                    EmptyBookView()
                            .padding(.top, 40)
                } else {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredEntries, id: \.id) { entry in
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
                        
                        Button(action: {}) {
                            Label("Sort by Date", systemImage: "calendar")
                        }
                        
                        Button(action: {}) {
                            Label("Sort by Type", systemImage: "square.grid.2x2")
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

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct TagStatCard: View {
    let tag: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("#\(tag)")
                    .font(.headline)
                    .foregroundColor(.purple)
                
            Text("\(count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
}

struct LocationStatCard: View {
    let location: String
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.purple)
            
            Text(location)
                .font(.body)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(.purple)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
                        Text(title)
                .font(.subheadline.bold())
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

// FlowLayout for tags
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

#Preview {
    BookView()
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}
