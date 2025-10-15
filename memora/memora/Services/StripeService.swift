import Foundation
import Combine

@MainActor
class StripeService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let publishableKey = "pk_test_51QejagQBQrhHPXtCwr1r1MVXRwc3DTDQDl3a8jmrmuooFdekdft48GPXSArPN0zTfkjte3hXL5Ee3ChLNlFeVDBY00ao2NdQ3w"
    private let baseURL = "https://api.stripe.com/v1"
    
    // MARK: - Create Payment Intent (Client-side approach)
    func createPaymentIntent(amount: Int, currency: String = "usd") async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // For now, we'll create a mock payment intent since we need a backend
        // In production, this should call your backend server which uses the secret key
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Mock payment intent - in production, this would come from your backend
        return "pi_mock_\(UUID().uuidString)"
    }
    
    // MARK: - Confirm Payment (Mock implementation for now)
    func confirmPayment(clientSecret: String, paymentMethodId: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Simulate payment processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock successful payment - in production, this would call your backend
        // which would use the secret key to confirm the payment with Stripe
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
