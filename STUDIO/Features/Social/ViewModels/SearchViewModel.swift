//
//  SearchViewModel.swift
//  STUDIO
//
//  User search state management with @Observable
//

import Foundation
import SwiftUI
import Combine

// MARK: - Search View Model

@Observable
@MainActor
final class SearchViewModel {
    // MARK: - State

    var searchText = ""
    var searchResults: [UserSearchResult] = []
    var suggestedUsers: [UserSearchResult] = []
    var isSearching = false
    var isLoadingSuggestions = false
    var error: Error?
    var showError = false

    // MARK: - Services

    private let followService = FollowService()

    // MARK: - Debounce

    private var searchTask: Task<Void, Never>?

    // MARK: - Search

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            guard !Task.isCancelled else { return }

            isSearching = true

            do {
                searchResults = try await followService.searchUsers(query: query)
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    showError = true
                }
            }

            isSearching = false
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        searchTask?.cancel()
    }

    // MARK: - Suggestions

    func loadSuggestions() async {
        guard suggestedUsers.isEmpty else { return }
        isLoadingSuggestions = true

        do {
            suggestedUsers = try await followService.getSuggestedUsers(limit: 15)
        } catch {
            // Silently fail
        }

        isLoadingSuggestions = false
    }

    // MARK: - Follow Actions

    func toggleFollow(user: UserSearchResult) async {
        // Find and update in search results
        if let index = searchResults.firstIndex(where: { $0.id == user.id }) {
            let currentlyFollowing = searchResults[index].isFollowing

            do {
                if currentlyFollowing {
                    try await followService.unfollowUser(userId: user.id)
                    searchResults[index].isFollowing = false
                } else {
                    try await followService.followUser(userId: user.id)
                    searchResults[index].isFollowing = true
                }
            } catch {
                self.error = error
                showError = true
            }
        }

        // Also update in suggested users
        if let index = suggestedUsers.firstIndex(where: { $0.id == user.id }) {
            let currentlyFollowing = suggestedUsers[index].isFollowing

            do {
                if currentlyFollowing {
                    try await followService.unfollowUser(userId: user.id)
                    suggestedUsers[index].isFollowing = false
                } else {
                    try await followService.followUser(userId: user.id)
                    suggestedUsers[index].isFollowing = true
                }
            } catch {
                // Already handled above
            }
        }
    }

    // MARK: - Computed

    var hasResults: Bool {
        !searchResults.isEmpty
    }

    var isShowingSuggestions: Bool {
        searchText.isEmpty && !suggestedUsers.isEmpty
    }
}
