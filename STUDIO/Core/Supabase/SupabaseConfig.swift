//
//  SupabaseConfig.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation

/// Supabase configuration loaded from Secrets.plist
enum SupabaseConfig {
    /// Load secrets from Secrets.plist
    private static var secrets: [String: Any] {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Secrets.plist not found. Please create it with SUPABASE_URL and SUPABASE_ANON_KEY.")
        }
        return dict
    }

    /// Your Supabase project URL
    static var url: String {
        guard let url = secrets["SUPABASE_URL"] as? String, !url.isEmpty else {
            fatalError("SUPABASE_URL not found in Secrets.plist")
        }
        return url
    }

    /// Your Supabase anon/public key
    static var anonKey: String {
        guard let key = secrets["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not found in Secrets.plist")
        }
        return key
    }

    /// Validate configuration is set
    static var isConfigured: Bool {
        !url.isEmpty && !anonKey.isEmpty
    }
}
