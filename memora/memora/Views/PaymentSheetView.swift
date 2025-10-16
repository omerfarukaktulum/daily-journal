import SwiftUI
import Stripe
import StripePaymentSheet

struct PaymentSheetView: View {
    let paymentSheet: PaymentSheet
    let onPaymentResult: (PaymentResult) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingPaymentSheet = false
    
    var body: some View {
        VStack {
            if showingPaymentSheet {
                PaymentSheetWrapper(
                    paymentSheet: paymentSheet,
                    onPaymentResult: { result in
                        showingPaymentSheet = false
                        onPaymentResult(result)
                    }
                )
            } else {
                VStack(spacing: 20) {
                    ProgressView("Preparing payment...")
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingPaymentSheet = true
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
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

struct PaymentSheetWrapper: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let onPaymentResult: (PaymentResult) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        DispatchQueue.main.async {
            paymentSheet.present(from: viewController) { result in
                onPaymentResult(result)
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Payment Result Enum
enum PaymentResult {
    case completed
    case canceled
    case failed(Error)
}
