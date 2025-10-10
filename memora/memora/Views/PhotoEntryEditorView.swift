 //
//  PhotoEntryEditorView.swift
//  Memora
//
//  Photo-based journal entry with AI caption generation
//

import SwiftUI
import PhotosUI
import CoreData

struct PhotoEntryEditorView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var content: String = ""
    @State private var characterNames: String = ""
    @State private var location: String = ""
    
    @State private var isGeneratingCaption = false
    @StateObject private var aiService = AIService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photo Picker
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        VStack(spacing: 15) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                            
                            Text(loadedImages.isEmpty ? "Add Photos" : "Add More Photos")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                .foregroundColor(.purple.opacity(0.5))
                        )
                    }
                    .onChange(of: selectedPhotos) { oldValue, newValue in
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
                    
                    // Metadata Fields
                    if appState.journalMode == .child {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Who's in the photo?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g., Melike, Uğur, Yağız", text: $characterNames)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Where was this taken?", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // AI Generate Caption Button
                    if !loadedImages.isEmpty && content.isEmpty {
                        Button(action: generateCaption) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(isGeneratingCaption ? "Generating..." : "Generate Caption with AI")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isGeneratingCaption)
                    }
                    
                    // Caption/Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Entry")
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
                    .disabled(loadedImages.isEmpty || content.isEmpty)
                }
            }
        }
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
                metadata["date"] = Date().formatted(date: .long, time: .omitted)
                
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
        
        entry.location = location.isEmpty ? nil : location
        
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


