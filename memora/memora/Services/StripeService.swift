import Foundation
import Combine

@MainActor
class StripeService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let publishableKey = "pk_test_51QejagQBQrhHPXtCwr1r1MVXRwc3DTDQDl3a8jmrmuooFdekdft48GPXSArPN0zTfkjte3hXL5Ee3ChLNlFeVDBY00ao2NdQ3w"
    private let backendURL = "http://localhost:3000" // Change to your deployed backend URL
    
    // MARK: - Create Payment Intent (Real Backend Implementation)
    func createPaymentIntent(amount: Int, currency: String = "usd", plan: String = "monthly") async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(backendURL)/api/create-payment-intent") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "amount": amount,
            "currency": currency,
            "plan": plan
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorData = try JSONDecoder().decode(BackendErrorResponse.self, from: data)
            throw StripeError.requestFailed(errorData.error)
        }
        
        let result = try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
        return result.clientSecret
    }
    
    // MARK: - Confirm Payment (Real Backend Implementation)
    func confirmPayment(clientSecret: String, paymentMethodId: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(backendURL)/api/confirm-payment") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "paymentIntentId": clientSecret,
            "paymentMethodId": paymentMethodId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorData = try JSONDecoder().decode(BackendErrorResponse.self, from: data)
            throw StripeError.paymentFailed(errorData.error)
        }
        
        let result = try JSONDecoder().decode(PaymentConfirmationResponse.self, from: data)
        return result.success && result.status == "succeeded"
    }
}

// MARK: - Stripe Models
struct StripePaymentIntent: Codable {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: String
}

struct StripePaymentResult: Codable {
    let id: String
    let status: String
    let amount: Int
    let currency: String
}

enum StripeError: LocalizedError {
    case invalidURL
    case requestFailed(String)
    case paymentFailed(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}

struct StripeErrorResponse: Codable {
    let error: StripeErrorDetail
}

struct StripeErrorDetail: Codable {
    let message: String
    let type: String
}

// MARK: - Backend Response Models
struct PaymentIntentResponse: Codable {
    let success: Bool
    let clientSecret: String
    let paymentIntentId: String
}

struct PaymentConfirmationResponse: Codable {
    let success: Bool
    let status: String
    let paymentIntentId: String
}

struct BackendErrorResponse: Codable {
    let success: Bool
    let error: String
}

// MARK: - Premium Plans
enum PremiumPlan: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var price: Int {
        switch self {
        case .monthly:
            return 499 // $4.99 in cents
        case .yearly:
            return 3999 // $39.99 in cents
        }
    }
    
    var displayPrice: String {
        switch self {
        case .monthly:
            return "$4.99"
        case .yearly:
            return "$39.99"
        }
    }
    
    var period: String {
        switch self {
        case .monthly:
            return "per month"
        case .yearly:
            return "per year"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly:
            return nil
        case .yearly:
            return "Save 33%"
        }
    }
}
