import Hairline
import SwiftUI

public struct SettingsView: View {
    @Environment(LaunchAtLogin.self) private var launchAtLogin

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            Toggle(isOn: Binding(get: { launchAtLogin.isEnabled }, set: launchAtLogin.set)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Open at login").textStyle(.control).foregroundStyle(Palette.ink)
                    Text("Start PR Tracker when you log in, so notifications arrive from the start of the day.")
                        .textStyle(.small)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            .toggleStyle(.hairlineCheckbox)
            if launchAtLogin.status == .requiresApproval {
                AlertBox(.info, title: "Waiting for your approval", detail: "Allow PR Tracker in System Settings, under General, then Login Items.")
            }
            if let error = launchAtLogin.error {
                AlertBox(.error, title: "The setting could not be changed", detail: error)
            }
        }
        .padding(Space.s4)
        .frame(width: 420, alignment: .topLeading)
        .background(Palette.bg)
        .onAppear(perform: launchAtLogin.reload)
    }
}
