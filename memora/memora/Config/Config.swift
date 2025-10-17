//
//  Config.swift
//  memora
//
//  Configuration management for different environments
//

import Foundation

struct Config {
    static let environment: AppEnvironment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    static var stripePublishableKey: String {
        switch environment {
        case .development:
            return "pk_test_51QejagQBQrhHPXtCwr1r1MVXRwc3DTDQDl3a8jmrmuooFdekdft48GPXSArPN0zTfkjte3hXL5Ee3ChLNlFeVDBY00ao2NdQ3w"
        case .production:
            return loadSecret(key: "STRIPE_PUBLISHABLE_KEY_LIVE") ?? "pk_live_YOUR_LIVE_PUBLISHABLE_KEY_HERE"
        }
    }
    
    static var backendURL: String {
        switch environment {
        case .development:
            return "http://localhost:3000"
        case .production:
            return loadSecret(key: "BACKEND_URL_PRODUCTION") ?? "https://your-backend-domain.com"
        }
    }
    
    // MARK: - Private Helper
    private static func loadSecret(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        return plist[key] as? String
    }
}

enum AppEnvironment {
    case development
    case production
}
