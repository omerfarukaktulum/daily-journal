import SwiftUI

struct PaymentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var stripeService = StripeService()
    
    let plan: PremiumPlan
    @State private var showingPaymentSheet = false
    @State private var paymentSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Complete Your Purchase")
                        .font(.title.bold())
                    
                    Text("Choose your payment method")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Plan Details
                VStack(spacing: 15) {
                    HStack {
                        Text("Plan")
                            .font(.headline)
                        Spacer()
                        Text(plan.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Price")
                            .font(.headline)
                        Spacer()
                        Text(plan.displayPrice)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Billing")
                            .font(.headline)
                        Spacer()
                        Text(plan.period)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let savings = plan.savings {
                        HStack {
                            Text("Savings")
                                .font(.headline)
                            Spacer()
                            Text(savings)
                                .font(.subheadline)
                                .foregroundColor(.green)
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
                
                // Payment Button
                Button(action: {
                    showingPaymentSheet = true
                }) {
                    HStack {
                        if stripeService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard.fill")
                        }
                        
                        Text(stripeService.isLoading ? "Processing..." : "Pay \(plan.displayPrice)")
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
                .disabled(stripeService.isLoading)
                .padding(.horizontal)
                
                // Test Card Information
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Test Payment Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Powered by Stripe")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💳 Test Card: 4242 4242 4242 4242")
                            .font(.title3.monospaced())
                            .foregroundColor(.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        
                        Text("📅 Expiry: Any future date (e.g., 12/25)")
                        Text("🔒 CVC: Any 3 digits (e.g., 123)")
                        Text("📧 Email: Any valid email")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Security notice
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Your payment is secured by Stripe's industry-leading security")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = stripeService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Security Notice
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Secure Payment")
                            .font(.subheadline.bold())
                    }
                    
                    Text("Your payment information is encrypted and secure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
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
            .onAppear {
                Task {
                    do {
                        try await stripeService.setupPayment(
                            amount: plan.price,
                            currency: "usd",
                            plan: plan.rawValue
                        )
                    } catch {
                        print("Error setting up payment: \(error)")
                    }
                }
            }
            .sheet(isPresented: $showingPaymentSheet) {
                if let paymentSheet = stripeService.paymentSheet {
                    PaymentSheetView(
                        paymentSheet: paymentSheet,
                        onPaymentResult: { result in
                            showingPaymentSheet = false
                            print("Payment result: \(result)")
                            switch result {
                            case .completed:
                                print("Payment completed successfully!")
                                paymentSuccess = true
                                appState.isPremiumUser = true
                                dismiss()
                            case .canceled:
                                print("Payment canceled by user")
                                // User canceled, do nothing
                                break
                            case .failed(let error):
                                print("Payment failed with error: \(error)")
                            }
                        }
                    )
                } else {
                    VStack {
                        Text("Setting up payment...")
                            .font(.headline)
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
            .onChange(of: paymentSuccess) { success in
                if success {
                    // Payment successful - dismiss immediately
                    dismiss()
                }
            }
        }
    }
}




#Preview {
    PaymentView(plan: .monthly)
        .environmentObject(AppState())
}