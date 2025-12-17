//
//  SlidableCardsView.swift
//  STUDIO
//
//  Instagram-style slidable cards for comments and status updates
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Card Item Protocol

protocol SlidableCardItem: Identifiable, Hashable {
    var cardId: UUID { get }
    var cardTimestamp: Date { get }
    var cardUserId: UUID { get }
}

// MARK: - Comment Card Model

struct CommentCard: SlidableCardItem, Codable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let content: String
    let createdAt: Date
    var likeCount: Int
    var isLiked: Bool
    var user: User?

    var cardId: UUID { id }
    var cardTimestamp: Date { createdAt }
    var cardUserId: UUID { userId }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CommentCard, rhs: CommentCard) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Status Card Model

struct StatusCard: SlidableCardItem, Codable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let statusType: StatusType
    let level: Int
    let message: String?
    let emoji: String?
    let createdAt: Date
    var user: User?

    var cardId: UUID { id }
    var cardTimestamp: Date { createdAt }
    var cardUserId: UUID { userId }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StatusCard, rhs: StatusCard) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Slidable Cards Container

struct SlidableCardsView: View {
    let partyId: UUID
    @State private var comments: [CommentCard] = []
    @State private var statuses: [StatusCard] = []
    @State private var currentIndex = 0
    @State private var cardOffset: CGFloat = 0
    @State private var selectedTab: CardTab = .all
    @State private var showAddComment = false
    @State private var isLoading = false

    enum CardTab: String, CaseIterable {
        case all = "ALL"
        case comments = "COMMENTS"
        case statuses = "STATUSES"
    }

    private var allCards: [any SlidableCardItem] {
        let combined: [any SlidableCardItem] = comments + statuses
        return combined.sorted { $0.cardTimestamp > $1.cardTimestamp }
    }

    private var filteredCards: [any SlidableCardItem] {
        switch selectedTab {
        case .all:
            return allCards
        case .comments:
            return comments.sorted { $0.createdAt > $1.createdAt }
        case .statuses:
            return statuses.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector

            // Card count indicator
            if !filteredCards.isEmpty {
                cardIndicator
            }

            // Slidable cards
            if filteredCards.isEmpty {
                emptyState
            } else {
                cardStack
            }

            // Action buttons
            actionBar
        }
        .background(Color.studioBlack)
        .sheet(isPresented: $showAddComment) {
            AddCommentSheet(partyId: partyId) { content in
                addComment(content: content)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
        .task {
            await loadCards()
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CardTab.allCases, id: \.self) { tab in
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                        currentIndex = 0
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(selectedTab == tab ? Color.studioChrome : Color.studioMuted)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.studioChrome : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Card Indicator

    private var cardIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(filteredCards.count, 10), id: \.self) { index in
                Rectangle()
                    .fill(index == currentIndex ? Color.studioChrome : Color.studioLine)
                    .frame(width: index == currentIndex ? 16 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }

            if filteredCards.count > 10 {
                Text("+\(filteredCards.count - 10)")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioMuted)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(filteredCards.enumerated().prefix(5).reversed()), id: \.element.cardId) { index, card in
                    cardView(for: card, at: index, width: geometry.size.width)
                        .offset(x: index == currentIndex ? cardOffset : 0)
                        .scaleEffect(scaleForCard(at: index))
                        .offset(y: offsetForCard(at: index))
                        .opacity(opacityForCard(at: index))
                        .zIndex(Double(filteredCards.count - index))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        cardOffset = value.translation.width
                    }
                    .onEnded { value in
                        handleSwipe(value: value, width: geometry.size.width)
                    }
            )
        }
        .frame(height: 320)
    }

    @ViewBuilder
    private func cardView(for card: any SlidableCardItem, at index: Int, width: CGFloat) -> some View {
        if let comment = card as? CommentCard {
            CommentCardView(comment: comment, onLike: {
                likeComment(comment)
            })
            .frame(width: width - 48)
        } else if let status = card as? StatusCard {
            StatusCardView(status: status)
                .frame(width: width - 48)
        }
    }

    private func scaleForCard(at index: Int) -> CGFloat {
        let diff = index - currentIndex
        return max(0.85, 1 - CGFloat(abs(diff)) * 0.05)
    }

    private func offsetForCard(at index: Int) -> CGFloat {
        let diff = index - currentIndex
        return CGFloat(diff) * 8
    }

    private func opacityForCard(at index: Int) -> CGFloat {
        let diff = abs(index - currentIndex)
        return max(0.3, 1 - CGFloat(diff) * 0.2)
    }

