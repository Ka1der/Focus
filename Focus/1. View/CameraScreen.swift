import SwiftUI
import AVFoundation

struct CameraScreen: View {

    @StateObject private var camera = CameraView()
    @StateObject private var settings = CameraSettingsManager()

    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            // Превью
            CameraPreview(session: camera.getSession()) { layerPoint, previewLayer in
                camera.focus(fromLayerPoint: layerPoint, in: previewLayer)
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {

                // Верхняя панель
                HStack(spacing: 12) {

                    // ⚙️ Settings
                    Button { isSettingsPresented = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 1))
                            .foregroundColor(.white)
                            .contentShape(Circle())
                            .accessibilityLabel("Настройки камеры")
                    }
                    .buttonStyle(.plain)

                    // Индикатор/переключатель режима
                    HStack(spacing: 6) {
                        Text(settings.isProMode ? "PRO" : "LITE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Toggle("", isOn: $settings.isProMode)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .white))
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    // Панель смены камер
                    ChangeCameraView(
                        available: camera.availableBackModules(),
                        selectedBack: camera.selectedBackModule,
                        isFrontSelected: camera.isFrontSelected,
                        onSelectFront: { if camera.isFrontAvailable() { camera.setFrontCamera() } },
                        onSelectBack: { module in camera.setBackModule(module) }
                    )
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                Spacer()

                // Кнопка спуска
                ShotButtonView(title: "") {
                    camera.capturePhoto()
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            CameraSettingsView(settings: settings)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Связываем менеджер настроек с камерой — чтобы, например, свет (flash) читался при съёмке:
            camera.attachSettings(settings)
        }
    }
}

#Preview {
    CameraScreen()
}
