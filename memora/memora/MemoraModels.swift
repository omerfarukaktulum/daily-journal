//
//  MemoraModels.swift
//  memora
//
//  All app models and state in one file
//

import Foundation
import SwiftUI
import CoreData
import Combine

// MARK: - App State
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var journalMode: JournalMode {
        didSet {
            UserDefaults.standard.set(journalMode.rawValue, forKey: "journalMode")
        }
    }
    
    @Published var isPremiumUser: Bool {
        didSet {
            UserDefaults.standard.set(isPremiumUser, forKey: "isPremiumUser")
        }
    }
    
    @Published var aiUsageCount: Int {
        didSet {
            UserDefaults.standard.set(aiUsageCount, forKey: "aiUsageCount")
        }
    }
    
    @Published var lastResetDate: Date {
        didSet {
            UserDefaults.standard.set(lastResetDate, forKey: "lastResetDate")
        }
    }
    
    // Navigation to newly saved entry
    @Published var pendingEntryToShow: UUID? = nil
    @Published var shouldNavigateToJournal: Bool = false
    @Published var shouldNavigateToNewEntry: Bool = false
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let modeString = UserDefaults.standard.string(forKey: "journalMode") ?? "personal"
        self.journalMode = JournalMode(rawValue: modeString) ?? .personal
        self.isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        self.aiUsageCount = UserDefaults.standard.integer(forKey: "aiUsageCount")
        self.lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
        
        // Reset AI usage count daily for PREMIUM users only
        if isPremiumUser {
            resetDailyUsageIfNeeded()
        }
    }
    
    func resetDailyUsageIfNeeded() {
        // Only reset for premium users
        guard isPremiumUser else { return }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            aiUsageCount = 0
            lastResetDate = Date()
        }
    }
    
    func canUseAI() -> Bool {
        if isPremiumUser {
            resetDailyUsageIfNeeded()
            return aiUsageCount < 5  // Premium: 5 per day
        } else {
            return aiUsageCount < 5  // Free: 5 total (lifetime)
        }
    }
    
    func incrementAIUsage() {
        aiUsageCount += 1
    }
}

enum JournalMode: String, Codable {
    case personal = "personal"
    case child = "child"
}

// MARK: - Data Controller
class DataController: ObservableObject {
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "memora")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
                fatalError("Core Data store failed to load: \(error)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                print("❌ Failed to save context: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Diary Entry Model
@objc(DiaryEntry)
public class DiaryEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var content: String
    @NSManaged public var createdAt: Date
    @NSManaged public var modifiedAt: Date
    @NSManaged public var entryType: String
    @NSManaged public var mood: String?
    @NSManaged public var tags: String?
    @NSManaged public var location: String?
    @NSManaged public var photoURLs: String?
    @NSManaged public var audioURL: String?
    @NSManaged public var aiImproved: Bool
    @NSManaged public var journalMode: String
    @NSManaged public var characterNames: String?
    @NSManaged public var childAge: Int16
}

extension DiaryEntry {
    static func fetchRequest() -> NSFetchRequest<DiaryEntry> {
        return NSFetchRequest<DiaryEntry>(entityName: "DiaryEntry")
    }
    
    var photoURLsArray: [URL]? {
        guard let photoURLs = photoURLs,
              let data = photoURLs.data(using: .utf8),
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return paths.compactMap { URL(fileURLWithPath: $0) }
    }
    
    var tagsArray: [String]? {
        guard let tags = tags,
              let data = tags.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return array
    }
    
    var characterNamesArray: [String]? {
        guard let characterNames = characterNames,
              let data = characterNames.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return array
    }
    
    convenience init(context: NSManagedObjectContext, entryType: EntryType, content: String, journalMode: JournalMode) {
        self.init(context: context)
        self.id = UUID()
        self.content = content
        self.entryType = entryType.rawValue
        self.journalMode = journalMode.rawValue
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.aiImproved = false
    }
}

enum EntryType: String, Codable {
    case text = "text"
    case photo = "photo"
    case voice = "voice"
}

