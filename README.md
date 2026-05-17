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
flutter build apk --release
```

To override the backend URL:

```bash
flutter run --dart-define=BHS_API_BASE_URL=https://api.meghaconnect.cloud/api/v1
```
