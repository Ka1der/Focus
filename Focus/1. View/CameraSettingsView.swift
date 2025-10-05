//
//  CameraSettingsView.swift
//  Focus
//
//  Created by Kaider on 05.10.2025.
//

import SwiftUI

struct CameraSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var settings: CameraSettingsManager

    var body: some View {
        NavigationStack {
            Form {
                Section("Режим") {
                    Toggle("Pro режим", isOn: $settings.isProMode)
                    Text(settings.isProMode
                         ? "Ручные параметры доступны в Pro-панели."
                         : "Камера сама подбирает параметры (AF/AE/AWB).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }

                Section("Оверлеи") {
                    Toggle("Сетка", isOn: $settings.showGrid)
                    Toggle("Уровень горизонта", isOn: $settings.showLevel)
                }

                Section("Съёмка") {
                    Picker("Вспышка", selection: $settings.flashMode) {
                        ForEach(CameraSettingsManager.FlashMode.allCases, id: \.self) {
                            Text($0.title).tag($0)
                        }
                    }
                    Picker("Таймер", selection: $settings.timerSeconds) {
                        Text("Выкл").tag(0)
                        Text("3 сек").tag(3)
                        Text("10 сек").tag(10)
                    }
                }

                // TODO:
                // - Разрешение / FPS для видео
                // - Форматы фото (HEIF/JPEG/RAW)
                // - Зебры / focus peaking / гистограмма (Pro)
            }
            .navigationTitle("Настройки камеры")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
