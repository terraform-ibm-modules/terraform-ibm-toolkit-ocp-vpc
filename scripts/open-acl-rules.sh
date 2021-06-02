#!/usr/bin/env bash

NETWORK_ACL="$1"

## TODO more sophisiticated logic needed to 1) test for existing rules and 2) place this rule in the right order

ibmcloud is network-acl-rule-add "${NETWORK_ACL}" allow inbound all "0.0.0.0/0" "0.0.0.0/0" --name allow-all-ingress
ibmcloud is network-acl-rule-add "${NETWORK_ACL}" allow outbound all "0.0.0.0/0" "0.0.0.0/0" --name allow-all-egress
