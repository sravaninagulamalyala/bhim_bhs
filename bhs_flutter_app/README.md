# BHARATHIYA HARIJANA SANGAM Flutter App

Android/iOS Flutter app for BHARATHIYA HARIJANA SANGAM family/member management.

## Backend

Default API base URL:

```text
https://api.meghaconnect.cloud/api/v1
```

Override at build/run time:

```bash
flutter run --dart-define=BHS_API_BASE_URL=https://api.meghaconnect.cloud/api/v1
```

## Modules

- Splash screen
- Home screen with public counts
- Staff/member login
- Role-based dashboard and drawer
- Public member registration
- Excel upload
- Staff management
- Member search and family details
- Member update
- Search result view actions, member detail view, and family correction mapping
- Date-first attendance marking and calendar attendance view
- Transaction entry and transaction view
- Reports, heatmap, and Excel download
- Profile/logout

## Run

```bash
flutter pub get
flutter run
flutter build apk --release
```

## Notes

- JWT token is stored using `flutter_secure_storage`.
- Staff role and display details are stored with `shared_preferences`.
- API endpoints are centralized in `lib/core/constants/api_constants.dart` and `lib/core/network/api_client.dart`.
- The UI includes fallback content when backend responses are empty.
- Mark Attendance is shown to `SUPER_ADMIN`, `GENERAL_SECRETARY`, `JOINT_SECRETARY`, `ORG_SECRETARY`, and `SECRETARY`.
- View Attendance is shown to all logged-in staff and highlights meeting dates in green.
- Member Search opens a detail screen with selected member data, family details, family members, remove-from-family, and add-to-family actions.
