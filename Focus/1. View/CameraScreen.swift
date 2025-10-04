//
//  CameraScreen.swift
//  Focus
//
//  Created by Kaider on 16.09.2025.
//

import SwiftUI
import AVFoundation

struct CameraScreen: View {

    @State private var camera = CameraView()

    var body: some View {
        ZStack {
            CameraPreview(session: camera.getSession()) { layerPoint, previewLayer in
                camera.focus(fromLayerPoint: layerPoint, in: previewLayer)
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                ShotButtonView(title: "") {
                    camera.capturePhoto() 
                }
                .padding(.bottom, 50)
                .padding(.leading, 200)
            }
        }
    }
}

#Preview {
    CameraScreen()
}
