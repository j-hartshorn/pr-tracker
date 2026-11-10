import Hairline
import SwiftUI
import TrackerCore

extension Status {
    /// Shape carries the meaning and colour repeats it. Approved with checks running is the one mix: the approved shape in the colour for not yet.
    var glyph: Glyph.Fill {
        switch self {
        case .failing: .solid
        case .attention: .half
        case .ready, .approved: .nested
        case .waiting: .empty
        }
    }

    var color: Color {
        switch self {
        case .failing: Palette.statusFailing
        case .attention, .approved: Palette.statusAttention
        case .ready: Palette.statusReady
        case .waiting: Palette.inkMuted
        }
    }
}
