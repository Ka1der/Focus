//
//  CameraManager.swift
//  Focus
//
//  Created by Kaider on 04.10.2025.
//

import AVFoundation

/// Отвечает за выбор заднего модуля камеры и перестройку input у AVCaptureSession.
final class CameraManager {
    
    // MARK: Public types
    
    enum BackModule: Hashable {
        case ultraWide          // 0.5x
        case wide               // 1x (базовый)
        case tele(nominal: Double?) // 2x/3x/… (если можем оценить)
    }
    
    // MARK: Dependencies
    
    private unowned let session: AVCaptureSession
    private let sessionQueue: DispatchQueue
    
    // MARK: State
    
    private(set) var currentBackModule: BackModule = .wide
    private(set) var currentInput: AVCaptureDeviceInput?
    private(set) var device: AVCaptureDevice?
    var onBackModuleChange: ((BackModule) -> Void)?
    
    /// Для обновления фокуса при смене модуля
    weak var focusManager: FocusManager?
    
    // MARK: Init
    
    init(session: AVCaptureSession, sessionQueue: DispatchQueue) {
        self.session = session
        self.sessionQueue = sessionQueue
    }
    
    // MARK: Public API
    
    /// Текущий выбранный задний модуль
    var selectedBackModule: BackModule { currentBackModule }
    
    /// Возвращает список доступных задних модулей на устройстве.
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
    
    /// Первичная конфигурация задней камеры (ширик по умолчанию).
    /// Вызывать один раз в начале настройки сессии.
    func configureInitialBackCamera() {
        sessionQueue.async {
            self.currentBackModule = .wide
            guard let dev = self.device(for: .wide),
                  let input = try? AVCaptureDeviceInput(device: dev) else { return }
            
            self.session.beginConfiguration()
            if let old = self.currentInput { self.session.removeInput(old) }
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
                self.device = dev
            }
            self.session.commitConfiguration()
            
            self.focusManager?.updateDevice(dev)
            
            // 👉 уведомляем UI
            DispatchQueue.main.async { self.onBackModuleChange?(self.currentBackModule) }
        }
    }
    
    /// Переключение на конкретный модуль задней камеры.
    func setBackModule(_ module: BackModule) {
        sessionQueue.async {
            guard let newDevice = self.device(for: module),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
            
            self.session.beginConfiguration()
            if let old = self.currentInput { self.session.removeInput(old) }
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
                self.device = newDevice
                self.currentBackModule = module
                self.focusManager?.updateDevice(newDevice)
            } else if let old = self.currentInput, self.session.canAddInput(old) {
                self.session.addInput(old)
            }
            self.session.commitConfiguration()
            
            // 👉 уведомляем UI
            DispatchQueue.main.async { self.onBackModuleChange?(module) }
        }
    }
    
    // MARK: Private helpers
    
    private func discoveryBackDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
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
    
    /// Грубая оценка «красивой» кратности теле-модуля (2x/3x/…)
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

