//
//  CameraView.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import AVFoundation
import SwiftUI

final class CameraView: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    private var device: AVCaptureDevice?
    private(set) var focusManager: FocusManager?
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let gallery: GalleryManager = GalleryManager(albumTitle: "Focus")
    
    @Published var lastSaveError: Error?
    
    override init() {
        super.init()
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
        if session.canAddInput(input) { session.addInput(input) }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        session.commitConfiguration()
        
        self.device = device
        self.focusManager = FocusManager(queue: sessionQueue, device: device)
        
        sessionQueue.async { self.session.startRunning() }
    }
    
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
}

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
