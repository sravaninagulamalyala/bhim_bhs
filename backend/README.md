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

- `GET /auth/captcha`
- `POST /auth/login`

Admin:

- `POST /admin/members/upload-excel`
- `POST /admin/staff/create`
- `GET /admin/staff`
- `PUT /admin/staff/{id}`

Members:

- `GET /members/search?keyword=`
- `GET /members/{id}/family`
- `PUT /members/{id}`
- `POST /members/map-family`

Attendance:

- `POST /attendance/meeting`
- `POST /attendance/mark`
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

Search:

- `GET /search/member-family?keyword=`

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
- `SECRETARY`: member updates, family mapping, reports
- `GENERAL_SECRETARY`: attendance meeting creation and attendance marking/updating
- `TREASURER`: credit/debit transaction creation/updating and transaction reports
- Logged-in staff: attendance view, transaction view, member search, report download
- Public: home, member registration, active family/member counts
