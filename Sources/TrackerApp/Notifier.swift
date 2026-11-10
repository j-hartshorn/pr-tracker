import AppKit
import UserNotifications
import os

private let log = Logger(subsystem: "local.gh-tracker", category: "notifier")

final class Notifier: NSObject, UNUserNotificationCenterDelegate, Sendable {
    private static let urlKey = "url"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            log.info("notification authorisation granted: \(granted)")
        } catch {
            log.error("notification authorisation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func post(id: String, title: String, body: String, url: URL) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [Self.urlKey: url.absoluteString]
        do {
            try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
            log.info("posted notification \(id, privacy: .public)")
        } catch {
            log.error("posting notification \(id, privacy: .public) failed: \(error)")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let string = response.notification.request.content.userInfo[Self.urlKey] as? String,
              let url = URL(string: string) else { return }
        await MainActor.run { _ = NSWorkspace.shared.open(url) }
    }
}
