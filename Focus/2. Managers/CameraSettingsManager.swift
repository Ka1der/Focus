//
//  CameraSettingsManager.swift
//  Focus
//
//  Created by Kaider on 05.10.2025.
//

import Foundation
import AVFoundation

/// Единая точка правды для настроек камеры + простая персистенция в UserDefaults.
final class CameraSettingsManager: ObservableObject {

    enum FlashMode: String, CaseIterable, Codable {
        case off, auto, on
    }

    // MARK: - Published настройки

    @Published var isProMode: Bool {
        didSet { defaults.set(isProMode, forKey: Keys.isProMode) }
    }

    @Published var showGrid: Bool {
        didSet { defaults.set(showGrid, forKey: Keys.showGrid) }
    }

    @Published var showLevel: Bool {
        didSet { defaults.set(showLevel, forKey: Keys.showLevel) }
    }

    @Published var flashMode: FlashMode {
        didSet { defaults.set(flashMode.rawValue, forKey: Keys.flashMode) }
    }

    @Published var timerSeconds: Int {
        didSet { defaults.set(timerSeconds, forKey: Keys.timerSeconds) }
    }

    // MARK: - Init / defaults

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Значения по умолчанию
        self.isProMode     = defaults.object(forKey: Keys.isProMode)     as? Bool ?? false
        self.showGrid      = defaults.object(forKey: Keys.showGrid)      as? Bool ?? true
        self.showLevel     = defaults.object(forKey: Keys.showLevel)     as? Bool ?? false
        self.timerSeconds  = defaults.object(forKey: Keys.timerSeconds)  as? Int  ?? 0

        if let raw = defaults.string(forKey: Keys.flashMode),
           let mode = FlashMode(rawValue: raw) {
            self.flashMode = mode
        } else {
            self.flashMode = .off
        }
    }

    private enum Keys {
        static let prefix       = "focus.camera.settings."
        static let isProMode    = prefix + "isProMode"
        static let showGrid     = prefix + "showGrid"
        static let showLevel    = prefix + "showLevel"
        static let flashMode    = prefix + "flashMode"
        static let timerSeconds = prefix + "timerSeconds"
    }
}

// MARK: - Утилиты

extension CameraSettingsManager.FlashMode {
    var title: String {
        switch self {
        case .off:  return "Выкл"
        case .auto: return "Авто"
        case .on:   return "Вкл"
        }
    }

    var avCaptureMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:  return .off
        case .auto: return .auto
        case .on:   return .on
        }
    }
}

