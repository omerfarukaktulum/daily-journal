import Foundation
import Combine

@MainActor
class StripeService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let publishableKey: String
    private let baseURL = "https://api.stripe.com/v1"
    
    init() {
        // In production, use your actual Stripe publishable key
        // For now, using test key - replace with your actual key
        self.publishableKey = "pk_test_your_stripe_publishable_key_here"
    }
    
    // MARK: - Create Payment Intent
    func createPaymentIntent(amount: Int, currency: String = "usd") async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/payment_intents") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "amount=\(amount)&currency=\(currency)&automatic_payment_methods[enabled]=true"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StripeError.requestFailed
        }
        
        let paymentIntent = try JSONDecoder().decode(StripePaymentIntent.self, from: data)
        return paymentIntent.clientSecret
    }
    
    // MARK: - Confirm Payment
    func confirmPayment(clientSecret: String, paymentMethodId: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/payment_intents/\(clientSecret)/confirm") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "payment_method=\(paymentMethodId)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StripeError.paymentFailed
        }
        
        let result = try JSONDecoder().decode(StripePaymentResult.self, from: data)
        return result.status == "succeeded"
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
    case requestFailed
    case paymentFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .paymentFailed:
            return "Payment failed"
        case .invalidResponse:
            return "Invalid response"
        }
    }
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
