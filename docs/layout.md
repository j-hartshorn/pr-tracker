# Code layout

Each layer only knows about the ones below it.

| Path | What it is |
| --- | --- |
| `Sources/TrackerCore` | The domain. No interface code. |
| `Sources/TrackerCore/Model` | `PullRequest`, `Review` and `Snapshot` (everything one poll learned). |
| `Sources/TrackerCore/GitHub` | The GraphQL queries (a cheap overview, and the costly details for my pull requests and for other people's), their decoding, rate limits, and the `gh` token. |
| `Sources/TrackerCore/Rules` | Pure functions over snapshots: which events to notify about, the next step of a pull request, and how pull requests stack. |
| `Sources/Hairline` | The design system in SwiftUI: tokens and components. It knows nothing about pull requests. |
| `Sources/TrackerApp` | The app: the poll loop (`AppModel`), notifications, and the views. |
| `Sources/GHTracker` | The executable. It only starts the app. |
| `Sources/Previews` | A tool that renders the views with made-up data. |
| `Support` | The app bundle's `Info.plist` and icon. |
| `docs/design-system` | Hairline's rules and tokens. The source of truth for `Sources/Hairline`. |
| `docs/plans` | The plan for v1 and the decisions behind it. |

## Where to change things

- **When to notify**: `Rules/Snapshot+Events.swift`, with `EventsTests`.
- **What a notification says**: `Rules/Event.swift`.
- **Who has the ball, and what needs attention**: `Rules/NextStep.swift`, with `NextStepTests`.
- **What red, amber and green mean**: `Rules/Status.swift`.
- **The words for a next step**: `TrackerApp/Presentation/Snapshot+Facts.swift`.
- **What data is fetched**: `GitHub/OverviewQuery.swift` if the field can change without the pull request being updated, such as checks. Otherwise `GitHub/DetailsQuery.swift` for my pull requests, or `GitHub/InvolvedQuery.swift` for other people's. Add the field to the query, the decoding and `PullRequest`, and check the cost with `rateLimit { cost }`.
- **The sections of the window**: `TrackerApp/Views/MainWindow.swift`.
- **A row**: `Views/PullRequestRow.swift` in the window, `Views/CompactPullRequestRow.swift` in the menu panel. Both use `Views/PullRequestLink.swift` for click and right-click.
- **The app icon**: `Support/AppIcon.svg` for the bundle, and `scripts/bundle.sh` makes the `.icns` from it. `Hairline/AppIcon.swift` draws the same mark for the Dock, and `TrackerApp/DockPresence.swift` colours it. Change both drawings together.
- **Colours, type and spacing**: `docs/design-system` first, then `Sources/Hairline`.

## Building without Xcode

- `@State` cannot be used. On this SDK it is a macro, and its compiler plugin ships only with Xcode. State lives in `@Observable` classes.
- Some test builds fail to find the Testing macro plugin. `scripts/check.sh` builds again when that happens.

## Commands

```sh
GH_TRACKER_LIVE=1 ./scripts/check.sh  # also the tests that read from github.com
./scripts/bundle.sh debug             # debug build of the app
```

Logs: `log show --last 5m --info --predicate 'subsystem == "local.gh-tracker"'`.

The README's screenshots are crops of `build/previews/window-*.png` and `menu-*.png`, saved in `docs/images`.
