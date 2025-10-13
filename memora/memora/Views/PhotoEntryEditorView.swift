 //
//  PhotoEntryEditorView.swift
//  Memora
//
//  Photo-based journal entry with AI caption generation
//

import SwiftUI
import PhotosUI
import CoreData
import CoreLocation
import MapKit

struct PhotoEntryEditorView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.createdAt, ascending: false)],
        animation: .default
    ) var existingEntries: FetchedResults<DiaryEntry>
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var characterNames: String = ""
    @State private var location: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    
    @State private var isGeneratingCaption = false
    @State private var showingCamera = false
    @State private var showingImageSourcePicker = false
    @State private var isFetchingLocation = false
    @State private var showingLocationSuggestions = false
    @State private var selectedDate: Date = Date() // Date picker for entries
    @State private var showingDatePicker = false // Show/hide date picker sheet
    
    @StateObject private var aiService = AIService()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var locationSearch = LocationSearchService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header: Date + Title (Side by Side)
                    HStack(alignment: .top, spacing: 12) {
                        // Date Picker (Compact)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                    Text(compactDate)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Title (Takes remaining space)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                
                                TextField("Give your entry a title...", text: $title)
                                    .font(.body)
                                    .padding(12)
                            }
                            .frame(height: 44)
                        }
                    }
                    
                    // Photo Source Buttons
                    HStack(spacing: 15) {
                        // Take Photo Button
                        Button(action: { 
                            #if targetEnvironment(simulator)
                            // Camera not available in simulator
                            print("📷 Camera not available in simulator. Use a physical device.")
                            #else
                            showingCamera = true
                            #endif
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                
                                Text("Take Photo")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    .foregroundColor(.purple.opacity(0.5))
                            )
                        }
                        .disabled(isSimulator())
                        
                        // Choose from Library Button
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                
                                Text(loadedImages.isEmpty ? "Add Photos" : "Add More")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    .foregroundColor(.purple.opacity(0.5))
                            )
                        }
                    }
                    .onChange(of: selectedPhotos) { _ in
                        loadPhotos()
                    }
                    
                    // Selected Photos Grid
                    if !loadedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: {
                                            loadedImages.remove(at: index)
                                            selectedPhotos.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.6)))
                                        }
                                        .padding(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Caption/Content
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Caption")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // AI Button (Inline with label) - only show when images loaded
                            if !loadedImages.isEmpty {
                                Button(action: generateCaption) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isGeneratingCaption ? "arrow.clockwise" : "sparkles")
                                            .font(.caption)
                                        Text(isGeneratingCaption ? "Generating..." : "Generate with AI")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                                }
                                .disabled(isGeneratingCaption)
                            }
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Write a caption for your photos...")
                                    .font(.body)
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 150)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(content.isEmpty ? Color.clear : Color.purple.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    
                    // Location Field
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Location")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: fetchCurrentLocation) {
                                HStack(spacing: 4) {
                                    Image(systemName: isFetchingLocation ? "arrow.clockwise" : "location.fill")
                                    Text(isFetchingLocation ? "Getting..." : "Use Current")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                            }
                            .disabled(isFetchingLocation)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            
                            TextField("Where was this taken?", text: $locationSearch.searchQuery)
                                .font(.body)
                                .padding(12)
                                .onChange(of: locationSearch.searchQuery) { newValue in
                                    location = newValue
                                    showingLocationSuggestions = !newValue.isEmpty && !locationSearch.suggestions.isEmpty
                                }
                        }
                        .frame(height: 44)
                        
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    TagChip(text: tag) {
                                        tags.removeAll { $0 == tag }
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                
                                TextField("Add a tag...", text: $newTag)
                                    .font(.body)
                                    .padding(12)
                                    .onSubmit {
                                        if !newTag.isEmpty && !tags.contains(newTag) {
                                            tags.append(newTag)
                                            newTag = ""
                                        }
                                    }
                            }
                            .frame(height: 44)
                            
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
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Photo Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .font(.body.bold())
                    .foregroundColor((loadedImages.isEmpty || content.isEmpty) ? .secondary : .purple)
                    .disabled(loadedImages.isEmpty || content.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        hideKeyboard()
                    }
                    .font(.body.bold())
                    .foregroundColor(.purple)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    DispatchQueue.main.async {
                        loadedImages.append(image)
                        showingCamera = false
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                VStack(spacing: 0) {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingDatePicker = false
                        }
                    }
                }
                .background(Color(.systemBackground))
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    var compactDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
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
        
        // Wait for location update (longer timeout for simulator)
        let timeout: TimeInterval = isSimulator() ? 5.0 : 2.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if let locationString = locationManager.locationString {
                location = locationString
                locationSearch.searchQuery = locationString
            } else {
                // Provide helpful message for simulator
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
    
    func loadPhotos() {
        Task {
            loadedImages.removeAll()
            
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        loadedImages.append(image)
                    }
                }
            }
        }
    }
    
    func generateCaption() {
        guard appState.canUseAI() else {
            return
        }
        
        isGeneratingCaption = true
        
        Task {
            do {
                var metadata: [String: String] = [:]
                if !characterNames.isEmpty {
                    metadata["names"] = characterNames
                }
                if !location.isEmpty {
                    metadata["location"] = location
                }
                // Don't include date - it's already shown in the UI
                
                // Simple description - in production, you'd use Vision API or GPT-4 Vision
                let description = "A precious moment captured in a photo"
                
                let caption = try await aiService.generatePhotoCaption(
                    description: description,
                    metadata: metadata
                )
                
                await MainActor.run {
                    content = caption
                    appState.incrementAIUsage()
                    isGeneratingCaption = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingCaption = false
                    print("Caption generation failed: \(error)")
                }
            }
        }
    }
    
    func saveEntry() {
        // Save images to app's document directory
        var photoURLs: [String] = []
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("photos", isDirectory: true)
        
        // Create photos directory if it doesn't exist
        try? fileManager.createDirectory(at: photosPath, withIntermediateDirectories: true)
        
        for (index, image) in loadedImages.enumerated() {
            let filename = "\(UUID().uuidString).jpg"
            let fileURL = photosPath.appendingPathComponent(filename)
            
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try? jpegData.write(to: fileURL)
                photoURLs.append(fileURL.path)
            }
        }
        
        let entry = DiaryEntry(
            context: managedObjectContext,
            entryType: .photo,
            content: content,
            journalMode: appState.journalMode
        )
        
        entry.createdAt = selectedDate // Use selected date
        entry.title = title.isEmpty ? nil : title
        entry.location = location.isEmpty ? nil : location
        
        if !tags.isEmpty {
            if let jsonData = try? JSONEncoder().encode(tags),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.tags = jsonString
            }
        }
        
        if !characterNames.isEmpty {
            let namesArray = characterNames.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if let jsonData = try? JSONEncoder().encode(namesArray),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.characterNames = jsonString
            }
        }
        
        if !photoURLs.isEmpty {
            if let jsonData = try? JSONEncoder().encode(photoURLs),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.photoURLs = jsonString
            }
        }
        
        do {
            try managedObjectContext.save()
            
            // Navigate to Journal and show this entry
            appState.pendingEntryToShow = entry.id
            appState.shouldNavigateToJournal = true
            
            // Dismiss the sheet
            dismiss()
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
}

#Preview {
    PhotoEntryEditorView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}


