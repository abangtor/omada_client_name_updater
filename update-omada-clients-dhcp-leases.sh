#!/bin/bash

OMADA_URL="https://192.168.0.1:443"
USERNAME="admin"
PASSWORD="adminpassword"
SITE="default"

CONTROLLER_ID="$(curl -sk "${OMADA_URL}/api/info" | jq -r .result.omadacId)"
TOKEN="$(curl -sk -X POST -c "/tmp/omada-cookies.txt" -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/login" -d '{"username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'"}' | jq -r .result.token)"
SITE_ID="$(curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE}" | jq -r .result.id)"

exit
dhcp-lease-list --parsable | while read p; do
  RAW_CLIENT_MAC=$(echo $p | sed -r 's/^MAC\s+([a-f0-9:]+)\s+.*$/\1/g')
  CLIENT_MAC=$(echo $RAW_CLIENT_MAC | tr '[:lower:]' '[:upper:]' | sed -r 's/:/-/g')
  CLIENT_NAME=$(echo $p | sed -r 's/^.*?\s+HOSTNAME\s+([a-zA-Z0-9-]+)\s+.*$/\1/g')
  test -z "${CLIENT_MAC}" && continue
  CLIENT_CURRENT_NAME=$(curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE_ID}/clients/${CLIENT_MAC}" | jq -r .result.name)
  test -z "${CLIENT_NAME}" && continue
  test "-NA-" = "${CLIENT_NAME}" && continue
  test "${CLIENT_CURRENT_NAME}" = "${CLIENT_NAME}" && continue
  curl -sk -X PATCH -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE_ID}/clients/${CLIENT_MAC}" -d "{\"name\": \"${CLIENT_NAME}\"}" > /dev/null
done
