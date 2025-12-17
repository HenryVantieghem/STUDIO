//
//  CacheManager.swift
//  STUDIO
//
//  High-performance caching layer for instant data access
//  Basel Afterdark Design System
//

import Foundation
import SwiftUI

// MARK: - Cache Manager

/// Thread-safe in-memory cache with TTL support
@Observable
@MainActor
final class CacheManager {

    // MARK: - Singleton

    static let shared = CacheManager()

    // MARK: - Cache Storage

    private var userCache: [UUID: CachedItem<User>] = [:]
    private var partyCache: [UUID: CachedItem<Party>] = [:]
    private var mediaCache: [UUID: CachedItem<[PartyMedia]>] = [:]
    private var commentsCache: [UUID: CachedItem<[PartyComment]>] = [:]
    private var statusCache: [UUID: CachedItem<[PartyStatus]>] = [:]
    private var feedCache: CachedItem<[Party]>?
    private var profileStatsCache: [UUID: CachedItem<ProfileStats>] = [:]

    // MARK: - TTL Configuration (seconds)

    private let userTTL: TimeInterval = 300        // 5 minutes
    private let partyTTL: TimeInterval = 60        // 1 minute
    private let mediaTTL: TimeInterval = 120       // 2 minutes
    private let commentsTTL: TimeInterval = 30     // 30 seconds
    private let statusTTL: TimeInterval = 30       // 30 seconds
    private let feedTTL: TimeInterval = 60         // 1 minute
    private let statsTTL: TimeInterval = 300       // 5 minutes

    // MARK: - Initialization

    private init() {}

    // MARK: - User Cache

    func getCachedUser(_ id: UUID) -> User? {
        guard let cached = userCache[id], !cached.isExpired else {
            userCache[id] = nil
            return nil
        }
        return cached.value
    }

    func cacheUser(_ user: User) {
        userCache[user.id] = CachedItem(value: user, ttl: userTTL)
    }

    func cacheUsers(_ users: [User]) {
        for user in users {
            cacheUser(user)
        }
    }

    // MARK: - Party Cache

    func getCachedParty(_ id: UUID) -> Party? {
        guard let cached = partyCache[id], !cached.isExpired else {
            partyCache[id] = nil
            return nil
        }
        return cached.value
    }

    func cacheParty(_ party: Party) {
        partyCache[party.id] = CachedItem(value: party, ttl: partyTTL)
    }

    func invalidateParty(_ id: UUID) {
        partyCache[id] = nil
    }

    // MARK: - Media Cache

    func getCachedMedia(_ partyId: UUID) -> [PartyMedia]? {
        guard let cached = mediaCache[partyId], !cached.isExpired else {
            mediaCache[partyId] = nil
            return nil
        }
        return cached.value
    }

    func cacheMedia(_ media: [PartyMedia], for partyId: UUID) {
        mediaCache[partyId] = CachedItem(value: media, ttl: mediaTTL)
    }

    func appendMedia(_ media: PartyMedia, for partyId: UUID) {
        if var existing = mediaCache[partyId]?.value {
            existing.insert(media, at: 0)
            mediaCache[partyId] = CachedItem(value: existing, ttl: mediaTTL)
        }
    }

    // MARK: - Comments Cache

    func getCachedComments(_ partyId: UUID) -> [PartyComment]? {
        guard let cached = commentsCache[partyId], !cached.isExpired else {
            commentsCache[partyId] = nil
            return nil
        }
        return cached.value
    }

    func cacheComments(_ comments: [PartyComment], for partyId: UUID) {
        commentsCache[partyId] = CachedItem(value: comments, ttl: commentsTTL)
    }

    func appendComment(_ comment: PartyComment, for partyId: UUID) {
        if var existing = commentsCache[partyId]?.value {
            existing.insert(comment, at: 0)
            commentsCache[partyId] = CachedItem(value: existing, ttl: commentsTTL)
        }
    }

    // MARK: - Status Cache

