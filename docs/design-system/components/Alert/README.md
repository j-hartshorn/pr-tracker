# Alert

An in-page message in a hairline box, with a square glyph that shows urgency by how much ink it has.

- Four levels: info (empty square), success (square in a square), warning (half-filled square), error (solid square). See "Alerts" in the brand book.
- Box: 1px `line-strong` border. Error: 1px `ink` border. No colour, no fill.
- Title in prose 14px weight 600. Detail text in `ink-muted`.
- Glyph: 16px, outline `stroke-mark` (1.5px), `ink`.
- Use `role="status"` for info, success and warning. Use `role="alert"` for errors.

The consumer provides: the level, a title, and detail text that says what to do.
