# Models Folder (`lib/models/`)

## Purpose
This folder is dedicated to **data models** and **data structures** used throughout the application. 

## What goes here?
- Dart classes representing domain entities (e.g., `UserModel`, `MemberModel`, `CenterModel`, `PostModel`).
- Data mapping and serialization logic:
  - `fromJson(Map<String, dynamic> json)` / `fromMap(...)`
  - `toJson()` / `toMap()`
  - Factory constructors for converting Firestore documents or SQLite database rows into Dart objects.
  - `copyWith(...)` methods for immutable state updates.

## Best Practices
- Keep models focused solely on data structure and serialization—avoid embedding UI widgets or heavy business logic here.
- Define explicit types rather than relying on `dynamic` where possible.
- Use `DateTime` parsing helpers for robust timestamp conversion.
