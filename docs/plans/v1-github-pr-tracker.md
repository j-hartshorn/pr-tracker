# v1: GitHub PR tracker

A local macOS app in Swift that tracks the GitHub PRs I'm involved with and notifies me when one needs me.

## Decisions made

| Topic | Decision |
| --- | --- |
| App shape | Menu bar item plus a full window. The window is one page with two sections: Needs attention, then Mine as stacks. |
| Rows | Each row leads with its next step: who has the ball. A click opens GitHub. A right-click copies the link. |
| Needs addressing | A review needs me when a thread is unresolved and nobody is asked to review, or when a reviewer who did not approve has seen no commit, reply or new request since. |
| Stacks | Inferred from base-branch chains. A PR whose base branch is another open PR's head branch is stacked on it. |
| Drafts | Shown greyed. Marking ready and converting to draft are done on GitHub: the app only reads. |
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
5. **Theme**: follows the system appearance. Paper in light mode, Dark in dark mode. Stark is not offered in v1. A setting can fix the app to Paper or to Dark whatever the system is.
6. **No Dock icon** while the window is closed: the app lives in the menu bar and opens its window from there.
7. **Clicking a notification** opens the PR (or the review) in the default browser.
8. **Auth**: the app asks `gh auth token` for a token. It stores no credentials of its own.
9. **First run** records a baseline and sends no notifications, so I don't get 20 at once.

10. **Next steps** are as defined in "Next steps" below. In particular, a stacked PR only counts as ready when nothing open sits beneath it.

11. **Bot reviews don't change a PR's next step.** Bot comments show on the bot line and notify, but a thread where a bot spoke last is not one to answer.

12. **On my own PR, every unresolved thread is mine until I resolve it, unless a review is requested.** I am trying to merge, so a thread is work to do, whoever spoke last. If I need an answer to a comment, I ask for a review again, and while one is requested the PR waits on the reviewers. Threads begun by a bot don't count. On someone else's PR, a thread I began waits on me until I reply, react to its last comment, or it is resolved. A reaction means "seen, nothing to answer". A reaction does not change `updatedAt`, so a PR with a thread waiting on me has its details fetched every poll.

## Verified so far

- CoreText registers the `.woff2` files directly (`Iosevka`, `Iosevka-Aile`). No TTF conversion needed.
- `swift test` with Swift Testing works on Command Line Tools alone (Swift 6.4).
- `gh` is authed as `j-hartshorn` with `repo` scope, which covers the reads.
- Live data: 19 open PRs authored by me, 1 requested of me by name, and 1 that names the team plus someone else (correctly excluded by `user-review-requested:@me`).
- Live data: of the reviews by people on my last 40 PRs, 18 are approvals and 42 are comment-only. GitHub creates a comment-only review for each reply in a thread, so one conversation can produce several review ids.
- Live data: Copilot posted 14 reviews on my last 40 PRs, and 9 of them had no comments.
- The six status colour values below, for contrast against `bg`.

## Found while building

- **Notifications work from an ad-hoc signed app.** Permission is tied to the bundle identifier, so it survives rebuilds.
- **`@State` needs Xcode.** On this SDK it is a macro whose compiler plugin does not ship with the Command Line Tools. The app keeps state in `@Observable` classes held with `let`.
- **Test builds are flaky without Xcode.** Some builds cannot find the Testing macro plugin. `scripts/check.sh` builds again when that happens.
- **The window does not open at launch**, because the app has no Dock icon. It opens from the menu bar item.
- **The menu bar needs the Dock.** macOS shows an app's menu bar only while the app is in the Dock, so the app joins the Dock while its window or Settings is open.
- **Open at login works for the ad-hoc signed app** with `SMAppService.mainApp`, and the registration survives a rebuild.
- **The app only reads.** It had draft actions on right-click, but in use it was simpler to do them on GitHub. A right-click now copies the link.
- **Minimum macOS is 26**, for exact line heights in SwiftUI.

## Not yet verified

- **Clicking a notification opens the link.** The code is in place, but only a person can click one.

## Architecture

```
gh auth token ──▶ GitHubClient ──▶ Snapshot ──▶ diff(old, new) ──▶ [Event] ──▶ Notifier
                                      │
                                      ├──▶ stacks(from:) ──▶ forest per repo
                                      ▼
                                   Store (@Observable) ──▶ menu bar + window
```

- **`GitHubClient`**: each poll makes one cheap overview request with two searches (`author:@me` and `user-review-requested:@me`). It makes a second request for review details only when one of my PRs changed. See "GitHub API cost" below.
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

