//
//  CameraScreen.swift
//  Focus
//
//  Created by Kaider on 16.09.2025.
//

import SwiftUI
import AVFoundation

struct CameraScreen: View {

    @StateObject private var camera = CameraView()

    var body: some View {
        ZStack {
            // Превью камеры + фокус по тапу
            CameraPreview(session: camera.getSession()) { layerPoint, previewLayer in
                camera.focus(fromLayerPoint: layerPoint, in: previewLayer)
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Панель переключения задних модулей (0.5x / 1x / 2x/3x)
                ChangeCameraView(
                    available: camera.availableBackModules(),
                    selected: camera.selectedBackModule,
                    onSelect: { module in
                        camera.setBackModule(module)
                    }
                )
                .padding(.top, 16)

                Spacer()

                // Кнопка спуска
                ShotButtonView(title: "") {
                    camera.capturePhoto()
                }
                .padding(.bottom, 50)
                .padding(.leading, 200)
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    CameraScreen()
}
