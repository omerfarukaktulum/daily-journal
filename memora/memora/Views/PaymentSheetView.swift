import SwiftUI
import Stripe

struct PaymentSheetView: View {
    let clientSecret: String
    let onPaymentResult: (PaymentResult) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingPaymentForm = false
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvc = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Payment Details")
                        .font(.title2.bold())
                    
                    Text("Enter your payment information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Payment Form
                VStack(spacing: 15) {
                    // Card Number
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Card Number")
                            .font(.headline)
                        TextField("1234 5678 9012 3456", text: $cardNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    HStack(spacing: 15) {
                        // Expiry Date
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Expiry")
                                .font(.headline)
                            TextField("MM/YY", text: $expiryDate)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // CVC
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CVC")
                                .font(.headline)
                            TextField("123", text: $cvc)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                
                // Test Card Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Card Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("💳 Card: 4242 4242 4242 4242")
                    Text("📅 Expiry: Any future date (e.g., 12/25)")
                    Text("🔒 CVC: Any 3 digits (e.g., 123)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Pay Button
                Button(action: {
                    processPayment()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard.fill")
                        }
                        
                        Text(isLoading ? "Processing..." : "Pay Now")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
                .disabled(isLoading || cardNumber.isEmpty || expiryDate.isEmpty || cvc.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func processPayment() {
        isLoading = true
        errorMessage = nil
        
        // For demo purposes, we'll simulate a successful payment
        // In a real implementation, you would use Stripe's PaymentIntents API
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            onPaymentResult(.completed)
        }
    }
}

// MARK: - Payment Result Enum
enum PaymentResult {
    case completed
    case canceled
    case failed(Error)
}
