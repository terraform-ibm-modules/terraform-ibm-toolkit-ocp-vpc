#!/usr/bin/env bash

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

CLUSTER_CRED=$(cat .cluster_creds)

SERVER_URL=$(echo "${CLUSTER_CRED}" | jq -r '.server_url')
USERNAME=$(echo "${CLUSTER_CRED}" | jq -r '.username')
PASSWORD=$(echo "${CLUSTER_CRED}" | jq -r '.password')
TOKEN=$(echo "${CLUSTER_CRED}" | jq -r '.token')

if [[ -n "${TOKEN}" ]]; then
  echo "Logging into OpenShift cluster ${SERVER_URL} as token"
  oc login "${SERVER_URL}" --token "${TOKEN}"
else
  echo "Logging into OpenShift cluster ${SERVER_URL} as user ${USERNAME}"
  oc login "${SERVER_URL}" --username "${USERNAME}" --password "${PASSWORD}"
fi
