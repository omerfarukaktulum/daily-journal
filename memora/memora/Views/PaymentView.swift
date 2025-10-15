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
            .sheet(isPresented: $showingPaymentSheet) {
                StripePaymentSheet(
                    plan: plan,
                    onPaymentSuccess: {
                        paymentSuccess = true
                        appState.isPremiumUser = true
                        dismiss()
                    }
                )
            }
            .alert("Payment Successful!", isPresented: $paymentSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Welcome to Memora Premium! You now have access to all premium features.")
            }
        }
    }
}

struct StripePaymentSheet: View {
    let plan: PremiumPlan
    let onPaymentSuccess: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var stripeService = StripeService()
    @State private var clientSecret: String?
    @State private var showingPaymentMethod = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let clientSecret = clientSecret {
                    // Simplified payment form for demo
                    VStack(spacing: 20) {
                        Text("Payment Method")
                            .font(.title2.bold())
                        
                        // Real Stripe payment form
                        VStack(spacing: 15) {
                            TextField("Card Number", text: .constant("4242 4242 4242 4242"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                            
                            HStack {
                                TextField("MM/YY", text: .constant("12/25"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                
                                TextField("CVC", text: .constant("123"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        
                        Text("Demo Mode - Backend integration required for real payments")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Real Stripe payment processing
                            Task {
                                do {
                                    let success = try await stripeService.confirmPayment(
                                        clientSecret: clientSecret,
                                        paymentMethodId: "pm_card_visa" // Stripe test payment method
                                    )
                                    if success {
                                        onPaymentSuccess()
                                    }
                                } catch {
                                    print("Payment error: \(error)")
                                }
                            }
                        }) {
                            Text("Complete Payment (Demo)")
                                .font(.headline)
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
                    }
                } else {
                    ProgressView("Setting up payment...")
                        .onAppear {
                            Task {
                                do {
                                    clientSecret = try await stripeService.createPaymentIntent(
                                        amount: plan.price,
                                        currency: "usd"
                                    )
                                } catch {
                                    print("Error creating payment intent: \(error)")
                                }
                            }
                        }
                }
                
                Spacer()
            }
            .padding()
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
}

#Preview {
    PaymentView(plan: .monthly)
        .environmentObject(AppState())
}
