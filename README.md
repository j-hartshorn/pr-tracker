<div align="center">
  <img src="Support/AppIcon.svg" width="128" alt="The PR Tracker icon: a square holding three bars">

  <h1>PR Tracker</h1>

  <p><b>macOS menu bar app: which GitHub pull requests need you, and what to do next.</b></p>

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

## Features

- **Next step per PR**: `answer 2 comments`, `waiting on bob for 3d`, `ready to merge`
- **Menu bar glyph**: most urgent status, dropdown of what needs you
- **Window**: needs attention first, then your PRs as stacks
- **Notifications**: review requests, reviews, failed CI, conflicts, mentions, replies
- Read-only, uses the `gh` token, 3 GraphQL points per poll

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/menu-dark.png">
    <img src="docs/images/menu-paper.png" width="640" alt="The menu bar dropdown: one line for each pull request that needs something">
  </picture>
</div>

## Install

Needs macOS 26+, Swift 6.2+, [`gh`](https://cli.github.com) logged in. No Xcode.

```sh
git clone https://github.com/j-hartshorn/pr-tracker.git
cd pr-tracker
./scripts/bundle.sh
open build/gh-tracker.app
```

## Develop

```sh
./scripts/check.sh     # tests
swift run Previews     # views as PNG in build/previews
```

Code layout: [docs/layout.md](docs/layout.md). Decisions: [docs/plans](docs/plans/v1-github-pr-tracker.md).

## Licence

[MIT](LICENSE). Iosevka fonts: [SIL OFL](docs/design-system/fonts/LICENSE-OFL.txt).
