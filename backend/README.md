# bharathi-jharijana-sangam-backend

Lightweight Java 17 Spring Boot backend for **BHARATHIYA HARIJANA SANGAM** family/member management.

## Association

- Name: BHARATHIYA HARIJANA SANGAM
- Registration No: Reg 46/2614
- Address: H.No: 7-6-110, Gowtham Nagar, Bowenpally, Hyderabad - 500011
- Base URL: `https://api.meghaconnect.cloud/api/v1`
- Local URL: `http://localhost:8085/api/v1`

## Stack

- Java 17
- Spring Boot 3.x
- Spring Security + JWT
- MySQL database `bhs_db`
- Maven
- JPA/Hibernate
- Lombok
- Apache POI
- Swagger/OpenAPI

## Database

The app uses Hibernate `ddl-auto: update` for first-release deployment. It creates/updates:

- `staff_table`
- `members_table`
- `family_table`
- `member_registration_request`
- `meeting_table`
- `attendance_table`
- `transaction_table`
- `audit_log_table`

Default datasource:

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/bhs_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
    username: root
    password: root
```

## Default Login

On startup, the app inserts this staff user if it does not exist:

- adminId: `admin`
- password: `welcome`
- role: `SUPER_ADMIN`
- active: `true`

The password is stored with BCrypt.

## Build

```bash
mvn clean package
```

## Run

```bash
java -jar target/bharathi-jharijana-sangam-backend.jar --server.port=8085
```

This backend runs on port `8085` and does not disturb any existing `8080` app.

## Swagger

```text
https://api.meghaconnect.cloud/api/v1/swagger-ui.html
```

## Main APIs

Public:

- `GET /public/home-content`
- `GET /public/counts`
- `POST /public/member-registration`

Auth:

- `POST /auth/login`

Login no longer requires captcha. Request body:

```json
{
  "adminId": "admin",
  "password": "welcome"
}
```

Admin:

- `POST /admin/members/upload-excel`
- `POST /admin/staff/create`
- `GET /admin/staff`
- `PUT /admin/staff/{id}`

Members:

- `GET /members/search?keyword=`
- `GET /members/{id}/family`
- `GET /members/{id}/details`
- `PUT /members/{id}`
- `POST /members/map-family`
- `POST /members/family/remove`
- `POST /members/family/add`

Attendance:

- `GET /attendance/meeting-by-date?date=yyyy-MM-dd`
- `POST /attendance/meeting`
- `POST /attendance/mark`
- `GET /attendance/meeting-dates?month=yyyy-MM`
- `GET /attendance/by-meeting/{meetingId}`
- `GET /attendance/by-date?date=yyyy-MM-dd`

Transactions:

- `POST /transactions`
- `GET /transactions`
- `GET /transactions/balance`
- `GET /transactions/monthly-summary?month=2026-05`

Reports:

- `GET /reports/family-member-count`
- `GET /reports/monthly-contribution?month=2026-05`
- `GET /reports/contributed-families?month=2026-05`
- `GET /reports/non-contributed-families?month=2026-05`
- `GET /reports/heatmap?month=2026-05`
- `GET /reports/download?type=CONTRIBUTED&month=2026-05`
- `GET /reports/download-members`

Search:

- `GET /search/member-family?keyword=`
- `GET /search/members?keyword=`
- `GET /families/search?keyword=`

## Attendance Flow

- Attendance marking is date-first: select a calendar date, load the meeting for that date, or create one with `POST /attendance/meeting`.
- `POST /attendance/mark` accepts `meetingId` and `attendanceList`; attendance rows are unique by `meeting_id + member_id`.
- Existing attendance rows are updated, new rows are inserted, `marked_by` is stored from the logged-in staff user, and create/update actions are audited.
- Attendance viewing is calendar-based: `GET /attendance/meeting-dates?month=yyyy-MM` returns highlighted meeting dates and counts, and `GET /attendance/by-date?date=yyyy-MM-dd` returns meeting details plus present and absent marked members.

## Search and Family Correction Flow

- Logged-in staff can use `GET /search/members?keyword=` to search by name, mobile, house number, or family code.
- `GET /members/{id}/details` returns the selected member, associated family, and all active family members.
- `GET /families/search?keyword=` searches by family code, house number, family head name, family member name, or mobile number.
- `POST /members/map-family` maps a selected member to a selected family and is available to logged-in staff.
- `POST /members/family/remove` removes a member from a family after validation and audit logging.
- `POST /members/family/add` maps a member to a target family after validation and audit logging.

## Report Downloads

- Family report Excel downloads include family head name, family code, house number, area, family member names, mobile numbers, contribution status, contribution amount, month, and remarks.
- Family head name uses `primary_member_id` when present, otherwise the eldest active member by age, otherwise the first active member in that family.
- `GET /reports/download-members` exports all members with member details, family head, family code, address, and active status.

## Excel Upload Notes

Upload `Register-bhs.xlsx` as multipart form field `file` to:

```text
POST /admin/members/upload-excel
```

The importer maps common header names for member name, father/husband name, relation, age, sex, mobile, address, house number, area, and caste. Address parsing and family grouping are isolated in utility/service classes so the rules can be refined after reviewing real production data.

Address examples:

- `7-8-226,Goutham nagar,Ferozguda` -> house no `7-8-226`, area `Goutham nagar,Ferozguda`
- `7-7-29/1` -> house no `7-7-29/1`, area empty

Mobile examples:

- empty -> empty mobile fields
- `9999999999/8888888888` -> mobile `9999999999`, alternate mobile `8888888888`

## Roles

- `SUPER_ADMIN`: login, Excel upload, staff creation, member administration, reports, search, view-only attendance/transactions
- `SECRETARY`: member updates, family mapping, reports, attendance meeting creation and attendance marking/updating
- `SUPER_ADMIN`, `GENERAL_SECRETARY`, `JOINT_SECRETARY`, `ORG_SECRETARY`, `SECRETARY`: attendance meeting creation and attendance marking/updating
- `TREASURER`: credit/debit transaction creation/updating and transaction reports
- Logged-in staff: attendance view, transaction view, member search, member detail update, family mapping/correction actions, report download
- Public: home, member registration, active family/member counts
