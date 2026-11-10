# Toast

A short message that appears after an action, with an optional action button.

- Normal toast: `bg` fill, 1px `ink` border, glyph and one line of text.
- Error toast: inverted (`ink` fill, `bg` text). This is the loudest element in the system. Use it only for errors that a person must not miss.
- Action button: 1px border in the text colour. In an error toast it is a `bg` fill with `ink` text. Do not use the accent here: it has too little contrast on `ink`.
- One line of text. Say what happened. In an error, also say what to do.
- No close timer for errors. They stay until the person acts or closes them.

The consumer provides: the level, the message, and an optional action label.
