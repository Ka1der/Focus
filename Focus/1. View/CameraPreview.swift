//
//  CameraPreview.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import AVFoundation
import SwiftUI

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

            // 1) визуальный индикатор точки фокуса
            view.showFocusRing(at: p)

            // 2) фокус по точке (конвертация в координаты устройства)
            onTap(p, view.videoPreviewLayer)
        }
    }

    // UIView с AVCaptureVideoPreviewLayer и рингом фокуса
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }

        // MARK: - Focus Ring
        private var ringReusePool: [UIView] = [] // простейший пул, чтобы не создавать каждый раз

        func showFocusRing(at point: CGPoint) {
            let size: CGFloat = 86
            let ring = dequeueRing(size: size)
            ring.center = point
            ring.alpha = 0
            ring.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            addSubview(ring)

            // анимация появления и затухания
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut], animations: {
                ring.alpha = 1
                ring.transform = .identity
            }, completion: { _ in
                UIView.animate(withDuration: 0.3, delay: 0.5, options: [.curveEaseIn], animations: {
                    ring.alpha = 0
                    ring.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: { _ in
                    ring.removeFromSuperview()
                    self.ringReusePool.append(ring) // вернуть в пул
                })
            })
        }

        private func dequeueRing(size: CGFloat) -> UIView {
            if let view = ringReusePool.popLast() {
                view.bounds.size = CGSize(width: size, height: size)
                view.layer.cornerRadius = size / 2
                return view
            }
            let v = UIView(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
            v.isUserInteractionEnabled = false
            v.layer.cornerRadius = size / 2
            v.layer.borderWidth = 2
            v.layer.borderColor = UIColor.systemYellow.cgColor
            v.layer.shadowColor = UIColor.black.cgColor
            v.layer.shadowOpacity = 0.25
            v.layer.shadowRadius = 6
            v.layer.shadowOffset = .zero

            // маленькая точка в центре — «точка фокуса»
            let dotSize: CGFloat = 6
            let dot = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
            dot.backgroundColor = .systemYellow
            dot.layer.cornerRadius = dotSize / 2
            dot.center = CGPoint(x: size/2, y: size/2)
            dot.isUserInteractionEnabled = false
            v.addSubview(dot)

            return v
        }
    }
}
