//
//  DiaryEntry.swift
//  Memora
//
//  Core Data model for diary entries
//

import Foundation
import CoreData

@objc(DiaryEntry)
public class DiaryEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var content: String
    @NSManaged public var createdAt: Date
    @NSManaged public var modifiedAt: Date
    @NSManaged public var entryType: String // text, photo, voice
    @NSManaged public var mood: String?
    @NSManaged public var tags: String? // JSON array of tags
    @NSManaged public var location: String?
    @NSManaged public var photoURLs: String? // JSON array of local file paths
    @NSManaged public var audioURL: String?
    @NSManaged public var aiImproved: Bool
    @NSManaged public var journalMode: String // personal or child
    @NSManaged public var characterNames: String? // JSON array for photo metadata
    @NSManaged public var childAge: Int16 // for child mode entries
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


