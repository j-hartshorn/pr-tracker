import Hairline
import SwiftUI

/// The Hairline components side by side, to compare with docs/design-system/index.html.
struct ComponentSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack(spacing: Space.s3) {
                Button("Save changes") {}.buttonStyle(.hairline(.primary))
                Button("Cancel") {}.buttonStyle(.hairline())
                Button("Publish") {}.buttonStyle(.hairline(.accent))
                Button("Show details") {}.buttonStyle(.hairline(.quiet))
                Button("Archived") {}.buttonStyle(.hairline()).disabled(true)
                Button("Review") {}.buttonStyle(.hairline(size: .small))
            }
            Rule()
            HStack(spacing: Space.s4) {
                ForEach(Array([Glyph.Fill.empty, .nested, .half, .solid].enumerated()), id: \.offset) { _, fill in
                    Glyph(fill)
                    Glyph(fill, size: 20)
                }
                Glyph(.solid, color: Palette.statusFailing)
                Glyph(.half, color: Palette.statusAttention)
                Glyph(.nested, color: Palette.statusReady)
                Glyph(.empty, color: Palette.inkMuted)
                Image(nsImage: Glyph.image(.half, color: Palette.statusAttention, size: 18))
                Image(nsImage: Glyph.image(.solid, color: Palette.statusFailing, size: 18))
            }
            Rule()
            HStack(spacing: Space.s4) {
                Toggle("Off", isOn: .constant(false))
                Toggle("On", isOn: .constant(true))
            }
            .toggleStyle(.hairlineCheckbox)
            .textStyle(.control)
            .foregroundStyle(Palette.ink)
            Rule()
            Toast("Copied the link to #201")
            AlertBox(.warning, title: "This draft is 3 days old", detail: "Someone else may have edited it. Reload to see the latest version.")
            AlertBox(.error, title: "Your post was not published", detail: "The title is empty. Add a title, then publish again.")
            HStack(alignment: .firstTextBaseline, spacing: Space.s4) {
                Text("Heading").textStyle(.heading)
                Text("Subheading").textStyle(.subheading)
                Text("Body text").textStyle(.body)
                Text("Small text").textStyle(.small)
                Text("1,204.50 data").textStyle(.data)
                Text("Field label").textStyle(.label)
            }
            .foregroundStyle(Palette.ink)
        }
        .padding(Space.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.bg)
    }
}
