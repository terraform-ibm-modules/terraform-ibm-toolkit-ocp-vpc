#!/usr/bin/env bash

NETWORK_ACL="$1"
REGION="$2"
RESOURCE_GROUP="$3"

if [[ -z "${NETWORK_ACL}" ]] || [[ -z "${REGION}" ]] || [[ -z "${RESOURCE_GROUP}" ]]; then
  echo "Usage: open-acl-rules.sh NETWORK_ACL REGION RESOURCE_GROUP"
  exit 1
fi

if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
  echo "IBMCLOUD_API_KEY environment variable must be set"
  exit 1
fi

ibmcloud login --apikey "${IBMCLOUD_API_KEY}" -g "${RESOURCE_GROUP}" -r "${REGION}"

ibmcloud is network-acl-rule-add "${NETWORK_ACL}" allow inbound all "0.0.0.0/0" "0.0.0.0/0" --name allow-all-ingress
ibmcloud is network-acl-rule-add "${NETWORK_ACL}" allow outbound all "0.0.0.0/0" "0.0.0.0/0" --name allow-all-egress
