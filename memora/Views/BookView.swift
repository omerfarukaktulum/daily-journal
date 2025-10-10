//
//  BookView.swift
//  Memora
//
//  Book-style journal presentation with page flipping
//

import SwiftUI
import CoreData

struct BookView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.createdAt, ascending: false)],
        animation: .default
    ) var entries: FetchedResults<DiaryEntry>
    
    @State private var currentPage = 0
    @State private var selectedEntry: DiaryEntry?
    @State private var showingEntryDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if entries.isEmpty {
                    EmptyBookView()
                } else {
                    TabView(selection: $currentPage) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            BookPageView(entry: entry)
                                .tag(index)
                                .onTapGesture {
                                    selectedEntry = entry
                                    showingEntryDetail = true
                                }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }
            }
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("Export as PDF", systemImage: "doc.fill")
                        }
                        
                        Button(action: {}) {
                            Label("Change Theme", systemImage: "paintbrush.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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

struct BookPageView: View {
    let entry: DiaryEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Header
            VStack(spacing: 5) {
                Text(entry.createdAt, style: .date)
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Text(entry.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photos
                    if let photoURLs = entry.photoURLsArray, !photoURLs.isEmpty {
                        TabView {
                            ForEach(photoURLs, id: \.self) { url in
                                if let image = loadImage(from: url) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 300)
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
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                    
                    // Content
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(8)
                    
                    // Metadata
                    HStack(spacing: 15) {
                        if let mood = entry.mood, !mood.isEmpty {
                            Label(mood, systemImage: "face.smiling")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let location = entry.location, !location.isEmpty {
                            Label(location, systemImage: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if entry.aiImproved {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    // Tags
                    if let tags = entry.tagsArray, !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color.purple.opacity(0.2)))
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
    
    func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
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
            
            Text("Start writing to see your entries in this beautiful book view")
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
                VStack(alignment: .leading, spacing: 20) {
                    // Full content view - similar to BookPageView but with more options
                    BookPageView(entry: entry)
                }
            }
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

#Preview {
    BookView()
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}


