<div align="center">
  <img src="Support/AppIcon.svg" width="128" alt="The PR Tracker icon: a square holding three bars">

  <h1>PR Tracker</h1>

  <p><b>A macOS menu bar app that tells you which GitHub pull requests need you, and what to do next.</b></p>

  <p>
    <img src="https://img.shields.io/badge/macOS-26%2B-informational" alt="macOS 26 or later">
    <img src="https://img.shields.io/badge/Swift-6.2-orange" alt="Swift 6.2">
    <a href="LICENSE"><img src="https://img.shields.io/badge/licence-MIT-blue" alt="MIT licence"></a>
  </p>

  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/window-dark.png">
    <img src="docs/images/window-paper.png" width="720" alt="The main window: pull requests that need attention, each with its next step">
  </picture>
</div>

## What it does

Every pull request gets a next step that says who has the ball: `answer 2 comments`, `waiting on bob for 3d`, `ready to merge`. The ones where it is you are listed first.

- **Menu bar.** A square glyph shows the most urgent status. Its dropdown lists the pull requests that need something, one line each.
- **Window.** What needs you, then all your pull requests as stacks. A click opens GitHub. A right-click copies the link.
- **Notifications.** When your review is requested by name, when someone reviews your pull request, when yours fails CI or gets a merge conflict, and when someone mentions you or replies to your review comments on theirs.
- **Dock.** While the window is open, the three bars of the icon take the colours of the three most urgent pull requests.
- **Light and dark.** It follows the system, or the choice in Settings.

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/menu-dark.png">
    <img src="docs/images/menu-paper.png" width="360" alt="The menu bar dropdown: one line for each pull request that needs something">
  </picture>
</div>

## Install

There is no download yet, so build it from source. You need macOS 26 or later, Swift 6.2 or later, and the [GitHub CLI](https://cli.github.com) logged in (`gh auth login`). Xcode is not needed.

```sh
git clone https://github.com/j-hartshorn/pr-tracker.git
cd pr-tracker
./scripts/bundle.sh          # builds build/gh-tracker.app
open build/gh-tracker.app
```

## Use

- Open the window from the menu bar item.
- While the window is open the app is in the Dock and has a menu bar. Settings (⌘,) has opening at login, the appearance and how often to refresh. View › Refresh is ⌘R.
- The first run asks for permission to send notifications. The first poll is a baseline, so notifications start with the second.

## How it talks to GitHub

- It only reads. Anything you do to a pull request, you do on GitHub.
- It uses the token from the `gh` CLI and stores no credentials.
- It polls every minute, or as often as Settings says.
- A poll costs 3 of GitHub's 5,000 GraphQL points an hour, plus about 1 for each of your pull requests that changed and 2 for each of someone else's. If GitHub says the limit was hit, the app stops until the reset time.
- A review request counts only if it names you. Requests to a team are ignored.

## Develop

```sh
./scripts/check.sh                    # tests
GH_TRACKER_LIVE=1 ./scripts/check.sh  # also the tests that read from github.com
swift run Previews                    # renders every view to build/previews/*.png, light and dark
./scripts/bundle.sh debug             # debug build of the app
```

Logs: `log show --last 5m --info --predicate 'subsystem == "local.gh-tracker"'`.

The screenshots above are crops of `build/previews/window-*.png` and `menu-*.png`, saved in `docs/images`. They show made-up data.

## Code layout

Each layer only knows about the ones below it.

| Path | What it is |
| --- | --- |
| `Sources/TrackerCore` | The domain. No interface code. |
| `Sources/TrackerCore/Model` | `PullRequest`, `Review` and `Snapshot` (everything one poll learned). |
| `Sources/TrackerCore/GitHub` | The GraphQL queries (a cheap overview, and the costly details for your pull requests and for other people's), their decoding, rate limits, and the `gh` token. |
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
- **What data is fetched**: `GitHub/OverviewQuery.swift` if the field can change without the pull request being updated, such as checks. Otherwise `GitHub/DetailsQuery.swift` for your own pull requests, or `GitHub/InvolvedQuery.swift` for other people's. Add the field to the query, the decoding and `PullRequest`, and check the cost with `rateLimit { cost }`.
- **The sections of the window**: `TrackerApp/Views/MainWindow.swift`.
- **A row**: `Views/PullRequestRow.swift` in the window, `Views/CompactPullRequestRow.swift` in the menu panel. Both use `Views/PullRequestLink.swift` for click and right-click.
- **The app icon**: `Support/AppIcon.svg` for the bundle, and `scripts/bundle.sh` makes the `.icns` from it. `Hairline/AppIcon.swift` draws the same mark for the Dock, and `TrackerApp/DockPresence.swift` colours it. Change both drawings together.
- **Colours, type and spacing**: `docs/design-system` first, then `Sources/Hairline`.

## Building without Xcode

- `@State` cannot be used. On this SDK it is a macro, and its compiler plugin ships only with Xcode. State lives in `@Observable` classes.
- Some test builds fail to find the Testing macro plugin. `scripts/check.sh` builds again when that happens.

## Licence

[MIT](LICENSE). The Iosevka fonts in `docs/design-system/fonts` are by Belleve Invis, under the [SIL Open Font License](docs/design-system/fonts/LICENSE-OFL.txt).
