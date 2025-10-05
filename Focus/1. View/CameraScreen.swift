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
            // Превью + фокус по тапу
            CameraPreview(session: camera.getSession()) { layerPoint, previewLayer in
                camera.focus(fromLayerPoint: layerPoint, in: previewLayer)
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {

                // ✅ Обновлённый вызов ChangeCameraView
                ChangeCameraView(
                    available: camera.availableBackModules(),
                    selectedBack: camera.selectedBackModule,
                    isFrontSelected: camera.isFrontSelected,
                    onSelectFront: {
                        if camera.isFrontAvailable() {
                            camera.setFrontCamera()
                        }
                    },
                    onSelectBack: { module in
                        camera.setBackModule(module)
                    }
                )
                .padding(.top, 16)

                Spacer()

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
