#!/usr/bin/env bash

INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | grep bin_dir | sed -E 's/.*"bin_dir": ?"([^"]*)".*/\1/g')

export PATH="${BIN_DIR}:${PATH}"

PUBLIC_ENDPOINT=$(echo "${INPUT}" | jq -r '.public_endpoint')
PUBLIC_SERVER_URL=$(echo "${INPUT}" | jq -r '.public_server_url')
PRIVATE_SERVER_URL=$(echo "${INPUT}" | jq -r '.private_server_url')
IBMCLOUD_API_KEY=$(echo "${INPUT}" | jq -r '.ibmcloud_api_key')
USERNAME=$(echo "${INPUT}" | jq -r '.username')
TOKEN=$(echo "${INPUT}" | jq -r '.token')

if [[ "${PUBLIC_ENDPOINT}" == "true" ]]; then
  SERVER_URL="${PUBLIC_SERVER_URL}"
else
  SERVER_URL="${PRIVATE_SERVER_URL}"
fi

jq -n \
  --arg SERVER_URL "${SERVER_URL}" \
  --arg USERNAME "${USERNAME}" \
  --arg PASSWORD "${IBMCLOUD_API_KEY}" \
  --arg TOKEN "${TOKEN}" \
  '{"server_url": $SERVER_URL,"username": $USERNAME, "password": $PASSWORD, "token": $TOKEN}'
