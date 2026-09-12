# UECFI Portal - Architecture & Folder Guide

This document outlines the organization and responsibilities of each directory under `lib/`.

```
lib/
├── main.dart             # App entry point, MaterialApp configuration, root bindings
├── theme/                # Global styling, light/dark themes, theme mode service
│   ├── app_theme.dart    # Theme definitions, colors, typography, component styles
│   ├── theme_service.dart# SharedPreferences-backed ThemeMode notifier (Light/Dark/System)
│   └── theme.dart        # Barrel export for theme utilities
│
├── models/               # Data structures, classes, and serialization (fromJson/toJson)
│   └── README.md
│
├── screens/              # Full-page views, routes, and user flow screens
│   └── README.md
│
├── services/             # Backend integration, Firestore, SQLite, Auth, and APIs
│   └── README.md
│
├── widgets/              # Reusable UI components (buttons, cards, inputs, dialogs)
│   └── README.md
│
└── utils/                # Helper functions, validators, date/text formatters, constants
    └── README.md
```

---

## Folder Responsibilities at a Glance

| Folder | Primary Purpose | Examples |
| :--- | :--- | :--- |
| **`models/`** | Data blueprints and serialization logic | `user_model.dart`, `member_model.dart` |
| **`screens/`** | Full-page views & application navigation routes | `login_screen.dart`, `member_list_screen.dart` |
| **`services/`** | Business logic, Firebase, SQLite, and external APIs | `auth_service.dart`, `firestore_service.dart` |
| **`widgets/`** | Reusable UI components used across multiple screens | `custom_button.dart`, `member_card.dart` |
| **`utils/`** | Utility functions, formatters, validators, and helpers | `date_formatter.dart`, `validators.dart` |
| **`theme/`** | Visual design system, colors, typography, theme state | `app_theme.dart`, `theme_service.dart` |
