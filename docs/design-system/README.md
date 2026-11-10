# Hairline

Thin lines, quiet greys, one colour used once.

Hairline is a minimal, monochrome design system for a personal project. It uses grey scale, 1px lines, sharp corners and much negative space. It has one accent colour. Use the accent very little.

This is version 2. It has tokens, four components (Button, Field, Alert, Toast) and these rules. The name is a working name.

The SwiftUI version of the tokens and components is in `Sources/Hairline`.

## Principles

1. **Remove before you add.** If an element does not help a person read or act, remove it.
2. **Lines make structure.** Use a 1px hairline (`line`) to divide areas. Do not use shadows, fills or cards.
3. **Space makes groups.** Put related items close together. Put unrelated items far apart. Use the spacing scale only.
4. **One accent, one job.** The accent (`accent`) marks the suggested next action, and the keyboard focus ring. One accent element per screen. If two things are accent, one is wrong. The current item in a menu is not an action: mark it with a 2px `ink` underline.
5. **Corners are sharp.** `radius-none` everywhere. Only a status dot is round (`radius-dot`).
6. **No decoration.** No gradients, icons as ornament, or animation for its own sake.

## Colour

There are three themes. You can compare them in the Colors view.

- **Paper** (default): cool off-white (`#f4f5f6`) and slate ink (`#1e2329`). Softer for long reading. Hairlines are still clear.
- **Stark**: pure white and pure black. Maximum contrast. It can feel harsh on large screens for long periods.
- **Dark**: slate ground (`#15181c`) with light ink.

Rules:

- Text is `ink` or `ink-muted`. Never use `line` for text.
- A control border is `line-strong` (3:1). A divider is `line` (decorative).
- `surface` is for inset areas only (code, a selected row). It is not for cards.
- In an app, the accent goes on the action you want the person to take next. On a blog, that is the action at the end of a post (for example, Subscribe).
- The accent is ultramarine (`#2b44c8`; `#8c9cff` on Dark). It was chosen over Prussian, ink, cobalt, steel and cerulean because it is the clearest signal against slate. Change the `accent` token to change it everywhere.

## Status colours

There are three status colours. They are the only colours apart from the accent, and they are for status glyphs only.

| Token | Paper and Stark | Dark | Use |
| --- | --- | --- | --- |
| `status-failing` | `#a8261d` | `#f2877d` | Something is broken and needs fixing. |
| `status-attention` | `#7d5600` | `#d9ac55` | Something waits on the person. |
| `status-ready` | `#1f6a3c` | `#7ccf97` | Something is done and can go ahead. |

Rules:

- A status colour goes on a status glyph, and nowhere else. Never on text, fills, borders or whole rows.
- The glyph keeps its shape (see "Alerts" below): solid for failing, half filled for attention, square in a square for ready, empty for no status. Colour repeats what the shape says. It is never the only signal, because red and green are hard to tell apart for some people.
- The text next to the glyph still says what the state is.
- Something with no status has no colour. Most of the screen stays grey.
- A status colour is not the accent. The accent still marks the one suggested next action.

## Alerts: shape and contrast, not colour

Alerts do not use colour. A status glyph in a list can (see "Status colours" above), but an alert box cannot. Urgency shows as **ink density**: the more of the glyph is filled, the more urgent the message.

| Level | Glyph | Use |
| --- | --- | --- |
| Info | Empty square | Neutral facts. |
| Success | Square in a square | An action is complete. |
| Warning | Square, half filled on the diagonal | Something may go wrong. |
| Error | Solid square | Something went wrong. |

- Glyph outlines use `stroke-mark` (1.5px). Draw glyphs at 16px or 20px, with square corners. A status glyph that leads a two-line list row is 36px, the height of the two lines of text, so the row can be read from its glyph alone.
- Most alerts are a hairline box. Only an error **toast** is inverted (`ink` fill, `bg` text). That is the loudest thing this system can do. Use it only for things a person must not miss.
- The glyph never works alone. The text must say what happened and what to do.
- The accent has too little contrast on an `ink` fill. In an inverted toast, the action button is a `bg` fill with `ink` text.

## Type

- **Iosevka Aile** for prose: headings, body text, buttons. It is the quasi-proportional sibling of Iosevka, so the two faces share the same skeleton.
- **Iosevka** for code, data and labels. Numbers align in columns.
- Weights: 300 for display, 400 for most text, 600 for subheadings only. No bold in running text.
- Sentence case everywhere. Never all caps.
- Keep body lines under 72 characters.

## Space and lines

- Spacing scale: 4, 8, 16, 24, 40, 64, 104px (`space-1` to `space-7`).
- All borders are `stroke-hair` (1px). The focus ring is `stroke-focus` (2px) in `focus`. That is the only thick line.
- No shadows.

## Writing

- Short and plain. Use verbs on buttons: "Save changes", not "Submit".
- An action keeps the same name in all places.
- Error text says what went wrong and what to do.

## Iconography

None yet. If you add icons: 1px stroke, square ends, 16px or 20px grid, in `ink` or `ink-muted`.

## Fonts

Both fonts are by Belleve Invis, under the SIL Open Font License (`fonts/LICENSE-OFL.txt`). Latin subset, from Fontsource.

## Using this package

- `tokens.json`: the source of all tokens.
- `tokens.css`: CSS custom properties made from `tokens.json`, with `@font-face` rules. Paper is the default. Set `data-theme="stark"` or `data-theme="dark"` on `<html>` to change the theme. With no `data-theme`, the page follows the system dark mode.
- `components/bundle.css`: the component classes (`hl-button`, `hl-field`, `hl-alert`, `hl-toast`, `hl-nav`). Load it after `tokens.css`.
- `index.html`: all components on one page, with a theme switch. Open it in a browser.
- Type styles are also shorthand variables, for example `font: var(--text-body);`.
