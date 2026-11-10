import Hairline
import SwiftUI

/// Confirms a right-click, which copies without any other sign.
struct CopiedLinkToast: View {
    @Environment(LinkCopier.self) private var copier

    var body: some View {
        ZStack {
            if let pullRequest = copier.lastCopied {
                Toast("Copied the link to #\(pullRequest.number)")
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: copier.lastCopied?.id)
    }
}
