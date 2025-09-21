//
//  CameraView.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import AVFoundation
import SwiftUI

class CameraView: ObservableObject {
    private let session = AVCaptureSession() // объект который управляет сессией захвата фото/видео/аудио
    
    init() {
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration() // ожидание настроек
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { // добавлем входной поток от камеры в сессию
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput() // добавлем выходной поток
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration() // применение изменений
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning() // запуск сессии (камера показывает кадры на экране)
        }
      
    }
    
    func getSession() -> AVCaptureSession { // отдаем наружу AVCaptureSession
        return session
    }
    
}
