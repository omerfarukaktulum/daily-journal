//
//  NotificationService.swift
//  Memora
//
//  Manages local notifications for daily journaling reminders
//

import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleDailyReminder(at time: Date) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily-journal-reminder"]
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Reflect"
        content.body = "Take a moment to capture your thoughts today ✨"
        content.sound = .default
        content.categoryIdentifier = "JOURNAL_REMINDER"
        
        // Extract hour and minute from date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily-journal-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func scheduleSmartReminder(prompt: String, delay: TimeInterval = 3600) {
        let content = UNMutableNotificationContent()
        content.title = "Memora"
        content.body = prompt
        content.sound = .default
        content.categoryIdentifier = "SMART_PROMPT"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "smart-prompt-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule smart reminder: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}


