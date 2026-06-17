# BHARATHIYA HARIJANA SANGAM

This repository contains both applications:

- `backend/` - Java 17 Spring Boot REST API
- `bhs_flutter_app/` - Flutter Android/iOS app named `bhim_bhs`
- `doc/` - source documents such as `Register-bhs.xlsx`

## Backend

```bash
cd backend
mvn clean package
java -jar target/bharathi-jharijana-sangam-backend.jar --server.port=8085
```

Backend local base URL:

```text
http://localhost:8085/api/v1
```

Production base URL:

```text
https://api.meghaconnect.cloud/api/v1
```

## Server Deployment

Create this DNS record in the `meghaconnect.cloud` domain panel before running the script:

```text
api.meghaconnect.cloud  A  187.127.162.84
```

Build and copy the backend jar to the server:

```bash
cd backend
mvn clean package
sudo mkdir -p /opt/bhs
sudo cp target/bharathi-jharijana-sangam-backend.jar /opt/bhs/
```

Run deployment on the server:

```bash
sudo bash deploy.sh
```

The script creates a `bhs-backend` systemd service, proxies `https://api.meghaconnect.cloud` through Nginx to `localhost:8085`, and installs the Let's Encrypt certificate.

Useful checks:

```bash
systemctl status bhs-backend
journalctl -u bhs-backend -f
curl https://api.meghaconnect.cloud/api/v1/public/home-content
```

## Flutter App

```bash
cd bhs_flutter_app
flutter pub get
flutter run
flutter build apk --release --build-name=1.0.0 --build-number=1
```

To override the backend URL:

```bash
flutter run --dart-define=BHS_API_BASE_URL=https://api.meghaconnect.cloud/api/v1
```

## Attendance And Search Updates

- Attendance marking is available to `SUPER_ADMIN`, `GENERAL_SECRETARY`, `JOINT_SECRETARY`, `ORG_SECRETARY`, and `SECRETARY`.
- Any logged-in staff can view attendance.
- Mark Attendance now starts with a date picker: the app loads an existing meeting for the selected date or shows `Create Meeting for Selected Date`, then lets staff search members and save attendance without typing a meeting ID.
- Attendance marking supports insert/update for existing member rows on the selected meeting.
- View Attendance uses a calendar; dates with meetings are highlighted green, and selecting a green date loads meeting details plus present and absent marked members.
- View Attendance member cards include attendance ID-backed edit and delete actions for allowed roles. Edit updates attended status; delete soft-removes a mistaken attendance record.
- Member Search supports name, mobile, house number, and family code. Results include a View action that opens member details, associated family details, and all family members.
- Family correction actions allow logged-in staff to remove a wrongly tagged member or add/map another member to the selected family after confirmation.
- Login no longer uses captcha; staff login sends only admin ID and password.
- Family Mapping can search families by family code, house number, family head name, any family member name, or mobile number.
- Report downloads now include family head name, family member names, mobile numbers, contribution status, contribution amount, month, and remarks.
- Reports include `Download All Members`.
- All logged-in staff can update member details from the Search module.
- Flutter uses a global non-dismissible Ambedkar loading popup for API calls and long save/download operations.
- The drawer header was removed; the left menu now shows only role-based menu options.
- Ambedkar images now use a shared `AmbedkarImage` widget so Splash, Home, and loading states share the same background-blending treatment.
- Ambedkar image containers use `BoxFit.contain`, rounded backgrounds that match the scaffold, and avoid visible texture boundaries.

## Transaction Statement Updates

- All logged-in staff can view the transaction statement by month.
- `TREASURER` and `SUPER_ADMIN` can add credit/debit transactions with transaction date, amount, purpose, remarks, and optional family/member selection for credits.
- Monthly statement view shows opening balance, total credit, total debit, closing balance, and bank-statement style transaction rows.
- Statement rows include date, credit/debit type, purpose, remarks, credit amount, debit amount, and balance after transaction.
- A simple credit/debit percentage bar diagram appears above the statement list.
- Monthly Excel statement download is available from the transaction screen.
- Backend balance calculation uses opening balance before the selected month, applies credit/debit rows in date order, and stores recalculated `balanceAfterTransaction` values when new transactions are added.

Key backend endpoints:

- `GET /attendance/meeting-by-date?date=yyyy-MM-dd`
- `POST /attendance/meeting`
- `POST /attendance/mark`
- `PUT /attendance/{attendanceId}`
- `DELETE /attendance/{attendanceId}`
- `GET /attendance/meeting-dates?month=yyyy-MM`
- `GET /attendance/by-date?date=yyyy-MM-dd`
- `POST /transactions`
- `GET /transactions/monthly-statement?month=yyyy-MM`
- `GET /transactions/download-statement?month=yyyy-MM`
- `GET /search/members?keyword=`
- `GET /families/search?keyword=`
- `GET /members/{memberId}/details`
- `PUT /members/{memberId}`
- `POST /members/map-family`
- `POST /members/family/remove`
- `POST /members/family/add`
- `GET /reports/download-members`
