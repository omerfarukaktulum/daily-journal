//
//  AppState.swift
//  Memora
//
//  Manages global app state
//

import Foundation
import SwiftUI

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
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let modeString = UserDefaults.standard.string(forKey: "journalMode") ?? "personal"
        self.journalMode = JournalMode(rawValue: modeString) ?? .personal
        self.isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        self.aiUsageCount = UserDefaults.standard.integer(forKey: "aiUsageCount")
        self.lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
        
        // Reset AI usage count daily for free users
        resetDailyUsageIfNeeded()
    }
    
    func resetDailyUsageIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            aiUsageCount = 0
            lastResetDate = Date()
        }
    }
    
    func canUseAI() -> Bool {
        resetDailyUsageIfNeeded()
        return isPremiumUser || aiUsageCount < 5
    }
    
    func incrementAIUsage() {
        if !isPremiumUser {
            aiUsageCount += 1
        }
    }
}

enum JournalMode: String, Codable {
    case personal = "personal"
    case child = "child"
}


