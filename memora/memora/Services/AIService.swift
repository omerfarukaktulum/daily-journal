//
//  AIService.swift
//  Memora
//
//  Handles AI-powered text improvements and image captioning
//

import Foundation
import Combine

@MainActor
class AIService: ObservableObject {
    private let backendURL = Config.backendURL
    
    init() {
        // No API key needed - using server-side AI
        print("🤖 AIService: Using server-side AI (no API key required)")
    }
    
    func improveText(_ text: String) async throws -> [String] {
        guard let url = URL(string: "\(backendURL)/api/improve-text") else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "text": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorData = try JSONDecoder().decode(BackendErrorResponse.self, from: data)
            throw AIError.serverError(errorData.error)
        }
        
        let result = try JSONDecoder().decode(TextImprovementResponse.self, from: data)
        return result.versions
    }
    
    func generatePhotoCaption(description: String, metadata: [String: String]) async throws -> String {
        var contextParts: [String] = []
        
        if let names = metadata["names"] {
            contextParts.append("People in photo: \(names)")
        }
        if let location = metadata["location"] {
            contextParts.append("Location: \(location)")
        }
        if let date = metadata["date"] {
            contextParts.append("Date: \(date)")
        }
        
        let context = contextParts.isEmpty ? "" : "\nContext: \(contextParts.joined(separator: ", "))"
        
        let prompt = """
        Create a warm, emotional journal entry (2-3 sentences) for this photo.
        
        Photo description: \(description)\(context)
        
        Write in first person, as if the person is capturing this precious moment in their journal.
        Make it heartfelt and meaningful.
        """
        
        return try await callOpenAI(prompt: prompt, maxTokens: 150)
    }
    
    func generateNotificationPrompt(recentEntries: [String]) async throws -> String {
        let entriesText = recentEntries.joined(separator: "\n\n")
        
        let prompt = """
        Based on these recent journal entries, create a gentle, encouraging notification prompt 
        (one short sentence) to encourage the user to journal today.
        
        Recent entries:
        \(entriesText)
        
        Make it personal, warm, and relevant to their recent thoughts.
        """
        
        return try await callOpenAI(prompt: prompt, maxTokens: 50)
    }
    
    private func callOpenAI(prompt: String, maxTokens: Int) async throws -> String {
        // Check if API key is configured
        guard apiKey != "YOUR_API_KEY_HERE" && !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key not configured. Please add your API key to use AI features."
        case .invalidURL:
            return "Invalid API URL"
        case .requestFailed:
            return "AI request failed. Please check your internet connection."
        case .invalidResponse:
            return "Invalid response from AI service"
        }
    }
}

// MARK: - AI Response Models
struct TextImprovementResponse: Codable {
    let success: Bool
    let versions: [String]
}

struct CaptionGenerationResponse: Codable {
    let success: Bool
    let caption: String
}



