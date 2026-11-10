# v1: GitHub PR tracker

A local macOS app in Swift that tracks the GitHub PRs I'm involved with and notifies me when one needs me.

## Decisions made

| Topic | Decision |
| --- | --- |
| App shape | Menu bar item plus a full window. |
| Stacks | Inferred from base-branch chains. A PR whose base branch is another open PR's head branch is stacked on it. |
| Drafts | List them, with "Mark ready" and "Convert to draft" actions. |
| Review requests | A PR is mine only if I'm requested by name (`user-review-requested:@me`). Team requests, with or without another person named, are ignored in v1. |
| Bot reviews | A bot review notifies only when it has comments. Every bot review shows as a quiet line on the PR row, separate from reviews by people. |
| Status colours | Hairline gains three status colours (failing, attention, ready), used on status glyphs only. |
| Build | SwiftPM package, no Xcode needed. A script wraps the binary into a `.app`. |
| Version control | `jj`. |

## Assumptions to confirm

These are my defaults. Change any of them before I start.

1. **Scope**: every open, non-archived PR on github.com that I authored or am requested on by name. No per-org or per-repo filter.
2. **"Review posted"** means any submitted review (approved, changes requested, or commented) on one of my open PRs, by a person other than me.
3. **Red and conflict notifications** are for my own PRs only, and fire once when the state changes to red or to conflicting. A PR that goes green and then red again notifies again.
4. **Poll interval**: 60 seconds. "Timely" means within about a minute.
5. **Theme**: follows the system appearance. Paper in light mode, Dark in dark mode. Stark is not offered in v1.
6. **No Dock icon**: the app lives in the menu bar and opens its window from there.
7. **Clicking a notification** opens the PR (or the review) in the default browser.
8. **Auth**: the app asks `gh auth token` for a token. It stores no credentials of its own.
9. **First run** records a baseline and sends no notifications, so I don't get 20 at once.

10. **Status meanings** are as defined in "PR status" below. In particular, a stacked PR only counts as ready when nothing open sits beneath it.

11. **Bot reviews don't change a PR's status.** Bot comments show on the bot line and notify, but they don't turn the PR amber.

## Verified so far

- CoreText registers the `.woff2` files directly (`Iosevka`, `Iosevka-Aile`). No TTF conversion needed.
- `swift test` with Swift Testing works on Command Line Tools alone (Swift 6.4).
- `gh` is authed as `j-hartshorn` with `repo` scope, which covers reads and the draft mutations.
- Live data: 19 open PRs authored by me, 1 requested of me by name, and 1 that names the team plus someone else (correctly excluded by `user-review-requested:@me`).
- Live data: of the reviews by people on my last 40 PRs, 18 are approvals and 42 are comment-only. GitHub creates a comment-only review for each reply in a thread, so one conversation can produce several review ids.
- Live data: Copilot posted 14 reviews on my last 40 PRs, and 9 of them had no comments.
- The six status colour values below, for contrast against `bg`.

## Not yet verified

- **Notifications from an ad-hoc signed app.** `UNUserNotificationCenter` needs a real bundle with a bundle identifier. I think ad-hoc signing is enough, but I haven't tried it. Slice 1 exists to settle this first.
- **The exact GraphQL query.** The fields below exist as far as I know, but the full query has only been run in part.

## Architecture

```
gh auth token ──▶ GitHubClient ──▶ Snapshot ──▶ diff(old, new) ──▶ [Event] ──▶ Notifier
                                      │
                                      ├──▶ stacks(from:) ──▶ forest per repo
                                      ▼
                                   Store (@Observable) ──▶ menu bar + window
```

- **`GitHubClient`**: one GraphQL request per poll with two searches (`author:@me` and `user-review-requested:@me`), decoded into `PullRequest` values. Also the two draft mutations.
- **`Snapshot`**: the PRs from one poll. Saved as JSON in Application Support so a restart doesn't re-notify.
- **`diff(old, new) -> [Event]`**: a pure function. This is where the notification rules live, and it is the most heavily tested part.
- **`stacks(from:)`**: a pure function from PRs to a forest. It builds trees, not just chains, so one PR can have several PRs stacked on it. It matches branches within one repository only, so forks don't create false stacks.
- **`Notifier`**: turns events into `UNUserNotificationCenter` notifications and opens the link on click.
- **`Store`**: owns the poll loop and the current snapshot. The UI reads from it.
- **Hairline**: the tokens as Swift constants (colours per theme, spacing, type styles) plus the small set of views we need.

No plugin layer for Linear yet. Events and the store are already source-neutral, so Linear can be added as a second client when we get there.

### PR fields

`id`, `number`, `title`, `url`, `isDraft`, `updatedAt`, `repository.nameWithOwner`, `baseRefName`, `headRefName`, `mergeable`, `reviewDecision`, `commits(last: 1).statusCheckRollup.state`, `reviewRequests` (user or team), `reviews` (`id`, `author` with its type, `state`, `submittedAt`, `url`, `comments.totalCount`).

