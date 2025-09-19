#!/bin/bash
set -e

NAMESPACE="waas-clients"
CHART="./wordpress-chart"   # Path to your Helm chart
DB_ROOT_PASS="Genoras_20@25!/"

create_namespace() {
  kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE
}

generate_values_yaml() {
  local CLIENT=$1
  local CLIENT_SAFE="${CLIENT//-/_}"

  cat <<EOF
client:
  name: $CLIENT
  domain: ${CLIENT}.genoras.com   # 👈 changed from nip.io to genoras.com

mysql:
  enabled: true
  rootPassword: "$DB_ROOT_PASS"
  database: ${CLIENT_SAFE}_db
  user: ${CLIENT_SAFE}_user
  password: "$DB_ROOT_PASS"
  storage: 5Gi

wordpress:
  enabled: true
  dbHost: ${CLIENT}-mysql
  dbName: ${CLIENT_SAFE}_db
  dbUser: ${CLIENT_SAFE}_user
  dbPassword: "$DB_ROOT_PASS"
  storage: 10Gi

nginx:
  enabled: true

ingress:
  enabled: true
  host: ${CLIENT}.genoras.com   # 👈 changed from nip.io to genoras.com
EOF
}

cleanup_old_resources() {
  local CLIENT=$1
  echo "🧹 Cleaning up old resources for $CLIENT ..."

  helm uninstall "$CLIENT" -n "$NAMESPACE" || true

  kubectl delete ingress "$CLIENT-ingress" -n "$NAMESPACE" --ignore-not-found
  kubectl delete pvc -n "$NAMESPACE" --selector=app=$CLIENT --ignore-not-found
  kubectl delete pod -n "$NAMESPACE" --selector=app=$CLIENT --ignore-not-found
}

install_client() {
  local CLIENT=$1
  echo "🚀 Installing isolated WordPress for client: $CLIENT"

  create_namespace
  cleanup_old_resources "$CLIENT"

  VALUES_FILE="/tmp/${CLIENT}-values.yaml"
  generate_values_yaml "$CLIENT" > "$VALUES_FILE"

  helm upgrade --install "$CLIENT" "$CHART" \
    -f "$VALUES_FILE" \
    -n "$NAMESPACE"

  echo "🎉 WordPress deployed for $CLIENT"
  echo "🌐 Access it at: https://${CLIENT}.genoras.com"   # 👈 direct to Cloudflare SSL
}

delete_client() {
  local CLIENT=$1
  echo "🗑️  Removing WordPress for client: $CLIENT"
  cleanup_old_resources "$CLIENT"
}

case "$1" in
  install)
    install_client "$2"
    ;;
  delete)
    delete_client "$2"
    ;;
  *)
    echo "Usage: $0 {install|delete} client-name"
    ;;
esac