    private func handleSwipe(value: DragGesture.Value, width: CGFloat) {
        let threshold: CGFloat = width * 0.25

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if value.translation.width < -threshold && currentIndex < filteredCards.count - 1 {
                // Swipe left - next card
                HapticManager.shared.impact(.light)
                currentIndex += 1
            } else if value.translation.width > threshold && currentIndex > 0 {
                // Swipe right - previous card
                HapticManager.shared.impact(.light)
                currentIndex -= 1
            }
            cardOffset = 0
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            SkeuomorphicEmoji(
                emoji: "💬",
                size: .large,
                showGlow: false,
                animatePulse: false
            )

            Text("NO ACTIVITY YET")
                .font(StudioTypography.headlineMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)

            Text("BE THE FIRST TO SHARE")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 16) {
            // Add comment button
            Button {
                HapticManager.shared.impact(.medium)
                showAddComment = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .light))
                    Text("ADD COMMENT")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                }
                .foregroundStyle(Color.studioBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.studioChrome)
            }
            .buttonStyle(.plain)

            Spacer()

            // Navigation arrows
            HStack(spacing: 8) {
                Button {
                    if currentIndex > 0 {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            currentIndex -= 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(currentIndex > 0 ? Color.studioChrome : Color.studioLine)
                        .frame(width: 44, height: 44)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(currentIndex == 0)

                Button {
                    if currentIndex < filteredCards.count - 1 {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            currentIndex += 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(currentIndex < filteredCards.count - 1 ? Color.studioChrome : Color.studioLine)
                        .frame(width: 44, height: 44)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(currentIndex >= filteredCards.count - 1)
            }
        }
        .padding(16)
        .background(Color.studioDeepBlack)
    }

    // MARK: - Data Loading

    private func loadCards() async {
        isLoading = true
        // TODO: Load from Supabase
        // Placeholder data
        comments = [
            CommentCard(
                id: UUID(),
                partyId: partyId,
                userId: UUID(),
                content: "THIS PARTY IS INSANE 🔥",
                createdAt: Date(),
                likeCount: 12,
                isLiked: false,
                user: nil
            ),
            CommentCard(
                id: UUID(),
                partyId: partyId,
                userId: UUID(),
                content: "WHERE IS EVERYONE AT?",
                createdAt: Date().addingTimeInterval(-300),
                likeCount: 5,
                isLiked: true,
                user: nil
            )
        ]

        statuses = [
            StatusCard(
                id: UUID(),
                partyId: partyId,
                userId: UUID(),
                statusType: .drunkMeter,
                level: 4,
                message: nil,
                emoji: "🍺",
                createdAt: Date().addingTimeInterval(-120),
                user: nil
            ),
            StatusCard(
                id: UUID(),
                partyId: partyId,
                userId: UUID(),
                statusType: .vibeCheck,
                level: 5,
                message: "LEGENDARY VIBES",
                emoji: "✨",
                createdAt: Date().addingTimeInterval(-600),
                user: nil
            )
        ]
        isLoading = false
    }

    private func addComment(content: String) {
        let newComment = CommentCard(
            id: UUID(),
            partyId: partyId,
            userId: UUID(), // TODO: Get current user ID
            content: content,
            createdAt: Date(),
            likeCount: 0,
            isLiked: false,
            user: nil
        )
        comments.insert(newComment, at: 0)
        currentIndex = 0
        HapticManager.shared.notification(.success)
    }

    private func likeComment(_ comment: CommentCard) {
        if let index = comments.firstIndex(where: { $0.id == comment.id }) {
            comments[index].isLiked.toggle()
            comments[index].likeCount += comments[index].isLiked ? 1 : -1
            HapticManager.shared.impact(.light)
        }
    }
}

// MARK: - Comment Card View

struct CommentCardView: View {
    let comment: CommentCard
    var onLike: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User header
            HStack(spacing: 12) {
                AvatarView(url: comment.user?.avatarUrl, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.user?.displayName?.uppercased() ?? "ANONYMOUS")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text(timeAgo(from: comment.createdAt))
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                // Comment type badge
                Text("💬")
                    .font(.system(size: 20))
            }

            // Comment content
            Text(comment.content)
                .font(StudioTypography.bodyLarge)
                .foregroundStyle(Color.studioPrimary)
                .lineLimit(4)

            // Actions
            HStack(spacing: 24) {
                // Like button
                Button {
                    onLike?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(comment.isLiked ? Color.studioError : Color.studioMuted)

                        Text("\(comment.likeCount)")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                    }
                }
                .buttonStyle(.plain)

                // Reply button
                Button {
                    HapticManager.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.system(size: 14, weight: .light))
                        Text("REPLY")
                            .font(StudioTypography.labelSmall)
                    }
                    .foregroundStyle(Color.studioMuted)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(20)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 2)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)

        if seconds < 60 {
            return "JUST NOW"
        } else if seconds < 3600 {
            let mins = seconds / 60
            return "\(mins)M AGO"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)H AGO"
        } else {
            let days = seconds / 86400
            return "\(days)D AGO"
        }
    }
}