## GitHub API cost

GitHub allows 5,000 GraphQL points an hour, shared with `gh` and every other tool on the token. It charges for the page sizes a query asks for, not for what comes back.

| Query | When | Measured cost |
| --- | --- | --- |
| Overview | Every poll | 2 points |
| Details | Only for my PRs that are new, whose `updatedAt` changed, or that had a thread waiting on me | 1 point for one PR, 20 for all 19 |

That is about 120 points an hour when nothing changes. The first version fetched everything on every poll, at 210 points, and used up the hour's budget in about 24 minutes.

- **Overview** has the fields that change without the PR being updated: checks, mergeability and requested reviewers.
- **Details** has reviews, review threads and review request times. These only change when the PR is updated, so the last snapshot's copy is reused until then. The exception is a PR with a thread waiting on me, which is fetched every poll: a reaction does not touch `updatedAt`, and resolving a thread may not either.
- **The Refresh button** fetches every PR's details again, in case GitHub changes something without touching `updatedAt`.
- **When GitHub says the limit was hit**, the app sends nothing until the reset time GitHub gives, and says so in the window.

## Next steps

Every PR has a next step that says who has the ball, from one pure function `nextSteps(for:)`. A PR shows every step that is mine, or else the one thing it waits on.

| Ball is with | Next step | When | Colour |
| --- | --- | --- | --- |
| Me | `review for alice` | Someone else's PR requests my review by name. | Amber |
| Me | `answer 2 comments` | Unresolved review threads begun by a person, whoever spoke last, while nobody is asked to review. With a review requested, the PR is `waiting on bob`. | Amber |
| Me | `respond to carol` | Carol commented or requested changes, is not asked again, and has seen no commit or reply from me since. Shown only when no thread is open. | Amber |
| Me | `answer 2 comments` | On someone else's PR: open threads I began where another person spoke last and I have not reacted. | Amber |
| Me | `answer a mention` | On someone else's PR: I was mentioned and have not commented or reviewed since. Shown only when no thread waits on me. | Amber |
| Me | `fix CI` | Checks failed or errored. Applies to drafts too. | Red |
| Me | `resolve conflicts` | There is a merge conflict. Applies to drafts too. | Red |
| Me | `request a review` | Not a draft, not approved, nobody is asked, and no review is waiting on me. | Amber |
| Me | `ready to merge` | Not a draft, approved, checks not failing or running, no conflicts, and nothing open beneath it in its stack. | Green |
| Others | `waiting on bob for 3d` | Reviewers are asked. The time is since the longest-waiting one was asked. | None |
| Others | `waiting on CI` | Approved, and checks are still running. | None |
| Others | `waiting on #175` | Approved and green, but stacked on an open PR. | Green |
| Others | `waiting on alice` | Someone else's PR that I took part in, with nothing for me to answer. Not listed anywhere. | None |
| Nobody | `draft` | A draft with nothing broken and nothing to answer. | None |

The Needs attention section lists the PRs whose first step is mine, in the order of the table. A PR's colour is that of its most urgent step: red, then amber, then green. The menu bar icon shows the most urgent colour among the PRs that need me, so a green PR that waits on its stack leaves it quiet.

Handing the ball back: on my PR, resolving a thread or asking for a review again hands it back. On someone else's, replying in a thread I began or reacting to its last comment answers it. A commit or a reply after a review moves the PR from `respond to carol` to `request a review`. Asking Carol again moves it to `waiting on carol`.

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
4. **Window and Hairline.** Tokens, fonts, light and dark themes, the next-step rules, and the sections of the window. Add the status tokens and their rules to `docs/design-system` (`tokens.json`, `tokens.css` and `README.md`, edited by hand as there is no generator in the repo).
   Verify: tests for each status row and its precedence, and by eye in both appearances against `docs/design-system/index.html`, using `swift run Previews`.
5. **Stacks.** `stacks(from:)` and the stack view, with review, conflict and CI state per PR.
   Verify: tests for a chain, a branching stack, a single PR and a fork.
6. **Drafts.** Drafts section with the two actions.
   Verify: GitHub accepts both mutations for a made-up id. Toggling a real draft PR is left to me.
7. **Menu bar status.** The icon shows the most urgent status, and the dropdown shows the short list.

## Out of scope for v1

- Linear.
- Team-only review requests.
- PRs not yet opened (local jj bookmarks).
- Per-repo filters, snoozing, notification preferences.
- Webhooks.
