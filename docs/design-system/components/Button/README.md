# Button

A rectangular button with a 1px border and sharp corners.

- **Default**: `line-strong` border on `bg`. Use for most actions.
- **Primary**: `ink` fill. One per view, for the main action.
- **Accent**: `accent` fill. Use it very rarely, only if the action is the one thing the screen is for. It uses up the screen's accent.
- **Quiet**: underlined text, no border. For low-priority actions in text.

Labels are verbs in sentence case. No icons in buttons unless the meaning is not clear without them. Focus shows a 2px `focus` ring, offset 2px.

The consumer provides: the label, and the `hl-button` class plus one modifier.
