#!/usr/bin/env bash
set -euo pipefail

APP_NAME="bhs-backend"
DOMAIN="${DOMAIN:-api.meghaconnect.cloud}"
APP_DIR="${APP_DIR:-/opt/bhs}"
JAR_NAME="${JAR_NAME:-bharathi-jharijana-sangam-backend.jar}"
JAR_PATH="${APP_DIR}/${JAR_NAME}"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
NGINX_FILE="/etc/nginx/sites-available/${APP_NAME}"
NGINX_LINK="/etc/nginx/sites-enabled/${APP_NAME}"
APP_PORT="${APP_PORT:-8085}"
JAVA_BIN="${JAVA_BIN:-/usr/bin/java}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash deploy.sh"
  exit 1
fi

echo "Deploying ${APP_NAME} for https://${DOMAIN}/api/v1"

apt-get update
apt-get install -y openjdk-17-jre-headless nginx certbot python3-certbot-nginx curl

if [[ ! -x "${JAVA_BIN}" ]]; then
  JAVA_BIN="$(command -v java || true)"
fi

if [[ -z "${JAVA_BIN}" || ! -x "${JAVA_BIN}" ]]; then
  echo "Java was not found. Install Java 17 and rerun this script."
  exit 1
fi

mkdir -p "${APP_DIR}"

if [[ ! -f "${JAR_PATH}" ]]; then
  LOCAL_JAR="$(find "$(pwd)" -path "*/target/${JAR_NAME}" -type f 2>/dev/null | head -n 1 || true)"
  if [[ -n "${LOCAL_JAR}" ]]; then
    cp "${LOCAL_JAR}" "${JAR_PATH}"
  else
    echo "Jar not found at ${JAR_PATH}"
    echo "Copy your jar first, for example:"
    echo "  sudo mkdir -p ${APP_DIR}"
    echo "  sudo cp backend/target/${JAR_NAME} ${JAR_PATH}"
    exit 1
  fi
fi

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Bharathiya Harijana Sangam Backend
After=network.target mysql.service

[Service]
User=root
WorkingDirectory=${APP_DIR}
ExecStart=${JAVA_BIN} -jar ${JAR_PATH} --server.port=${APP_PORT}
SuccessExitStatus=143
Restart=always
RestartSec=10
Environment=JAVA_OPTS=-Xms256m -Xmx512m

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${APP_NAME}"
systemctl restart "${APP_NAME}"

echo "Waiting for backend on localhost:${APP_PORT}..."
for _ in {1..30}; do
  if curl -fsS "http://localhost:${APP_PORT}/api/v1/public/home-content" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS "http://localhost:${APP_PORT}/api/v1/public/home-content" >/dev/null 2>&1; then
  echo "Backend did not start on localhost:${APP_PORT}."
  echo "Service status:"
  systemctl --no-pager status "${APP_NAME}" || true
  echo "Recent logs:"
  journalctl -u "${APP_NAME}" -n 80 --no-pager || true
  exit 1
fi

cat > "${NGINX_FILE}" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    client_max_body_size 25m;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sfn "${NGINX_FILE}" "${NGINX_LINK}"
nginx -t
systemctl reload nginx

if getent hosts "${DOMAIN}" >/dev/null; then
  certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos --redirect -m "admin@meghaconnect.cloud" || {
    echo "Certbot failed. Confirm DNS A record: ${DOMAIN} -> this server public IP"
    exit 1
  }
  systemctl reload nginx
else
  echo "DNS is not resolving for ${DOMAIN} yet."
  echo "Create DNS A record: ${DOMAIN} -> 187.127.162.84"
  echo "Then rerun: sudo DOMAIN=${DOMAIN} bash deploy.sh"
  exit 1
fi

echo "Deployment completed."
echo "API: https://${DOMAIN}/api/v1/public/home-content"
echo "Swagger: https://${DOMAIN}/api/v1/swagger-ui/index.html"
echo "Logs: journalctl -u ${APP_NAME} -f"
