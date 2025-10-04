//
//  GalleryManager.swift
//  Focus
//
//  Created by Kaider on 04.10.2025.
//

import Foundation
import Photos
import UIKit

/// Ошибки, связанные с сохранением в Фото
enum GalleryError: LocalizedError {
    case accessDenied
    case noImageData
    case saveFailed
    case albumCreationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .accessDenied:        return "Нет доступа к библиотеке Фото."
        case .noImageData:         return "Не удалось получить данные изображения."
        case .saveFailed:          return "Ошибка сохранения снимка."
        case .albumCreationFailed: return "Не удалось создать альбом."
        case .unknown:             return "Неизвестная ошибка при сохранении."
        }
    }
}

/// Менеджер работы с фотогалереей: доступ и сохранение в Фото (в общий каталог или в альбом)
final class GalleryManager {

    /// Необязательное имя пользовательского альбома (например, “Focus”).
    /// Если `nil`, сохраняем в «Недавние» без привязки к альбому.
    private let albumTitle: String?

    init(albumTitle: String? = "Focus") {
        self.albumTitle = albumTitle
    }

    // MARK: - Публичное API

    /// Сохранить фотографию по `Data` (HEIC/JPEG). Создаст альбом при необходимости.
    func savePhotoData(_ data: Data,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        requestAddOnlyAccess { [weak self] granted in
            guard granted else {
                completion(.failure(GalleryError.accessDenied))
                return
            }
            guard let self else { return }

            if let albumTitle = self.albumTitle {
                self.ensureAlbum(named: albumTitle) { result in
                    switch result {
                    case .failure(let err):
                        completion(.failure(err))
                    case .success(let collection):
                        self.save(data: data, to: collection, completion: completion)
                    }
                }
            } else {
                self.save(data: data, to: nil, completion: completion)
            }
        }
    }

    /// Сохранить UIImage (будет перекодирован в JPEG с качеством 0.95)
    func saveUIImage(_ image: UIImage,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.95) else {
            completion(.failure(GalleryError.noImageData))
            return
        }
        savePhotoData(data, completion: completion)
    }

    // MARK: - Приватные

    private func requestAddOnlyAccess(_ completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        @unknown default:
            completion(false)
        }
    }

    private func ensureAlbum(named title: String,
                             completion: @escaping (Result<PHAssetCollection, Error>) -> Void) {
        if let existing = fetchAlbum(named: title) {
            completion(.success(existing))
            return
        }

        var placeholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = request.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard success,
                  let ph = placeholder,
                  let collection = self.fetchCollection(forLocalIdentifier: ph.localIdentifier)
            else {
                completion(.failure(GalleryError.albumCreationFailed))
                return
            }
            completion(.success(collection))
        })
    }

    private func fetchAlbum(named title: String) -> PHAssetCollection? {
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var result: PHAssetCollection?
        fetch.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == title {
                result = collection
                stop.pointee = true
            }
        }
        return result
    }

    private func fetchCollection(forLocalIdentifier id: String) -> PHAssetCollection? {
        let fetch = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
        return fetch.firstObject
    }

    private func save(data: Data,
                      to collection: PHAssetCollection?,
                      completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)

            if let collection = collection,
               let changeRequest = PHAssetCollectionChangeRequest(for: collection),
               let placeholder = creationRequest.placeholderForCreatedAsset {
                let fastEnumeration = NSArray(object: placeholder)
                changeRequest.addAssets(fastEnumeration)
            }
        }, completionHandler: { success, error in
            if let error = error {
                completion(.failure(error))
            } else if !success {
                completion(.failure(GalleryError.saveFailed))
            } else {
                completion(.success(()))
            }
        })
    }
}
