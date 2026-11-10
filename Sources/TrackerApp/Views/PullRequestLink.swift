import AppKit
import SwiftUI
import TrackerCore

/// A click opens the pull request on GitHub. A right-click copies its link.
struct PullRequestLink<Label: View>: View {
    let pullRequest: PullRequest
    @ViewBuilder let label: Label
    @Environment(\.openURL) private var openURL
    @Environment(LinkCopier.self) private var copier

    var body: some View {
        // The right-click goes on the label: on the button, a right-click would also open the link.
        Button { openURL(pullRequest.url) } label: {
            label
                .contentShape(Rectangle())
                .gesture(RightClick { copier.copyLink(of: pullRequest) })
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
    }
}

/// SwiftUI only offers a menu on right-click, so this uses AppKit's click recognizer for the right button.
private struct RightClick: NSGestureRecognizerRepresentable {
    let action: () -> Void

    func makeNSGestureRecognizer(context: Context) -> NSClickGestureRecognizer {
        let recognizer = NSClickGestureRecognizer()
        recognizer.buttonMask = 0x2
        return recognizer
    }

    func handleNSGestureRecognizerAction(_ recognizer: NSClickGestureRecognizer, context: Context) {
        action()
    }
}
