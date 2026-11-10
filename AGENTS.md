# gh-tracker

A macOS menu bar app, for one person, that tracks the GitHub pull requests they are involved with. Swift 6.2, SwiftUI, macOS 26 or later. `docs/layout.md` has the code layout and where each rule lives. `docs/plans/v1-github-pr-tracker.md` has the decisions and the reasons for them.

## Commands

```sh
./scripts/check.sh                    # tests
GH_TRACKER_LIVE=1 ./scripts/check.sh  # also the tests that read from github.com
swift run Previews                    # every view as PNG in build/previews, light and dark
./scripts/bundle.sh                   # release build of build/gh-tracker.app
pkill -f "gh-tracker.app/Contents/MacOS/GHTracker"; open build/gh-tracker.app   # restart the app
```

- Open the app a second time (`open build/gh-tracker.app`) to bring its window up. It is in the Dock, with its menu bar, only while its window or Settings is open (`DockPresence.swift`).
- Logs: `log show --last 5m --info --predicate 'subsystem == "local.gh-tracker"'`.

## Version control

- Use `jj`, not `git`. The remote is `origin`, on GitHub, and the branch is `main`.
- `jj commit -m "..."` adds the sign-off trailer by itself. Pass paths to commit part of the working copy.
- One logical change per commit. Run the tests first, and check their exit status, not only the last line of output.

## Building without Xcode

Only the Command Line Tools are installed. Two things follow.

- **`@State` does not compile.** It is a macro whose plugin ships only with Xcode. Keep state in `@Observable` classes held with `let`. `@Environment`, `@Binding` and `@Bindable` work.
- **Test builds sometimes fail with "plugin for module 'TestingMacros' not found".** Run them again. `scripts/check.sh` does this by itself. Use it and not `swift test`.

There are no Xcode previews. To check a view, run `swift run Previews` and read the PNG. Add new states to `Sources/Previews/Fixtures.swift`.

## Layers

Each layer knows only the ones below it.

1. `TrackerCore`: the domain. `Model`, `GitHub` (queries and decoding) and `Rules` (pure functions over a `Snapshot`). No interface code. All the tests are here.
2. `Hairline`: the design system in SwiftUI. It knows nothing about pull requests.
3. `TrackerApp`: the poll loop (`AppModel`), notifications, text for the interface (`Presentation`) and the views.

Put a rule in `Rules` with a test, not in a view.

## The rules that matter

- **A pull request is mine to review only if I am requested by name.** Team requests are ignored.
- **Someone else's pull request also needs me when I am mentioned on it, or when someone replies in a review thread I began.** A mention stands until I comment or review. A thread stands until I reply or it is resolved. A new review request replaces both.
- **Every pull request has next steps** (`Rules/NextStep.swift`): the steps that are mine, or the one thing it waits on. The window, the menu bar icon and the colours all come from these.
- **Notifications come from comparing two snapshots** (`Rules/Snapshot+Events.swift`). The first snapshot is a silent baseline.
- **Adding a stored field to `PullRequest` makes the saved snapshot unreadable**, so the next poll is a silent baseline. This is fine, but expect it.

## GitHub API

- The budget is 5,000 GraphQL points an hour, shared with `gh`. GitHub charges for the page sizes a query asks for, not for what comes back.
- `OverviewQuery` runs every poll and costs 3 points. `DetailsQuery` (my pull requests, about 1 point each) and `InvolvedQuery` (other people's, about 2 each) run only for pull requests whose `updatedAt` changed.
- Before changing a query, measure it: add `rateLimit { cost }` and run it with `gh api graphql`. A version that asked for review threads on every poll cost 210 points and used the hour's budget in 24 minutes.
- The app only reads from GitHub. Actions on a pull request are done on GitHub.

## Design system

`docs/design-system` is the source of truth. `Sources/Hairline` follows it. Change the docs first.

- Use the tokens only: `Palette`, `Space`, `Stroke` and `TextStyle`. No other colours, sizes or radii.
- Text is `ink` or `ink-muted`. `line-strong` is for disabled text, used here for parked drafts.
- The three status colours go on status glyphs and the bars of the Dock icon, and nowhere else. The glyph's shape carries the meaning, and the colour repeats it.
- Sentence case. Short, plain words. Verbs on buttons.
- Colours follow the system appearance: Paper in light, Dark in dark. A setting can fix the app to either one. Check both.