    func getCachedStatuses(_ partyId: UUID) -> [PartyStatus]? {
        guard let cached = statusCache[partyId], !cached.isExpired else {
            statusCache[partyId] = nil
            return nil
        }
        return cached.value
    }

    func cacheStatuses(_ statuses: [PartyStatus], for partyId: UUID) {
        statusCache[partyId] = CachedItem(value: statuses, ttl: statusTTL)
    }

    // MARK: - Feed Cache

    func getCachedFeed() -> [Party]? {
        guard let cached = feedCache, !cached.isExpired else {
            feedCache = nil
            return nil
        }
        return cached.value
    }

    func cacheFeed(_ parties: [Party]) {
        feedCache = CachedItem(value: parties, ttl: feedTTL)
    }

    func invalidateFeed() {
        feedCache = nil
    }

    // MARK: - Profile Stats Cache

    func getCachedProfileStats(_ userId: UUID) -> ProfileStats? {
        guard let cached = profileStatsCache[userId], !cached.isExpired else {
            profileStatsCache[userId] = nil
            return nil
        }
        return cached.value
    }

    func cacheProfileStats(_ stats: ProfileStats, for userId: UUID) {
        profileStatsCache[userId] = CachedItem(value: stats, ttl: statsTTL)
    }

    // MARK: - Clear All

    func clearAll() {
        userCache.removeAll()
        partyCache.removeAll()
        mediaCache.removeAll()
        commentsCache.removeAll()
        statusCache.removeAll()
        feedCache = nil
        profileStatsCache.removeAll()
    }

    func clearPartyData(_ partyId: UUID) {
        partyCache[partyId] = nil
        mediaCache[partyId] = nil
        commentsCache[partyId] = nil
        statusCache[partyId] = nil
    }
}

// MARK: - Cached Item

struct CachedItem<T> {
    let value: T
    let cachedAt: Date
    let ttl: TimeInterval

    init(value: T, ttl: TimeInterval) {
        self.value = value
        self.cachedAt = Date()
        self.ttl = ttl
    }

    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }
}

// MARK: - Profile Stats

struct ProfileStats: Sendable {
    let partiesHosted: Int
    let partiesAttended: Int
    let followersCount: Int
    let followingCount: Int
    let photosShared: Int
    let achievementsCount: Int
}

// MARK: - Prefetch Manager

/// Intelligently prefetches data for smooth scrolling
@Observable
@MainActor
final class PrefetchManager {

    static let shared = PrefetchManager()

    private var prefetchedPartyIds: Set<UUID> = []
    private var prefetchTasks: [UUID: Task<Void, Never>] = [:]

    private init() {}

    /// Prefetch party data when scrolling
    func prefetchParty(_ partyId: UUID) {
        guard !prefetchedPartyIds.contains(partyId) else { return }
        guard prefetchTasks[partyId] == nil else { return }

        prefetchTasks[partyId] = Task { [weak self] in
            // Check cache first
            if CacheManager.shared.getCachedParty(partyId) != nil {
                self?.prefetchedPartyIds.insert(partyId)
                return
            }

            // Fetch and cache
            do {
                let service = PartyService()
                let party = try await service.getParty(id: partyId)
                CacheManager.shared.cacheParty(party)
                self?.prefetchedPartyIds.insert(partyId)
            } catch {
                // Silently fail prefetch
            }

            self?.prefetchTasks[partyId] = nil
        }
    }

    /// Prefetch multiple parties
    func prefetchParties(_ partyIds: [UUID]) {
        for id in partyIds.prefix(5) {
            prefetchParty(id)
        }
    }

    /// Cancel all pending prefetches
    func cancelAll() {
        for task in prefetchTasks.values {
            task.cancel()
        }
        prefetchTasks.removeAll()
    }
}

// MARK: - Image Cache Manager

