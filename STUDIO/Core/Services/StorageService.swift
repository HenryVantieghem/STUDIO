//
//  StorageService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import UIKit
@preconcurrency import AVFoundation
import Supabase

// MARK: - Storage Service

/// Storage service for file uploads - using @MainActor for Supabase SDK compatibility
@MainActor
final class StorageService {
    static let shared = StorageService()

    private init() {}

    // MARK: - Storage Buckets

    enum Bucket: String {
        case avatars = "avatars"
        case partyMedia = "party-media"
    }

    // MARK: - Upload Result

    struct UploadResult: Sendable {
        let path: String
        let publicUrl: String?
    }

    // MARK: - Avatar Upload

    func uploadAvatar(image: UIImage, userId: UUID) async throws -> UploadResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidData
        }

        let fileName = "\(userId.uuidString)/avatar.jpg"

        try await supabase.storage
            .from(Bucket.avatars.rawValue)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        let publicUrl = try supabase.storage
            .from(Bucket.avatars.rawValue)
            .getPublicURL(path: fileName)
            .absoluteString

        return UploadResult(path: fileName, publicUrl: publicUrl)
    }

    // MARK: - Party Cover Upload

    func uploadPartyCover(partyId: UUID, imageData: Data) async throws -> String {
        let fileName = "\(partyId.uuidString)/cover.jpg"

        try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        let publicUrl = try supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .getPublicURL(path: fileName)
            .absoluteString

        return publicUrl
    }

    // MARK: - Party Media Upload

    func uploadPartyMedia(
        partyId: UUID,
        image: UIImage,
        caption: String? = nil
    ) async throws -> PartyMedia {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw StorageError.invalidData
        }

        let userId = try await supabase.auth.session.user.id
        let fileName = "\(partyId.uuidString)/\(UUID().uuidString).jpg"

        // Upload to storage
        try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        // Get signed URL (private bucket)
        let signedUrl = try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .createSignedURL(path: fileName, expiresIn: 86400) // 24 hours
            .absoluteString

        // Create media record
        let media = PartyMediaInsert(
            partyId: partyId,
            userId: userId,
            mediaType: .photo,
            url: signedUrl,
            caption: caption
        )

        let inserted: PartyMedia = try await supabase
            .from("party_media")
            .insert(media)
            .select()
            .single()
            .execute()
            .value

        return inserted
    }

    func uploadPartyVideo(
        partyId: UUID,
        videoURL: URL,
        caption: String? = nil
    ) async throws -> PartyMedia {
        let videoData = try Data(contentsOf: videoURL)

        let userId = try await supabase.auth.session.user.id
        let fileName = "\(partyId.uuidString)/\(UUID().uuidString).mov"

        // Upload to storage
        try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .upload(
                fileName,
                data: videoData,
                options: FileOptions(contentType: "video/quicktime")
            )

        // Get signed URL
        let signedUrl = try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .createSignedURL(path: fileName, expiresIn: 86400) // 24 hours
            .absoluteString

        // Generate thumbnail
        let thumbnailUrl = try await generateAndUploadThumbnail(
            videoURL: videoURL,
            partyId: partyId
        )

        // Create media record
        let media = PartyMediaInsert(
            partyId: partyId,
            userId: userId,
            mediaType: .video,
            url: signedUrl,
            thumbnailUrl: thumbnailUrl,
            caption: caption
        )

        let inserted: PartyMedia = try await supabase
            .from("party_media")
            .insert(media)
            .select()
            .single()
            .execute()
            .value

        return inserted
    }

    // MARK: - Thumbnail Generation

    private func generateAndUploadThumbnail(
        videoURL: URL,
        partyId: UUID
    ) async throws -> String {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1, preferredTimescale: 60)

        // Use async thumbnail generation
        let cgImage = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
            imageGenerator.generateCGImageAsynchronously(for: time) { image, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: StorageError.thumbnailGenerationFailed)
                }
            }
        }

        let thumbnail = UIImage(cgImage: cgImage)

        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw StorageError.thumbnailGenerationFailed
        }

        let fileName = "\(partyId.uuidString)/thumb_\(UUID().uuidString).jpg"

        try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .upload(
                fileName,
                data: thumbnailData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let signedUrl = try await supabase.storage
            .from(Bucket.partyMedia.rawValue)
            .createSignedURL(path: fileName, expiresIn: 86400) // 24 hours
            .absoluteString

        return signedUrl
    }

    // MARK: - Delete Media

    func deleteMedia(path: String, bucket: Bucket = .partyMedia) async throws {
        try await supabase.storage
            .from(bucket.rawValue)
            .remove(paths: [path])
    }

    // MARK: - Refresh Signed URLs

    func refreshSignedUrl(path: String, bucket: Bucket = .partyMedia) async throws -> String {
        let signedUrl = try await supabase.storage
            .from(bucket.rawValue)
            .createSignedURL(path: path, expiresIn: 86400) // 24 hours
            .absoluteString

        return signedUrl
    }
}

// MARK: - Storage Error

enum StorageError: LocalizedError {
    case invalidData
    case uploadFailed
    case thumbnailGenerationFailed
    case urlGenerationFailed

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data for upload"
        case .uploadFailed:
            return "Failed to upload file"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .urlGenerationFailed:
            return "Failed to generate URL"
        }
    }
}

// MARK: - Party Media Insert

struct PartyMediaInsert: Encodable, Sendable {
    let partyId: UUID
    let userId: UUID
    let mediaType: MediaType
    let url: String
    var thumbnailUrl: String?
    var caption: String?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case userId = "user_id"
        case mediaType = "media_type"
        case url
        case thumbnailUrl = "thumbnail_url"
        case caption
    }
}
