import Foundation

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
