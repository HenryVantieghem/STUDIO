//
//  MediaService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Supabase
import UIKit

// MARK: - Media Service

/// Service for media storage and database operations
final class MediaService: Sendable {

    // Storage bucket names
    private let avatarsBucket = "avatars"
    private let partyMediaBucket = "party-media"

    // MARK: - Avatar Upload

    /// Upload user avatar
    func uploadAvatar(imageData: Data, userId: UUID) async throws -> String {
        let fileName = "\(userId.uuidString)/avatar.jpg"

        try await supabase.storage
            .from(avatarsBucket)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        let publicUrl = try supabase.storage
            .from(avatarsBucket)
            .getPublicURL(path: fileName)

        return publicUrl.absoluteString
    }

    /// Delete user avatar
    func deleteAvatar(userId: UUID) async throws {
        let fileName = "\(userId.uuidString)/avatar.jpg"

        try await supabase.storage
            .from(avatarsBucket)
            .remove(paths: [fileName])
    }

    // MARK: - Party Media Upload

    /// Upload party media (photo or video)
    func uploadPartyMedia(
        partyId: UUID,
        data: Data,
        mediaType: MediaType,
        caption: String? = nil
    ) async throws -> PartyMedia {
        _ = try await supabase.auth.session.user.id // Verify authenticated
        let mediaId = UUID()
        let fileExtension = mediaType == .photo ? "jpg" : "mp4"
        let contentType = mediaType == .photo ? "image/jpeg" : "video/mp4"
        let fileName = "\(partyId.uuidString)/\(mediaId.uuidString).\(fileExtension)"

        // Upload to storage
        try await supabase.storage
            .from(partyMediaBucket)
            .upload(
                fileName,
                data: data,
                options: FileOptions(contentType: contentType)
            )

        // Get public URL
        let publicUrl = try supabase.storage
            .from(partyMediaBucket)
            .getPublicURL(path: fileName)

        // Generate thumbnail for videos
        var thumbnailUrl: String? = nil
        if mediaType == .video {
            // Thumbnail generation would be handled by a Supabase Edge Function
            // For now, we'll use the same URL or generate client-side
            thumbnailUrl = publicUrl.absoluteString
        }

        // Create database record
        let request = CreateMediaRequest(
            partyId: partyId,
            mediaType: mediaType,
            url: publicUrl.absoluteString,
            thumbnailUrl: thumbnailUrl,
            caption: caption,
            duration: nil // Would be calculated for videos
        )

        let media: PartyMedia = try await supabase
            .from("party_media")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        return media
    }

    /// Delete party media
    func deletePartyMedia(mediaId: UUID, partyId: UUID) async throws {
        // Get media record to find file path
        let media: PartyMedia = try await supabase
            .from("party_media")
            .select()
            .eq("id", value: mediaId.uuidString)
            .single()
            .execute()
            .value

        // Extract file path from URL
        if let url = URL(string: media.url),
           let fileName = url.pathComponents.suffix(2).joined(separator: "/") as String? {
            // Delete from storage
            try await supabase.storage
                .from(partyMediaBucket)
                .remove(paths: [fileName])
        }

        // Delete database record
        try await supabase
            .from("party_media")
            .delete()
            .eq("id", value: mediaId.uuidString)
            .execute()
    }

    // MARK: - Get Party Media

    /// Get all media for a party
    func getPartyMedia(partyId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [PartyMedia] {
        let media: [PartyMedia] = try await supabase
            .from("party_media")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return media
    }

    /// Get media by user in a party
    func getUserMedia(partyId: UUID, userId: UUID) async throws -> [PartyMedia] {
        let media: [PartyMedia] = try await supabase
            .from("party_media")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return media
    }

    /// Get latest media preview for a party
    func getMediaPreview(partyId: UUID, count: Int = 4) async throws -> [PartyMedia] {
        let media: [PartyMedia] = try await supabase
            .from("party_media")
            .select()
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .limit(count)
            .execute()
            .value

        return media
    }

    // MARK: - Image Processing

    /// Compress image data for upload
    func compressImage(_ image: UIImage, maxSize: CGSize = CGSize(width: 1920, height: 1920), quality: CGFloat = 0.8) -> Data? {
        // Resize if needed
        let resized: UIImage
        if image.size.width > maxSize.width || image.size.height > maxSize.height {
            let ratio = min(maxSize.width / image.size.width, maxSize.height / image.size.height)
            let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resized = image
        }

        return resized.jpegData(compressionQuality: quality)
    }

    /// Create thumbnail from image
    func createThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        let aspectRatio = image.size.width / image.size.height
        var thumbnailSize = size

        if aspectRatio > 1 {
            thumbnailSize.height = size.width / aspectRatio
        } else {
            thumbnailSize.width = size.height * aspectRatio
        }

        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - Media Upload Progress

/// Track upload progress
@Observable
class MediaUploadProgress {
    var progress: Double = 0
    var isUploading: Bool = false
    var error: Error?
    var completedUrl: String?

    func reset() {
        progress = 0
        isUploading = false
        error = nil
        completedUrl = nil
    }
}
