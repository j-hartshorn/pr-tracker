import Hairline
import SwiftUI
import TrackerCore

/// The most urgent status across everything, as the menu bar item.
struct MenuBarIcon: View {
    let status: Status

    var body: some View {
        Image(nsImage: image)
            .accessibilityLabel("gh-tracker")
    }

    private var image: NSImage {
        let image = Glyph.image(status.glyph, color: status.color, size: 18)
        // With nothing to report it is a template, so it looks like any other quiet menu bar item.
        image.isTemplate = status == .waiting
        return image
    }
}
