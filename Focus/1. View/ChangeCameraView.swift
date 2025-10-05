//
//  ChangeCameraView.swift
//  Focus
//
//  Created by Kaider on 04.10.2025.
//

import SwiftUI

/// Кнопки переключения задних камер: 0.5x / 1x / 2x(/3x)
struct ChangeCameraView: View {
    let available: [CameraManager.BackModule]
    let selected: CameraManager.BackModule
    let onSelect: (CameraManager.BackModule) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(available, id: \.self) { module in
                let isSelected = (module == selected)

                Button {
                    onSelect(module)
                } label: {
                    Text(title(for: module))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.9) : Color.clear)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
                        )
                        .foregroundColor(isSelected ? .black : .white)
                        .contentShape(Capsule())
                        .accessibilityLabel(accessibilityTitle(for: module))
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    private func title(for module: CameraManager.BackModule) -> String {
        switch module {
        case .ultraWide: return "0.5x"
        case .wide:      return "1x"
        case .tele(let nominal):
            // Покажем кратность, если знаем; иначе дефолт «2x»
            if let n = nominal { return "\(Int(n))x" }
            return "2x"
        }
    }

    private func accessibilityTitle(for module: CameraManager.BackModule) -> String {
        switch module {
        case .ultraWide: return "Ультраширокая камера, 0.5 икс"
        case .wide:      return "Широкоугольная камера, 1 икс"
        case .tele(let nominal):
            if let n = nominal { return "Телеобъектив, \(Int(n)) икс" }
            return "Телеобъектив, 2 икс"
        }
    }
}

#Preview {
    ChangeCameraView(
        available: [.ultraWide, .wide, .tele(nominal: 3)],
        selected: .wide,
        onSelect: { _ in }
    )
    .padding()
    .background(Color.black)
}
