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

    // MARK: - Outputs
    private let photoOutput = AVCapturePhotoOutput()

    // MARK: - Storage
    private let gallery: GalleryManager = GalleryManager(albumTitle: "Focus")

    // MARK: - Published UI state
    @Published private(set) var selection: CameraManager.Selection = .back(.wide)
    @Published var lastSaveError: Error?

    // Простой флаг для UI
    var isFrontSelected: Bool {
        if case .front = selection { return true } else { return false }
    }

    // MARK: - Init
    override init() {
        super.init()

        // Подписка на изменения выбора камеры
        cameraManager.onSelectionChange = { [weak self] newSelection in
            guard let self = self else { return }
            self.selection = newSelection
            self.updatePreviewMirroring()
        }

        setupSession()
    }

    // MARK: - Public API (для UI)
    func getSession() -> AVCaptureSession { session }

    func focus(fromLayerPoint layerPoint: CGPoint, in previewLayer: AVCaptureVideoPreviewLayer) {
        focusManager?.focus(fromLayerPoint: layerPoint, in: previewLayer)
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        settings.flashMode = .off

        sessionQueue.async {
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // Прокси для задних модулей
    var selectedBackModule: CameraManager.BackModule {
        switch selection {
        case .back(let m): return m
        case .front:       return .wide
        }
    }

    func availableBackModules() -> [CameraManager.BackModule] {
        cameraManager.availableBackModules()
    }

    func setBackModule(_ module: CameraManager.BackModule) {
        cameraManager.setBackModule(module)
    }

    // Переключение фронт/тыл
    func setFrontCamera() { cameraManager.setFrontCamera() }
    func setBackDefault() { cameraManager.setBackModule(.wide) }
    func isFrontAvailable() -> Bool { cameraManager.isFrontAvailable() }
}

// MARK: - Private: Session Setup
private extension CameraView {
    func setupSession() {
        sessionQueue.async {
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }
            
            // 1) Настраиваем задний ширик по умолчанию
            self.cameraManager.configureInitialBackCamera()
            
            // 2) Фото-выход
            self.session.beginConfiguration()
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            self.session.commitConfiguration()
            
            // 3) Фокус + связь с менеджером
            self.focusManager = FocusManager(queue: self.sessionQueue, device: self.cameraManager.device)
            self.cameraManager.focusManager = self.focusManager
            
            // 4) Старт
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    private func updatePreviewMirroring() {
        let shouldMirror: Bool = {
            if case .front = selection { return true }
            return false
        }()

        // Делаем на sessionQueue, чтобы не трогать главный поток
        sessionQueue.async {
            for connection in self.session.connections where connection.isVideoMirroringSupported {
                // Сначала — выключаем авто-режим
                connection.automaticallyAdjustsVideoMirroring = false
                // Затем — вручную задаём зеркалирование
                connection.isVideoMirrored = shouldMirror
            }
        }
    }
}

// MARK: - Photo Delegate
extension CameraView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            DispatchQueue.main.async { self.lastSaveError = error }
            return
        }
        guard let data = photo.fileDataRepresentation() else { return }

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
