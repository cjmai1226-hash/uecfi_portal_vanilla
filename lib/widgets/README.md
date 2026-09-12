# Widgets Folder (`lib/widgets/`)

## Purpose
This folder contains **reusable, modular UI components** shared across multiple screens or throughout the entire app.

## What goes here?
- **Buttons & Controls**: Custom primary buttons, action chips, icon buttons, toggle switches (`custom_button.dart`).
- **Input Fields**: Custom text inputs, dropdown pickers, search bars (`custom_text_field.dart`, `search_bar_widget.dart`).
- **Cards & Tiles**: Member cards, summary cards, statistic tiles (`member_card.dart`, `stat_card.dart`).
- **Dialogs & Bottom Sheets**: Confirmation dialogs, modal bottom sheets, filter sheets.
- **Feedback & Loaders**: Custom shimmer skeletons, loading indicators, empty-state placeholders.

## Best Practices
- Keep widgets modular, parameterized, and reusable.
- Rely on theme tokens (`Theme.of(context).colorScheme...`) rather than hardcoded colors so your widgets adapt smoothly to light and dark modes.
- Prefer smaller, well-named custom widgets over large monolithic widget build trees.
