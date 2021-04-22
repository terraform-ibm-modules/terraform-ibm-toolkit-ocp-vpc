#!/usr/bin/env bash

if [[ -z "${KUBECONFIG}" ]]; then
  echo "KUBECONFIG environment variable required"
  exit 1
fi

echo "Waiting for cluster config to settle"
sleep 300

count=0
while [[ ! -f "${KUBECONFIG}" ]]; do
  if [[ $count -eq 10 ]]; then
    echo "Timed out waiting for KUBECONFIG"
    exit 1
  fi

  echo "KUBECONFIG file not available yet: ${KUBECONFIG}. Sleeping... "
  sleep 30

  count=$((count + 1))
done

count=0
while ! kubectl api-resources 1> /dev/null; do
  if [[ $count -eq 10 ]]; then
    echo "Timed out waiting for login to cluster"
    exit 1
  fi

  echo "No access yet to cluster. Sleeping..."
  sleep 30

  count=$((count + 1))
done