/// Fast image caching for avatars and media
@MainActor
final class ImageCacheManager {

    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()
    private var downloadTasks: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 100  // Max 100 images
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB
    }

    /// Get cached image
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    /// Cache image
    func setImage(_ image: UIImage, for url: URL) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    /// Download and cache image
    func downloadImage(from url: URL) async -> UIImage? {
        // Check cache first
        if let cached = image(for: url) {
            return cached
        }

        // Check for existing download
        if let existingTask = downloadTasks[url] {
            return await existingTask.value
        }

        // Start download
        let task = Task<UIImage?, Never> { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    self?.setImage(image, for: url)
                    return image
                }
            } catch {
                // Download failed
            }
            return nil
        }

        downloadTasks[url] = task
        let result = await task.value
        downloadTasks[url] = nil

        return result
    }

    /// Clear cache
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Optimized Data Loader

/// Batch loading with optimistic updates
@Observable
@MainActor
final class OptimizedDataLoader {

    static let shared = OptimizedDataLoader()

    private init() {}

    /// Load party with cache-first strategy
    func loadParty(_ id: UUID) async throws -> Party {
        // 1. Return cached immediately if available
        if let cached = CacheManager.shared.getCachedParty(id) {
            // Refresh in background
            Task {
                try? await refreshParty(id)
            }
            return cached
        }

        // 2. Fetch from network
        let service = PartyService()
        let party = try await service.getParty(id: id)

        // 3. Cache result
        CacheManager.shared.cacheParty(party)

        return party
    }

    /// Refresh party data in background
    func refreshParty(_ id: UUID) async throws {
        let service = PartyService()
        let party = try await service.getParty(id: id)
        CacheManager.shared.cacheParty(party)
    }

    /// Load feed with pagination
    func loadFeed(page: Int, pageSize: Int = 20) async throws -> [Party] {
        // Return cached for first page
        if page == 0, let cached = CacheManager.shared.getCachedFeed() {
            Task {
                try? await refreshFeed()
            }
            return cached
        }

        let service = FeedService()
        let parties = try await service.getFeed(limit: pageSize, offset: page * pageSize)

        if page == 0 {
            CacheManager.shared.cacheFeed(parties)
        }

        return parties
    }

    /// Refresh feed
    private func refreshFeed() async throws {
        let service = FeedService()
        let parties = try await service.getFeed(limit: 20, offset: 0)
        CacheManager.shared.cacheFeed(parties)
    }

    /// Optimistic comment add
    func addComment(partyId: UUID, content: String, currentUser: User) async throws -> PartyComment {
        // 1. Create optimistic comment
        let optimisticComment = PartyComment(
            id: UUID(),
            partyId: partyId,
            userId: currentUser.id,
            content: content,
            createdAt: Date(),
            user: currentUser
        )

        // 2. Add to cache immediately (optimistic)
        CacheManager.shared.appendComment(optimisticComment, for: partyId)

        // 3. Perform actual insert
        let service = SocialService()
        let actualComment = try await service.addComment(partyId: partyId, content: content)

        // 4. Update cache with actual comment
        CacheManager.shared.cacheComments(
            (CacheManager.shared.getCachedComments(partyId) ?? [])
                .filter { $0.id != optimisticComment.id } + [actualComment],
            for: partyId
        )

        return actualComment
    }
}

// MARK: - Debouncer

/// Debounce rapid user actions
actor Debouncer {
    private var task: Task<Void, Never>?
    private let delay: Duration

    init(delay: Duration = .milliseconds(300)) {
        self.delay = delay
    }

    func debounce(_ operation: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await operation()
        }
    }
}

// MARK: - Throttler

/// Throttle frequent operations
actor Throttler {
    private var lastExecution: Date?
    private let interval: TimeInterval

    init(interval: TimeInterval = 1.0) {
        self.interval = interval
    }

    func throttle(_ operation: @escaping () async -> Void) async {
        let now = Date()

        if let last = lastExecution, now.timeIntervalSince(last) < interval {
            return
        }

        lastExecution = now
        await operation()
    }
}
