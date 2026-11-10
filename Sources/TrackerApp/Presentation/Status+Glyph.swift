import Hairline
import SwiftUI
import TrackerCore

extension Status {
    /// Shape carries the meaning and colour repeats it, so the two never disagree.
    var glyph: Glyph.Fill {
        switch self {
        case .failing: .solid
        case .attention: .half
        case .ready: .nested
        case .waiting: .empty
        }
    }

    var color: Color {
        switch self {
        case .failing: Palette.statusFailing
        case .attention: Palette.statusAttention
        case .ready: Palette.statusReady
        case .waiting: Palette.inkMuted
        }
    }
}

extension Checks {
    /// The colour of the CI dot. Nil when the pull request has no checks.
    var color: Color? {
        switch self {
        case .failing: Palette.statusFailing
        case .pending: Palette.statusAttention
        case .passing: Palette.statusReady
        case .none: nil
        }
    }
}
