//
//  CameraManager.swift
//  Focus
//
//  Created by Kaider on 04.10.2025.
//

import AVFoundation

/// Управляет выбором камеры и перестройкой input у AVCaptureSession.
final class CameraManager {

    // MARK: Public types

    enum BackModule: Hashable {
        case ultraWide          // 0.5x
        case wide               // 1x
        case tele(nominal: Double?) // 2x/3x/…
    }

    enum Selection: Equatable {
        case back(BackModule)
        case front
    }

    // MARK: Dependencies

    private unowned let session: AVCaptureSession
    private let sessionQueue: DispatchQueue

    // MARK: State

    private(set) var currentBackModule: BackModule = .wide
    private(set) var currentSelection: Selection = .back(.wide)
    private(set) var currentInput: AVCaptureDeviceInput?
    private(set) var device: AVCaptureDevice?

    /// Для обновления фокуса при смене устройства
    weak var focusManager: FocusManager?

    /// Уведомление об изменении активной камеры (на главном потоке)
    var onSelectionChange: ((Selection) -> Void)?

    // MARK: Init

    init(session: AVCaptureSession, sessionQueue: DispatchQueue) {
        self.session = session
        self.sessionQueue = sessionQueue
    }

    // MARK: Public API

    var isFrontSelected: Bool {
        if case .front = currentSelection { return true }
        return false
    }

    func availableBackModules() -> [BackModule] {
        let devices = discoveryBackDevices()
        var result: [BackModule] = []
        if devices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) {
            result.append(.ultraWide)
        }
        result.append(.wide)
        if let tele = devices.first(where: { $0.deviceType == .builtInTelephotoCamera }) {
            result.append(.tele(nominal: estimateTeleNominalZoom(tele: tele, devices: devices)))
        }
        return result
    }

    func isFrontAvailable() -> Bool {
        !discoveryFrontDevices().isEmpty
    }

    /// Первичная конфигурация: включаем задний ширик.
    func configureInitialBackCamera() {
        sessionQueue.async {
            self.currentBackModule = .wide
            self.applyInput(for: .back(.wide))
        }
    }

    /// Переключение на конкретный задний модуль.
    func setBackModule(_ module: BackModule) {
        sessionQueue.async {
            self.currentBackModule = module
            self.applyInput(for: .back(module))
        }
    }

    /// Включить фронтальную камеру.
    func setFrontCamera() {
        sessionQueue.async {
            self.applyInput(for: .front)
        }
    }

    // MARK: Private helpers

    private func applyInput(for selection: Selection) {
        guard let dev = device(for: selection),
              let input = try? AVCaptureDeviceInput(device: dev) else { return }

        session.beginConfiguration()
        if let old = currentInput { session.removeInput(old) }

        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
            device = dev
            currentSelection = selection

            // сообщаем менеджеру фокуса
            focusManager?.updateDevice(dev)
        } else if let old = currentInput, session.canAddInput(old) {
            // откат
            session.addInput(old)
        }
        session.commitConfiguration()

        DispatchQueue.main.async { self.onSelectionChange?(self.currentSelection) }
    }

    private func device(for selection: Selection) -> AVCaptureDevice? {
        switch selection {
        case .front:
            return discoveryFrontDevices().first { $0.deviceType == .builtInWideAngleCamera }
                ?? discoveryFrontDevices().first
        case .back(let module):
            return device(for: module)
        }
    }

    private func discoveryBackDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        ).devices
    }

    private func discoveryFrontDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices
    }

    private func device(for module: BackModule) -> AVCaptureDevice? {
        let devices = discoveryBackDevices()
        switch module {
        case .ultraWide:
            return devices.first { $0.deviceType == .builtInUltraWideCamera }
                ?? devices.first { $0.deviceType == .builtInWideAngleCamera }
        case .wide:
            return devices.first { $0.deviceType == .builtInWideAngleCamera }
                ?? devices.first
        case .tele:
            return devices.first { $0.deviceType == .builtInTelephotoCamera }
                ?? devices.first { $0.deviceType == .builtInWideAngleCamera }
        }
    }

    private func estimateTeleNominalZoom(tele: AVCaptureDevice, devices: [AVCaptureDevice]) -> Double? {
        if let wide = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }),
           let w = wide.virtualDeviceSwitchOverVideoZoomFactors.first?.doubleValue,
           let t = tele.virtualDeviceSwitchOverVideoZoomFactors.first?.doubleValue,
           w > 0 {
            let ratio = t / w
            if ratio < 2.5 { return 2 }
            else if ratio < 3.5 { return 3 }
            else { return round(ratio) }
        }
        return nil
    }
}
