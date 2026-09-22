# Screens Folder (`lib/screens/`)

## Purpose
This folder contains the **full-page views, routes, and UI screens** that users navigate between in the application.

## Directory Structure

Screens are grouped by domain / feature modules:

- **`admin/`**: Administrative screens (`activity_logs_screen.dart`, `role_management_screen.dart`).
- **`auth/`**: Authentication & account access (`login_screen.dart`).
- **`centers/`**: Worship centers and local church details (`center_details_screen.dart`).
- **`finance/`**: Financial dashboard, tithes, and reports (`finance_screen.dart`).
- **`home/`**: Main app container and landing view (`home_screen.dart`, `main_navigation_screen.dart`).
- **`members/`**: Member directory, profile details, and registration (`members_directory_screen.dart`, `member_details_screen.dart`, `add_member_screen.dart`).
- **`portal/`**: General portal resources, menu, constitution, and forms (`portal_menu_screen.dart`, `constitution_bylaws_screen.dart`, `forms_templates_screen.dart`).
- **`posts/`**: Announcements and social feed creation (`create_post_screen.dart`).
- **`stats/`**: Aggregated analytics and demographics (`stats_screen.dart`).
- **`transfers/`**: Church transfer requests and approvals (`transfer_request_screen.dart`, `transfer_requests_screen.dart`).
- **`screens.dart`**: Central barrel export for all screens.

## Best Practices
- Each screen typically returns a `Scaffold` with an `AppBar`, `body`, and optional navigation elements.
- Keep screen files clean by delegating reusable UI components (cards, custom inputs, dialogs) to the `widgets/` folder.
- Delegate data fetching, authentication, and database calls to classes in the `services/` folder.
- You can import individual screens or import `package:.../screens/screens.dart` for all screens.
