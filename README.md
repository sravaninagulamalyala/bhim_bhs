# BHARATHIYA HARIJANA SANGAM

This repository contains both applications:

- `backend/` - Java 17 Spring Boot REST API
- `bhs_flutter_app/` - Flutter Android/iOS app
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
https://meghaconnect.cloud:8085/api/v1
```

## Flutter App

```bash
cd bhs_flutter_app
flutter pub get
flutter run
flutter build apk --release
```

To override the backend URL:

```bash
flutter run --dart-define=BHS_API_BASE_URL=https://meghaconnect.cloud:8085/api/v1
```
