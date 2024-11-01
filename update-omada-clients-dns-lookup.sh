#!/bin/bash

OMADA_URL="https://192.168.0.1:443"
USERNAME="admin"
PASSWORD="adminpassword"
SITE="default"

CONTROLLER_ID="$(curl -sk "${OMADA_URL}/api/info" | jq -r .result.omadacId)"
TOKEN="$(curl -sk -X POST -c "/tmp/omada-cookies.txt" -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/login" -d '{"username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'"}' | jq -r .result.token)"
SITE_ID="$(curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE}" | jq -r .result.id)"

curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE_ID}/insight/clients?currentPage=1&currentPageSize=65536" | jq -r '.result.data[].mac' | while read CLIENT_MAC; do
  test -z "${CLIENT_MAC}" && continue
  CLIENT_INFO=$(curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE_ID}/clients/${CLIENT_MAC}" | jq -r .result)
  CLIENT_IP=$(echo $CLIENT_INFO | jq -r .ip)
  CLIENT_OMADA_NAME=$(echo $CLIENT_INFO | jq -r .name)
  test "null" = "${CLIENT_IP}" && continue
  CLIENT_NAME=$(dig +noall +answer +short -x $CLIENT_IP | sed -r 's/\.$//g')
  test -z "$CLIENT_NAME" && continue
  test "${CLIENT_OMADA_NAME}" = "${CLIENT_NAME}" && continue
  curl -sk -X PATCH -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/${SITE_ID}/clients/${CLIENT_MAC}" -d "{\"name\": \"${CLIENT_NAME}\"}" > /dev/null
done
