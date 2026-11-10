# Field

A text input with only a bottom line, a mono label above and help text below.

- The input has no box. Its only border is a 1px `line-strong` bottom line (3:1 on `bg`).
- On focus the line becomes 2px `focus`. This is the accent's job on that screen.
- Error: the line and the help text become `ink`, with a small round dot before the help text. There is no red: the message must say what is wrong and how to fix it.
- Labels are in `label` style (Iosevka 12px), sentence case.

The consumer provides: the label, the input, and optional help or error text.
