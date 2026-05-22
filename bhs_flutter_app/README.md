# BHARATHIYA HARIJANA SANGAM Flutter App

Android/iOS Flutter app for BHARATHIYA HARIJANA SANGAM family/member management.

App build/display name: `bhim_bhs`

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
flutter build apk --release --build-name=1.0.0 --build-number=1
```

## Notes

- JWT token is stored using `flutter_secure_storage`.
- Staff role and display details are stored with `shared_preferences`.
- API endpoints are centralized in `lib/core/constants/api_constants.dart` and `lib/core/network/api_client.dart`.
- The UI includes fallback content when backend responses are empty.
- Login no longer calls captcha APIs and only asks for Admin ID and Password.
- Mark Attendance is shown to `SUPER_ADMIN`, `GENERAL_SECRETARY`, `JOINT_SECRETARY`, `ORG_SECRETARY`, and `SECRETARY`.
- View Attendance is shown to all logged-in staff and highlights meeting dates in green.
- Member Search opens a detail screen with selected member data, family details, family members, remove-from-family, and add-to-family actions.
- Member Search also includes Update, available to logged-in staff.
- Family Mapping searches family code, house number, family head name, member name, or mobile number and maps after confirmation.
- Reports include richer family Excel files and a Download All Members option.
- API calls and long operations use the global non-dismissible Ambedkar loading popup.
- The left drawer header is removed and only clean role-based menu options are shown.
- Splash, Home, and the loading popup use the shared `AmbedkarImage` widget.
- Ambedkar image containers blend with the scaffold background and use `BoxFit.contain`.
