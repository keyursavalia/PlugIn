import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Profile Images

    func uploadProfileImage(userId: String, image: UIImage) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.imageCompressionFailed
        }

        // Create reference
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")

        // Upload
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await profileImagesRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await profileImagesRef.downloadURL()
        return downloadURL.absoluteString
    }

    func deleteProfileImage(userId: String) async throws {
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        try await profileImageRef.delete()
    }
}

enum StorageError: Error, LocalizedError {
    case imageCompressionFailed
    case uploadFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload image"
        case .deleteFailed:
            return "Failed to delete image"
        }
    }
}
