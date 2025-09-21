//
//  CameraScreen.swift
//  Focus
//
//  Created by Kaider on 16.09.2025.
//

import SwiftUI

struct CameraScreen: View {
    
    @State private var camera = CameraView()
    
    var body: some View {
        ZStack{
            CameraPreview(session: camera.getSession())
                .ignoresSafeArea()
            
            VStack {
                
              Spacer()
                
                ShotButtonView(title: "") {
                    // button action
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
