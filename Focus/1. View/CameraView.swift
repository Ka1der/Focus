//
//  CameraView.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import AVFoundation
import SwiftUI

class CameraView: ObservableObject {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private var device: AVCaptureDevice?
    private(set) var focusManager: FocusManager?

    init() {
        setupSession()
    }

    private func setupSession() {
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        // Сохраняем устройство и создаем FocusManager на той же очереди
        self.device = device
        self.focusManager = FocusManager(queue: sessionQueue, device: device)

        // Запуск сессии в фоне
        sessionQueue.async {
            self.session.startRunning()
        }
    }

    func getSession() -> AVCaptureSession {
        return session
    }

    // Проброс фокуса: конвертация точки слоя и вызов FocusManager
    func focus(fromLayerPoint layerPoint: CGPoint, in previewLayer: AVCaptureVideoPreviewLayer) {
        focusManager?.focus(fromLayerPoint: layerPoint, in: previewLayer)
    }
}
