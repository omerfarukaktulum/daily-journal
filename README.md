# 📘 Memora – AI-Powered Personal & Family Journal

> "Your memories, reimagined by AI."

Memora is a beautiful iOS journaling app that makes writing and reflecting effortless through AI assistance. Capture your thoughts through text, voice, or photos, and let AI help you express yourself beautifully.

## ✨ Features

- **📝 Text Journaling** - Write with a rich text editor and improve your entries with AI
- **🎙️ Voice Journaling** - Record your thoughts and get instant transcriptions
- **📸 Photo Journaling** - Capture moments with images and generate AI-powered captions
- **📖 Beautiful Book View** - Browse your entries in a stunning page-flipping journal
- **👶 Child Mode** - Special journaling mode for documenting your child's milestones
- **🔔 Smart Reminders** - Daily notifications to maintain your journaling habit
- **☁️ iCloud Sync** - Seamlessly sync across all your Apple devices
- **🔒 Privacy First** - All data encrypted locally with optional privacy mode

## 🚀 Getting Started

### Prerequisites

- macOS with Xcode 15.0 or later
- iOS 17.0+ deployment target
- Apple Developer account (for device testing)
- OpenAI API key (for AI features)

### Installation

1. **Clone the repository:**
   ```bash
   cd /Users/omerfaruk/Personal/projects/daily-journal
   ```

2. **Open in Xcode:**
   ```bash
   open MemoraApp.xcodeproj
   ```
   
   Or simply double-click the `MemoraApp.xcodeproj` file.

3. **Configure your API Key:**
   - Run the app and navigate to Settings → API Configuration
   - Add your OpenAI API key
   - Get a key at: https://platform.openai.com/api-keys

4. **Set up signing:**
   - In Xcode, select the project in the navigator
   - Go to "Signing & Capabilities"
   - Select your development team
   - Xcode will automatically create provisioning profiles

5. **Enable iCloud:**
   - In "Signing & Capabilities", ensure "iCloud" is enabled
   - Check "CloudKit" under Services
   - The container identifier is: `iCloud.com.memora.journal`

6. **Build and Run:**
   - Select a simulator or connected device
   - Press `Cmd + R` or click the Run button

## 📁 Project Structure

```
MemoraApp/
├── MemoraApp.swift              # Main app entry point
├── AppState.swift               # Global app state management
├── ContentView.swift            # Main navigation structure
├── Models/
│   ├── DiaryEntry.swift         # Core Data entity
│   └── DataController.swift     # Core Data stack
├── Views/
│   ├── OnboardingView.swift     # First-time user onboarding
│   ├── HomeView.swift           # Dashboard with recent entries
│   ├── NewEntryView.swift       # Entry type selection
│   ├── TextEntryEditorView.swift   # Text journaling
│   ├── PhotoEntryEditorView.swift  # Photo journaling
│   ├── VoiceEntryRecorderView.swift # Voice journaling
│   ├── BookView.swift           # Book-style entry browser
│   └── SettingsView.swift       # App settings
├── Services/
│   ├── AIService.swift          # OpenAI API integration
│   └── NotificationService.swift # Local notifications
├── Memora.xcdatamodeld/         # Core Data model
└── Info.plist                   # App permissions & configuration
```

## 🔑 Required Permissions

The app requests the following permissions:

- **Microphone** - For voice journal entries
- **Speech Recognition** - To transcribe voice recordings
- **Photo Library** - To add photos to entries
- **Camera** - To capture new photos
- **Location** (optional) - To add location context
- **Notifications** - For daily journaling reminders

## 💎 Premium Features

Memora offers a freemium model:

### Free Tier
- Create unlimited text/photo/voice entries
- 5 AI improvements per day
- Basic themes
- iCloud sync

### Premium ($4.99/month or $39.99/year)
- Unlimited AI improvements
- Advanced voice transcription
- Premium themes
- Multiple journals
- Advanced analytics
- Priority support

## 🛠️ Technologies Used

- **SwiftUI** - Modern declarative UI framework
- **Core Data** - Local data persistence
- **CloudKit** - iCloud synchronization
- **Speech Framework** - Voice-to-text transcription
- **AVFoundation** - Audio recording
- **PhotosUI** - Photo selection
- **UserNotifications** - Daily reminders
- **StoreKit 2** - In-app purchases (coming soon)
- **OpenAI GPT-4o mini** - AI text improvements

## 🔐 Privacy & Security

- All journal data is stored locally in an encrypted format
- iCloud sync uses end-to-end encryption
- AI features only process data when explicitly requested
- Optional privacy mode keeps everything on-device
- No analytics or tracking without consent
- GDPR and CCPA compliant

## 🗺️ Roadmap

- [ ] Complete StoreKit integration for Premium subscriptions
- [ ] Export to PDF with custom templates
- [ ] Advanced search with filters
- [ ] Sentiment analysis dashboard
- [ ] Weekly AI-generated summaries
- [ ] Collaborative family journals
- [ ] Apple Watch companion app
- [ ] Widget support
- [ ] Siri shortcuts
- [ ] On-device AI models (CoreML)

## 🐛 Known Issues

- Voice recognition requires iOS 17.0+
- Some features require an active internet connection
- iCloud sync requires sufficient iCloud storage

## 📝 Development Notes

### Setting up Core Data

The app uses `NSPersistentCloudKitContainer` which automatically handles CloudKit sync. Make sure:

1. CloudKit is enabled in Capabilities
2. The container identifier matches your app ID
3. You're signed in with an iCloud account in the simulator/device

### AI Service Configuration

For development, you can set your API key as an environment variable:

```bash
export OPENAI_API_KEY="your-key-here"
```

Or add it directly in Settings → API Configuration within the app.

### Testing

To test the app without an API key:
- Voice transcription uses Apple's Speech Framework (works offline)
- Photo entries can be created without AI captions
- Text entries work without AI improvements

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

Copyright © 2025. All rights reserved.

## 📧 Support

For questions or support, please contact: support@memora.app

---

**Made with ❤️ for mindful journaling**


