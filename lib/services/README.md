# Services Folder (`lib/services/`)

## Purpose
This folder handles all **business logic, backend communication, data persistence, and external APIs**.

## What goes here?
- **Authentication Services**: Firebase Auth, session management (`auth_service.dart`).
- **Database Services**: 
  - Cloud Firestore operations (`firestore_service.dart`).
  - Local SQLite operations (`database_service.dart`).
- **File & Media Services**: Storage upload/download, image picking and caching (`storage_service.dart`).
- **Device & System Services**: Notifications, network connectivity, hardware APIs.

## Best Practices
- Keep services decoupled from Flutter UI widgets. Services should return pure Dart types, models, or streams (`Future<UserModel>`, `Stream<List<MemberModel>>`).
- Handle errors and exceptions gracefully within services, returning meaningful messages or result types.
- Follow singleton or dependency injection patterns so services can be easily accessed across screens.
