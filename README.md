# gh-tracker

A macOS menu bar app that tracks the GitHub pull requests I'm involved with and notifies me when one needs me.

- **Notifies** when my review is requested by name, when someone reviews one of my pull requests, and when one of mine fails CI or gets a merge conflict.
- **Menu bar**: a square glyph showing the most urgent status, with a dropdown of the pull requests that need something.
- **Window**: what needs me, then all my pull requests as stacks. Every row says who has the ball: `answer 2 comments`, `waiting on bob for 3d`, `ready to merge`. A click opens GitHub, and a right-click marks a pull request ready or converts it to a draft.

It polls GitHub every 60 seconds with the token from the `gh` CLI. It stores no credentials.

## Run

Needs macOS 26 or later, Swift 6.2 or later, and `gh` logged in (`gh auth login`). Xcode is not needed.

```sh
./scripts/bundle.sh          # builds build/gh-tracker.app
open build/gh-tracker.app
```

The app has no Dock icon. Open the window from the menu bar item. The first run asks for permission to send notifications, and sends none until the second poll: the first poll is the baseline.

## Develop

```sh
./scripts/check.sh                    # tests
GH_TRACKER_LIVE=1 ./scripts/check.sh  # also the tests that read from github.com
swift run Previews                    # renders every view to build/previews/*.png, light and dark
./scripts/bundle.sh debug             # debug build of the app
```

Logs: `log show --last 5m --info --predicate 'subsystem == "local.gh-tracker"'`.

## Layout

Each layer only knows about the ones below it.

| Path | What it is |
| --- | --- |
| `Sources/TrackerCore` | The domain. No interface code. |
| `Sources/TrackerCore/Model` | `PullRequest`, `Review` and `Snapshot` (everything one poll learned). |
| `Sources/TrackerCore/GitHub` | The GraphQL query, its decoding, and the `gh` token. |
| `Sources/TrackerCore/Rules` | Pure functions over snapshots: which events to notify about, the next step of a pull request, and how pull requests stack. |
| `Sources/Hairline` | The design system in SwiftUI: tokens and components. It knows nothing about pull requests. |
| `Sources/TrackerApp` | The app: the poll loop (`AppModel`), notifications, and the views. |
| `Sources/GHTracker` | The executable. It only starts the app. |
| `Sources/Previews` | A tool that renders the views with made-up data. |
| `docs/design-system` | Hairline's rules and tokens. The source of truth for `Sources/Hairline`. |
| `docs/plans` | The plan for v1 and the decisions behind it. |

### Where to change things

- **When to notify**: `Rules/Snapshot+Events.swift`, with `EventsTests`.
- **What a notification says**: `Rules/Event.swift`.
- **Who has the ball, and what needs attention**: `Rules/NextStep.swift`, with `NextStepTests`.
- **What red, amber and green mean**: `Rules/Status.swift`.
- **The words for a next step**: `TrackerApp/Presentation/Snapshot+Facts.swift`.
- **What data is fetched**: `GitHub/SnapshotQuery.swift`. Add the field to the query, the decoding and `PullRequest`.
- **The sections of the window**: `TrackerApp/Views/MainWindow.swift`.
- **Colours, type and spacing**: `docs/design-system` first, then `Sources/Hairline`.

## Limits of building without Xcode

- `@State` cannot be used. On this SDK it is a macro, and its compiler plugin ships only with Xcode. State lives in `@Observable` classes.
- Some test builds fail to find the Testing macro plugin. `scripts/check.sh` builds again when that happens.
