import AppKit
import TrackerCore
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

    func post(_ event: Event) async {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default
        content.userInfo = [Self.urlKey: event.url.absoluteString]
        do {
            try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: event.id, content: content, trigger: nil))
        } catch {
            log.error("posting notification failed: \(error.localizedDescription, privacy: .public)")
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
