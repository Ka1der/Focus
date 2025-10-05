//
//  CameraView.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import AVFoundation
import SwiftUI

final class CameraView: NSObject, ObservableObject {

    // MARK: - Session & Queues
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "focus.camera.session.queue")

    // MARK: - Managers
    private lazy var cameraManager = CameraManager(session: session, sessionQueue: sessionQueue)
    private(set) var focusManager: FocusManager?
    @Published private(set) var activeBackModule: CameraManager.BackModule = .wide

    // MARK: - Outputs
    private let photoOutput = AVCapturePhotoOutput()

    // MARK: - Storage
    private let gallery: GalleryManager = GalleryManager(albumTitle: "Focus")

    // MARK: - State
    @Published var lastSaveError: Error?

    // MARK: - Init
    override init() {
        super.init()
        
        cameraManager.onBackModuleChange = { [weak self] module in
                   self?.activeBackModule = module
               }
        setupSession()
    }

    // MARK: - Public API (для UI)

    func getSession() -> AVCaptureSession { session }

    /// Фокус из точки слоя превью (см. CameraPreview callback)
    func focus(fromLayerPoint layerPoint: CGPoint, in previewLayer: AVCaptureVideoPreviewLayer) {
        focusManager?.focus(fromLayerPoint: layerPoint, in: previewLayer)
    }

    /// Съёмка фото
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        // На iOS 16 используем maxPhotoDimensions вместо устаревших флагов
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        settings.flashMode = .off

        sessionQueue.async {
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Прокси для кнопок выбора задних модулей

    var selectedBackModule: CameraManager.BackModule { activeBackModule }
      func availableBackModules() -> [CameraManager.BackModule] { cameraManager.availableBackModules() }
      func setBackModule(_ module: CameraManager.BackModule) { cameraManager.setBackModule(module) }
  }

// MARK: - Private: Session Setup
private extension CameraView {
    func setupSession() {
        sessionQueue.async {
            // Предпочтительный пресет
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }

            // 1) Настраиваем вход задней камеры через CameraManager (ширик по умолчанию)
            self.cameraManager.configureInitialBackCamera()

            // 2) Добавляем выход для фото
            self.session.beginConfiguration()
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                // Не включаемDeprecated-флаги; дефолтов достаточно на iOS 16
            }
            self.session.commitConfiguration()

            // 3) Инициализируем менеджер фокуса и свяжем с CameraManager
            self.focusManager = FocusManager(queue: self.sessionQueue, device: self.cameraManager.device)
            self.cameraManager.focusManager = self.focusManager

            // 4) Стартуем сессию
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            DispatchQueue.main.async { self.lastSaveError = error }
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { self.lastSaveError = GalleryError.noImageData }
            return
        }

        // Сохраняем в альбом "Focus"
        gallery.savePhotoData(data) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.lastSaveError = nil
                case .failure(let err):
                    self?.lastSaveError = err
                }
            }
        }
    }
}
