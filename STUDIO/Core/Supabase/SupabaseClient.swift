//
//  SupabaseClient.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Supabase

/// Global Supabase client singleton
let supabase = SupabaseClient(
    supabaseURL: URL(string: SupabaseConfig.url)!,
    supabaseKey: SupabaseConfig.anonKey
)
