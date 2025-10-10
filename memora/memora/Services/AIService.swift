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
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Read API key from UserDefaults (where user saves it in Settings)
        // In production, should use Keychain for better security
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? 
                      ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? 
                      "YOUR_API_KEY_HERE"
    }
    
    func improveText(_ text: String) async throws -> [String] {
        let prompt = """
        You are a compassionate journaling assistant. The user has written a personal journal entry. 
        Please provide 2-3 improved versions that:
        - Preserve the user's authentic voice and emotions
        - Enhance clarity and flow
        - Keep the same meaning and tone
        - Make it more reflective and meaningful
        
        Original entry:
        "\(text)"
        
        Provide only the improved versions, separated by "---VERSION---", without any additional commentary.
        """
        
        let response = try await callOpenAI(prompt: prompt, maxTokens: 500)
        let versions = response.components(separatedBy: "---VERSION---")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return versions.isEmpty ? [text] : versions
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


