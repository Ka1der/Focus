//
//  ChangeCameraView.swift
//  Focus
//
//  Created by Kaider on 04.10.2025.
//

import SwiftUI

/// Панель выбора камеры: фронтальная + модули задней (0.5x / 1x / 2x/3x)
struct ChangeCameraView: View {
    // Back modules
    let available: [CameraManager.BackModule]
    let selectedBack: CameraManager.BackModule

    // Front
    let isFrontSelected: Bool
    let onSelectFront: () -> Void

    // Back select
    let onSelectBack: (CameraManager.BackModule) -> Void

    var body: some View {
        HStack(spacing: 10) {

            // FRONT button
            Button(action: onSelectFront) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(10)
                    .background(
                        Circle().fill(isFrontSelected ? Color.white.opacity(0.95) : Color.clear)
                    )
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
                    )
                    .foregroundColor(isFrontSelected ? .black : .white)
                    .contentShape(Circle())
                    .accessibilityLabel("Фронтальная камера")
                    .accessibilityAddTraits(isFrontSelected ? [.isSelected] : [])
            }
            .buttonStyle(.plain)

            // Divider dot
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 3, height: 3)

            // BACK modules (всегда активны, даже когда выбрана фронталка)
            HStack(spacing: 8) {
                ForEach(available, id: \.self) { module in
                    // Выделяем кнопку, если выбран именно этот задний модуль и фронтальная НЕ активна
                    let isSelected = (!isFrontSelected && module == selectedBack)

                    Button {
                        onSelectBack(module) // ← при фронталке мгновенно переключит на заднюю
                    } label: {
                        Text(title(for: module))
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isSelected ? Color.white.opacity(0.95) : Color.clear)
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
                    // Больше НЕ делаем .disabled при фронтальной камере
                    // Можем слегка уменьшить контраст, но оставить кликабельность:
                    .opacity(isFrontSelected ? 0.85 : 1.0)
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .animation(.easeInOut(duration: 0.15), value: isFrontSelected)
    }

    private func title(for module: CameraManager.BackModule) -> String {
        switch module {
        case .ultraWide: return "0.5x"
        case .wide:      return "1x"
        case .tele(let n): return "\(Int(n ?? 2))x"
        }
    }

    private func accessibilityTitle(for module: CameraManager.BackModule) -> String {
        switch module {
        case .ultraWide: return "Ультраширокая камера, 0.5 икс"
        case .wide:      return "Широкоугольная камера, 1 икс"
        case .tele(let n): return "Телеобъектив, \(Int(n ?? 2)) икс"
        }
    }
}

#Preview {
    ChangeCameraView(
        available: [.ultraWide, .wide, .tele(nominal: 3)],
        selectedBack: .wide,
        isFrontSelected: false,
        onSelectFront: {},
        onSelectBack: { _ in }
    )
    .padding()
    .background(Color.black)
}
