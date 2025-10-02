//
//  FocusManager.swift
//  Focus
//
//  Created by Kaider on 21.09.2025.
//

import AVFoundation

final class FocusManager {
    
    private let queue: DispatchQueue
    private weak var device: AVCaptureDevice?
    
    init(queue: DispatchQueue = DispatchQueue(label: "focus.qeue"), device: AVCaptureDevice?) {
        self.queue = queue
        self.device = device
    }
    
    // Метод обновления камеры при переключении
    func updateDevice(_ device: AVCaptureDevice?) {
        self.device = device
    }
    
        // Метод установки точки фокуса devicePoint
    func focus(at devicePoint: CGPoint) {
        queue.async { [weak self] in
            guard let device = self?.device else { return }
            
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    } else if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }
                device.unlockForConfiguration()
            } catch {
               print("Focus manager error:", error)
            }
        }
    }
    
    // Метод для конвертации точки тапа слоя в точку камеры
    func focus(fromLayerPoint layerPoint: CGPoint, in previewLayer: AVCaptureVideoPreviewLayer) {
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        focus(at: devicePoint)
    }
}
