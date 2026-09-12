# Screens Folder (`lib/screens/`)

## Purpose
This folder contains the **full-page views, routes, and UI screens** that users navigate between in the application.

## What goes here?
- Top-level screen widgets (e.g., `login_screen.dart`, `home_screen.dart`, `member_profile_screen.dart`, `dashboard_screen.dart`).
- Subfolders grouped by feature or flow when the app grows:
  - `auth/` (Login, Register, Forgot Password)
  - `dashboard/` (Overview, Metrics, Home)
  - `members/` (Member List, Member Details, Member Registration)
  - `settings/` (App Settings, Theme Preferences, Profile)

## Best Practices
- Each screen typically returns a `Scaffold` with an `AppBar`, `body`, and optional navigation elements.
- Keep screen files clean by delegating reusable UI components (cards, custom inputs, dialogs) to the `widgets/` folder.
- Delegate data fetching, authentication, and database calls to classes in the `services/` folder.
