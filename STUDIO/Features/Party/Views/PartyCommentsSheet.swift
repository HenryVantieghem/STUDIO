//
//  PartyCommentsSheet.swift
//  STUDIO
//
//  Instagram-style slidable comments sheet
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Comments Sheet

/// Instagram-style slidable comments sheet
struct PartyCommentsSheet: View {
    let partyId: UUID
    let comments: [PartyComment]
    var isLoading: Bool = false

    var onAddComment: ((String) -> Void)?
    var onLikeComment: ((UUID) -> Void)?

    @State private var commentText = ""
    @State private var replyingTo: PartyComment?
    @FocusState private var isCommentFocused: Bool

    // Quick reactions
    private let quickReactions = ["❤️", "🙌", "🔥", "👏", "😢", "😍", "😮", "😂"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader

            // Comments list or empty state
            if isLoading {
                loadingView
            } else if comments.isEmpty {
                emptyCommentsView
            } else {
                commentsList
            }

            // Quick reactions
            quickReactionsBar

            // Comment composer
            commentComposer
        }
        .background(Color.studioSurface)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Text("COMMENTS")
                .font(StudioTypography.headlineSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)

            Spacer()

            // Sort/filter button
            Button {
                // Sort options
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.studioMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            StudioLoadingIndicator(size: 24, color: .studioChrome)
            Text("LOADING COMMENTS")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyCommentsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.studioLine)

            VStack(spacing: 8) {
                Text("NO COMMENTS YET")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text("START THE CONVERSATION")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.6))
            }

            Spacer()
        }
    }

    // MARK: - Comments List

    private var commentsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(comments) { comment in
                    CommentRow(
                        comment: comment,
                        onLike: { onLikeComment?(comment.id) },
                        onReply: { replyingTo = comment }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Quick Reactions

    private var quickReactionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickReactions, id: \.self) { reaction in
                    Button {
                        commentText = reaction
                        submitComment()
                    } label: {
                        Text(reaction)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 36)
                            .background(Color.studioBlack)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 0.5)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.studioDeepBlack)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Comment Composer

    private var commentComposer: some View {
        VStack(spacing: 0) {
            // Replying to indicator
            if let replyingTo = replyingTo,
               let user = replyingTo.user {
                HStack(spacing: 8) {
                    Text("REPLYING TO")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)

                    Text("@\(user.username)")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioChrome)

                    Spacer()

                    Button {
                        self.replyingTo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.studioSurface)
            }

            // Input row
            HStack(spacing: 12) {
                // Current user avatar
                AvatarView(url: nil, size: .small)

                // Text field
                TextField("", text: $commentText, prompt: Text("Add a comment...")
                    .font(StudioTypography.bodySmall)
                    .foregroundStyle(Color.studioMuted))
                    .font(StudioTypography.bodySmall)
                    .foregroundStyle(Color.studioPrimary)
                    .focused($isCommentFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        submitComment()
                    }

                // Emoji picker button
                Button {
                    // Show emoji picker
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                }
                .buttonStyle(.plain)

                // Send button
                if !commentText.isEmpty {
                    Button {
                        submitComment()
                    } label: {
                        Text("POST")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioChrome)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.studioSurface)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.studioLine)
                    .frame(height: 0.5)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: commentText.isEmpty)
    }

    private func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onAddComment?(commentText)
        commentText = ""
        replyingTo = nil
    }
}

// MARK: - Comment Row

/// Individual comment row with user, content, and actions
struct CommentRow: View {
    let comment: PartyComment
    var onLike: (() -> Void)?
    var onReply: (() -> Void)?

    @State private var showReplies = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                AvatarView(
                    url: comment.user?.avatarUrl,
                    size: .medium
                )

                VStack(alignment: .leading, spacing: 6) {
                    // Username and time
                    HStack(spacing: 8) {
                        Text(comment.user?.username ?? "unknown")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingNormal)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.studioPrimary)

                        Text(formatTimeAgo(comment.createdAt))
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)

                        // Host badge
                        if isHost(comment.userId) {
                            Text("HOST")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.studioChrome)
                        }
                    }

                    // Comment content
                    Text(comment.content)
                        .font(StudioTypography.bodySmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            onLike?()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.system(size: 12, weight: .light))
                                Text("LIKE")
                                    .font(StudioTypography.labelSmall)
                            }
                            .foregroundStyle(Color.studioMuted)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onReply?()
                        } label: {
                            Text("REPLY")
                                .font(StudioTypography.labelSmall)
                                .foregroundStyle(Color.studioMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)

                    // View replies
                    if let replies = comment.replies, !replies.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showReplies.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(Color.studioLine)
                                    .frame(width: 24, height: 0.5)

                                Text(showReplies ? "HIDE REPLIES" : "VIEW \(replies.count) REPL\(replies.count == 1 ? "Y" : "IES")")
                                    .font(StudioTypography.labelSmall)
                                    .foregroundStyle(Color.studioMuted)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)

                        // Replies
                        if showReplies {
                            VStack(spacing: 0) {
                                ForEach(replies) { reply in
                                    ReplyRow(comment: reply)
                                }
                            }
                            .padding(.top, 8)
                            .transition(.opacity)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Like count
                VStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.studioMuted)

                    Text("80")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.studioLine.opacity(0.5))
                .frame(height: 0.5)
                .padding(.leading, 72)
        }
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func isHost(_ userId: UUID) -> Bool {
        // This would be checked against party hosts
        return false
    }
}

// MARK: - Reply Row

/// Compact reply row for nested comments
struct ReplyRow: View {
    let comment: PartyComment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(url: comment.user?.avatarUrl, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.user?.username ?? "unknown")
                        .font(StudioTypography.labelSmall)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)

                    Text(formatTimeAgo(comment.createdAt))
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }

                Text(comment.content)
                    .font(StudioTypography.bodySmall)
                    .foregroundStyle(Color.studioSecondary)
            }

            Spacer()
        }
        .padding(.leading, 44)
        .padding(.vertical, 8)
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Comments Sheet") {
    PartyCommentsSheet(
        partyId: UUID(),
        comments: MockData.partyComments,
        isLoading: false
    )
}

#Preview("Comments Sheet - Empty") {
    PartyCommentsSheet(
        partyId: UUID(),
        comments: [],
        isLoading: false
    )
}

#Preview("Comments Sheet - Loading") {
    PartyCommentsSheet(
        partyId: UUID(),
        comments: [],
        isLoading: true
    )
}
