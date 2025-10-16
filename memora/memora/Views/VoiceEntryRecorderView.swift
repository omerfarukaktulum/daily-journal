//
//  VoiceEntryRecorderView.swift
//  Memora
//
//  Voice journal entry with speech-to-text transcription
//

import SwiftUI
import AVFoundation
import Speech
import CoreData
import Combine
import CoreLocation
import MapKit

struct VoiceEntryRecorderView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.createdAt, ascending: false)],
        animation: .default
    ) var existingEntries: FetchedResults<DiaryEntry>
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var hasRecorded = false
    @State private var transcribedText = ""
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    
    // Editor fields (like TextEntryEditorView)
    @State private var title: String = ""
    @State private var mood: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var location: String = ""
    @State private var isFetchingLocation = false
    @State private var showingLocationSuggestions = false
    @State private var selectedDate: Date = Date() // Date picker for entries
    @State private var showingDatePicker = false // Show/hide date picker sheet
    
    @StateObject private var locationSearch = LocationSearchService()
    @State private var showingAIImprovement = false
    @State private var aiSuggestions: [String] = []
    @State private var isLoadingAI = false
    @State private var showingPremiumSheet = false
    @State private var showingDailyLimitAlert = false
    @State private var usedAI = false // Track if AI was used
    
    @StateObject private var aiService = AIService()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            if !hasRecorded {
                // Recording View
                recordingView
            } else {
                // Editor View (after recording)
                editorView
            }
        }
    }
    
    var recordingView: some View {
            ZStack {
                LinearGradient(
                    colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Recording Animation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                        
                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    
                    // Duration
                    if isRecording {
                        Text(formatDuration(recordingDuration))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text("Ready to Record")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Record Button
                    Button(action: toggleRecording) {
                        Text(isRecording ? "Stop Recording" : "Start Recording")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(isRecording ? Color.red : Color.pink)
                            )
                    }
                    
                    Spacer()
                    
                // Live Transcription Preview
                if isRecording && !speechRecognizer.transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                        Text("Live Transcription")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ScrollView {
                            Text(speechRecognizer.transcript)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        .frame(maxHeight: 150)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Voice Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopRecording()
                        dismiss()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .onAppear {
            requestPermissions()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    var editorView: some View {
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
                
                // Transcribed Content (Editable)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Voice Entry")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Re-record button (left side)
                        Button(action: {
                            hasRecorded = false
                            transcribedText = ""
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Re-record")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.pink)
                        }
                        
                        Spacer()
                        
                        // AI Button (right-aligned)
                        Button(action: improveWithAI) {
                            HStack(spacing: 6) {
                                Image(systemName: isLoadingAI ? "arrow.clockwise" : "sparkles")
                                    .font(.caption)
                                Text(isLoadingAI ? "Improving..." : "Improve with AI")
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
                        .disabled(isLoadingAI)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if transcribedText.isEmpty {
                            Text("Your transcribed voice entry will appear here...")
                                .font(.body)
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                        }
                        
                        TextEditor(text: $transcribedText)
                            .frame(minHeight: 180)
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
                            .stroke(transcribedText.isEmpty ? Color.clear : Color.purple.opacity(0.2), lineWidth: 1.5)
                    )
                }
                
                // Mood Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("How are you feeling?")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
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
                        
                        TextField("Where are you?", text: $locationSearch.searchQuery)
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
        .navigationTitle("Edit Voice Entry")
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
                    .foregroundColor(.purple)
                    .disabled(transcribedText.isEmpty)
                }
            
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    hideKeyboard()
                }
                .font(.body.bold())
                .foregroundColor(.purple)
            }
            }
        .sheet(isPresented: $showingAIImprovement) {
            AIImprovementSheet(suggestions: aiSuggestions) { selectedVersion in
                transcribedText = selectedVersion
                usedAI = true // Mark that AI was used
                showingAIImprovement = false
            }
        }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumUpgradeView()
            }
            .alert("Daily AI Limit Reached", isPresented: $showingDailyLimitAlert) {
                Button("OK") { }
            } message: {
                Text("You've used all 5 AI improvements for today. Come back tomorrow for more AI-powered enhancements!")
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
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                SFSpeechRecognizer.requestAuthorization { status in
                    // Handle authorization status
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        recordingDuration = 0
        isRecording = true
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingDuration += 1
        }
        
        // Start speech recognition
        Task {
            await speechRecognizer.startTranscribing()
        }
    }
    
    func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        Task {
            await speechRecognizer.stopTranscribing()
            await MainActor.run {
                transcribedText = speechRecognizer.transcript
                if !transcribedText.isEmpty {
                    hasRecorded = true
                }
            }
        }
    }
    
    func improveWithAI() {
        // Check if user is premium first
        if !appState.isPremiumUser {
            // Free user needs to upgrade
            showingPremiumSheet = true
            return
        }
        
        // Premium user - check daily usage
        guard appState.canUseAI() else {
            // Premium user has reached daily limit
            showingDailyLimitAlert = true
            return
        }
        
        isLoadingAI = true
        
        Task {
            do {
                let suggestions = try await aiService.improveText(transcribedText)
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
            entryType: .voice,
            content: transcribedText,
            journalMode: appState.journalMode
        )
        
        entry.createdAt = selectedDate // Use selected date
        entry.title = title.isEmpty ? nil : title
        entry.mood = mood.isEmpty ? nil : mood
        entry.location = location.isEmpty ? nil : location
        entry.aiImproved = usedAI // Set AI improved flag
        
        if !tags.isEmpty {
            if let jsonData = try? JSONEncoder().encode(tags),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entry.tags = jsonString
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

// Speech Recognizer
@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    
    func startTranscribing() async {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("Speech recognition not available")
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    Task { @MainActor in
                        self.transcript = result.bestTranscription.formattedString
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                }
            }
        } catch {
            print("Could not start transcription: \(error)")
        }
    }
    
    func stopTranscribing() async {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

#Preview {
    VoiceEntryRecorderView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
}
