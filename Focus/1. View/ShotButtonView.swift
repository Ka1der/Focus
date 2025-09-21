//
//  ShotButtonView.swift
//  Focus
//
//  Created by Kaider on 15.09.2025.
//

import SwiftUI

struct ShotButtonView: View {
    
    let firstCircleRadius: CGFloat = 55
    let secondircleRadius: CGFloat = 50
    let thirdircleRadius: CGFloat = 48
    
    let title: String
    let action: () -> Void
    
    var body: some View {
            Button(action: action) {
                ZStack {
                    Text(title)
                    Circle()
                        .fill(Color.black)
                        .frame(width: firstCircleRadius)
                        .shadow(radius: 4)
                    Circle()
                        .fill(Color.white)
                        .frame(width: secondircleRadius)
                    Circle()
                        .fill(Color.red)
                        .frame(width: thirdircleRadius)
                }
        }
            .buttonStyle(PlainButtonStyle()) 
    }
}

#Preview {
    ShotButtonView(title: "", action: { print("tap") } )
}
