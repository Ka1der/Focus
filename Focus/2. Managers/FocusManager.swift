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

    init(queue: DispatchQueue = DispatchQueue(label: "focus.queue"), device: AVCaptureDevice?) {
        self.queue = queue
        self.device = device
    }

    func updateDevice(_ device: AVCaptureDevice?) {
        self.device = device
    }

    func focus(at devicePoint: CGPoint) {
        queue.async { [weak self] in
            guard let device = self?.device else { return }
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    } else if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }
            } catch {
                print("Focus manager error:", error)
            }
        }
    }

    func focus(fromLayerPoint layerPoint: CGPoint, in previewLayer: AVCaptureVideoPreviewLayer) {
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        focus(at: devicePoint)
    }
}