### Event rules

| Event | Fires when |
| --- | --- |
| Review requested | A PR appears in the "requested by name" set that wasn't there before. |
| Review posted | One of my PRs has a review id not seen before, from a person other than me. |
| Bot review posted | One of my PRs has a review id not seen before, from a bot, with at least one comment. |
| CI red | The check rollup on one of my PRs changes to `FAILURE` or `ERROR`. |
| Conflict | `mergeable` on one of my PRs changes to `CONFLICTING`. |

GitHub computes `mergeable` lazily and often returns `UNKNOWN`. An `UNKNOWN` keeps the previous value, so it never causes or hides a conflict notification.

Review-posted events are collapsed to one notification per PR and reviewer per poll, so a reviewer who posts five separate comments sends one notification, not five.

## PR status

Every PR has exactly one status, from one pure function `status(of:)`. The first matching row wins.

| Status | Colour | Means |
| --- | --- | --- |
| Failing | Red | My PR has failed or errored CI, or a merge conflict. |
| Attention | Amber | The next move is mine: changes were requested on my PR, or my review is requested by name. |
| Ready | Green | My PR is not a draft, is approved, has green CI and no conflicts, and nothing open sits beneath it in its stack. |
| Waiting | None (`ink-muted`) | Everything else: CI running, waiting on reviewers, drafts. |

## Design system mapping

- **Dark mode** already exists in Hairline as the Dark theme. The work is choosing the theme from the system appearance.
- **Status colours** are a new addition to Hairline. Three tokens, named by meaning and not by hue:

  | Token | Paper and Stark | Dark | Contrast on `bg` |
  | --- | --- | --- | --- |
  | `status-failing` | `#a8261d` | `#f2877d` | 6.5 Paper, 7.1 Stark, 7.2 Dark |
  | `status-attention` | `#7d5600` | `#d9ac55` | 6.0 Paper, 6.6 Stark, 8.5 Dark |
  | `status-ready` | `#1f6a3c` | `#7ccf97` | 6.0 Paper, 6.6 Stark, 9.5 Dark |

  For comparison, the accent is 7.0 on Paper and Dark. These are starting values, to be tuned once they are on screen.
- **Rules for the status colours**, to keep them sparing:
  - They colour the status glyph and the menu bar icon. Never text, fills, borders or whole rows.
  - The glyph keeps its ink-density shape (solid square for failing, half-filled for attention, square in a square for ready, empty for waiting), so colour is never the only signal. This matters for red and green, which are hard to tell apart for some people.
  - Text still says what the state is.
  - A waiting PR has no colour. Most of the screen stays grey.
- **The accent** keeps its one job: the suggested next action on a screen (for example the oldest review waiting on me). It is not a status colour.
- **Menu bar icon**: a square glyph in the shape and colour of the most urgent status across my PRs.
- **Type sizes**: Hairline's 16px body is sized for web reading. PR lists will likely use `small` (13px) and `data` (14px). To settle when the first list is on screen.
- **Notifications** are drawn by macOS, so they don't use Hairline.

## Slices

Each slice leaves a working app.

0. **Repo setup.** Raise `snapshot.max-new-file-size` for this repo so jj tracks the four fonts over 1 MiB, add `.gitignore` for `.build`, and commit the design system.
   Verify: `jj status` shows no refused files.
1. **Walking skeleton.** SwiftPM package, bundle script, menu bar item, and a "Send test notification" item whose notification opens a URL.
   Verify: clicking the notification opens the browser. This settles the ad-hoc signing question.
2. **Fetch.** Token from `gh`, the GraphQL query, decoding into the model.
   Verify: decoding tests against a recorded response, and the menu shows live PR counts.
3. **Events and notifications.** `diff`, snapshot persistence, the poll loop, the four notifications.
   Verify: tests for every row of the event table, the `UNKNOWN` rule and the first-run baseline.
4. **Window and Hairline.** Tokens, fonts, light and dark themes, `status(of:)`, and two lists: reviews requested of me, and my PRs waiting on reviewers. Add the status tokens and their rules to `docs/design-system` (`tokens.json`, `tokens.css` and `README.md`, edited by hand as there is no generator in the repo).
   Verify: tests for each status row and its precedence, and by eye in both appearances against `docs/design-system/index.html`.
5. **Stacks.** `stacks(from:)` and the stack view, with review, conflict and CI state per PR.
   Verify: tests for a chain, a branching stack, a single PR and a fork.
6. **Drafts.** Drafts list with the two actions.
   Verify: toggle a real draft PR both ways.
7. **Menu bar status.** The icon shows the most urgent status, and the dropdown shows the short list.

## Out of scope for v1

- Linear.
- Team-only review requests.
- PRs not yet opened (local jj bookmarks).
- Per-repo filters, snoozing, notification preferences.
- Webhooks.
