# Utils Folder (`lib/utils/`)

## Purpose
This folder is for **utility functions, helpers, formatters, and global constants** that don't belong strictly to a single UI screen or service.

## What goes here?
- **Formatters**: Currency, date, time, and phone number formatting (`date_formatter.dart`, `currency_formatter.dart`).
- **Validators**: Form field validators (email validator, password strength checker, required field checker).
- **Constants**: Application strings, regex patterns, route name constants, default configuration values.
- **Helpers**: Device screen size helpers, snackbar/toast helper utilities, clipboard helpers.
- **Extensions**: Custom Dart extensions on `BuildContext`, `String`, `DateTime`, etc.

## Best Practices
- Keep helper functions pure and stateless whenever possible (take input, return output without side effects).
- Avoid putting large business workflows here—those belong in `services/`.