// MARK: - Status Card View

struct StatusCardView: View {
    let status: StatusCard

    var body: some View {
        VStack(spacing: 20) {
            // User header
            HStack(spacing: 12) {
                AvatarView(url: status.user?.avatarUrl, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.user?.displayName?.uppercased() ?? "ANONYMOUS")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text(timeAgo(from: status.createdAt))
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                // Status type badge
                Text(status.statusType.emoji)
                    .font(.system(size: 20))
            }

            // Status visualization
            VStack(spacing: 12) {
                // Large emoji
                SkeuomorphicEmoji(
                    emoji: status.emoji ?? status.statusType.emoji,
                    size: .xlarge,
                    showGlow: true,
                    animatePulse: status.level >= 4
                )

                // Status type label
                Text(status.statusType.label)
                    .font(StudioTypography.headlineMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioChrome)

                // Level indicator
                EmojiLevelIndicator(
                    level: status.level,
                    maxLevel: 5,
                    emoji: status.statusType.emoji
                )

                // Optional message
                if let message = status.message {
                    Text(message)
                        .font(StudioTypography.bodyMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(20)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(statusBorderColor, lineWidth: 2)
        }
    }

    private var statusBorderColor: Color {
        switch status.level {
        case 5: return Color.studioChrome
        case 4: return Color.studioChrome.opacity(0.7)
        default: return Color.studioLine
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)

        if seconds < 60 {
            return "JUST NOW"
        } else if seconds < 3600 {
            let mins = seconds / 60
            return "\(mins)M AGO"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)H AGO"
        } else {
            let days = seconds / 86400
            return "\(days)D AGO"
        }
    }
}

// MARK: - Add Comment Sheet

struct AddCommentSheet: View {
    let partyId: UUID
    var onSubmit: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR COMMENT")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    TextField("", text: $commentText, prompt: Text("What's happening?")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted), axis: .vertical)
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...6)
                        .focused($isFocused)
                        .padding()
                        .background(Color.studioDeepBlack)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 1)
                        }
                }
                .padding(.horizontal, 16)

                // Character count
                HStack {
                    Spacer()
                    Text("\(commentText.count)/200")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(commentText.count > 200 ? Color.studioError : Color.studioMuted)
                }
                .padding(.horizontal, 16)

                // Quick reactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("QUICK REACTIONS")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickReactions, id: \.self) { reaction in
                                Button {
                                    HapticManager.shared.impact(.light)
                                    commentText += " \(reaction)"
                                } label: {
                                    Text(reaction)
                                        .font(.system(size: 24))
                                        .padding(8)
                                        .background(Color.studioDeepBlack)
                                        .overlay {
                                            Rectangle()
                                                .stroke(Color.studioLine, lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Submit button
                Button {
                    guard !commentText.isEmpty && commentText.count <= 200 else { return }
                    onSubmit?(commentText)
                    dismiss()
                } label: {
                    Text("POST COMMENT")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(canSubmit ? Color.studioBlack : Color.studioMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canSubmit ? Color.studioChrome : Color.studioSurface)
                        .overlay {
                            if !canSubmit {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .padding(.top, 20)
            .background(Color.studioSurface)
            .navigationTitle("ADD COMMENT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioMuted)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private var canSubmit: Bool {
        !commentText.isEmpty && commentText.count <= 200
    }

    private var quickReactions: [String] {
        ["🔥", "🎉", "💀", "😭", "🙌", "💯", "⚡️", "🍻"]
    }
}

// MARK: - Preview

#Preview("Slidable Cards") {
    SlidableCardsView(partyId: UUID())
}

#Preview("Comment Card") {
    CommentCardView(
        comment: CommentCard(
            id: UUID(),
            partyId: UUID(),
            userId: UUID(),
            content: "THIS PARTY IS ABSOLUTELY INSANE RIGHT NOW 🔥🔥🔥",
            createdAt: Date(),
            likeCount: 24,
            isLiked: true,
            user: nil
        )
    )
    .padding()
    .background(Color.studioBlack)
}

#Preview("Status Card") {
    StatusCardView(
        status: StatusCard(
            id: UUID(),
            partyId: UUID(),
            userId: UUID(),
            statusType: .vibeCheck,
            level: 5,
            message: "LEGENDARY NIGHT",
            emoji: "✨",
            createdAt: Date(),
            user: nil
        )
    )
    .padding()
    .background(Color.studioBlack)
}
