//
//  CameraPreview.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import AVFoundation
import SwiftUI

// UIViewRepresentable чтобы UIKit использовать внутри SwiftUI
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let onTap: (CGPoint, AVCaptureVideoPreviewLayer) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    final class Coordinator: NSObject {
        let onTap: (CGPoint, AVCaptureVideoPreviewLayer) -> Void
        init(onTap: @escaping (CGPoint, AVCaptureVideoPreviewLayer) -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard let view = gr.view as? PreviewView else { return }
            let p = gr.location(in: view)
            onTap(p, view.videoPreviewLayer)
        }
    }

    // Кастомный UIView чтобы основным слоем был AVCaptureVideoPreviewLayer
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }
    }
}
