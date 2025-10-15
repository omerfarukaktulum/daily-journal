import Foundation
import Combine

@MainActor
class StripeService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Create Payment Intent (Mock Implementation)
    func createPaymentIntent(amount: Int, currency: String = "usd") async throws -> String {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        defer { isLoading = false }
        
        // Mock successful payment intent creation
        return "pi_mock_\(UUID().uuidString)"
    }
    
    // MARK: - Confirm Payment (Mock Implementation)
    func confirmPayment(clientSecret: String, paymentMethodId: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        defer { isLoading = false }
        
        // Mock successful payment confirmation
        // In a real implementation, this would call Stripe's API
        return true
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
