import Hairline
import SwiftUI

public struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(LaunchAtLogin.self) private var launchAtLogin
    @AppStorage(Appearance.key) private var appearance = Appearance.system

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
            VStack(alignment: .leading, spacing: Space.s1) {
                Text("Appearance").textStyle(.control).foregroundStyle(Palette.ink)
                Choice(Appearance.allCases, selection: $appearance, title: \.title)
            }
            VStack(alignment: .leading, spacing: Space.s1) {
                Text("Refresh every").textStyle(.control).foregroundStyle(Palette.ink)
                Choice(AppModel.refreshChoices, selection: Binding(get: { model.refreshMinutes }, set: { model.refreshMinutes = $0 })) { "\($0) min" }
                Text("How often PR Tracker asks GitHub for changes.")
                    .textStyle(.small)
                    .foregroundStyle(Palette.inkMuted)
            }
            Toggle(isOn: Binding(get: { model.hidesDrafts }, set: { model.hidesDrafts = $0 })) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Ignore drafts").textStyle(.control).foregroundStyle(Palette.ink)
                    Text("Leave drafts out of Needs attention, and send no notifications about them.")
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
