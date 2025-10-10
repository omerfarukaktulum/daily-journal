//
//  VoiceEntryRecorderView.swift
//  Memora
//
//  Voice journal entry with speech-to-text transcription
//

import SwiftUI
import AVFoundation
import Speech

struct VoiceEntryRecorderView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
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
                    
                    // Transcribed Text Preview
                    if !transcribedText.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Transcription")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ScrollView {
                                Text(transcribedText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
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
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(transcribedText.isEmpty)
                }
            }
            .onAppear {
                requestPermissions()
            }
            .onDisappear {
                stopRecording()
            }
        }
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
        transcribedText = ""
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
            transcribedText = await speechRecognizer.transcript
        }
    }
    
    func saveEntry() {
        let entry = DiaryEntry(
            context: managedObjectContext,
            entryType: .voice,
            content: transcribedText,
            journalMode: appState.journalMode
        )
        
        do {
            try managedObjectContext.save()
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


