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

if [[ -z "${ACL_RULES}" ]] || [[ -z "${SG_RULES}" ]]; then
  echo "ACL_RULES or SG_RULES environment variable must be set"
  exit 0
fi

SEMAPHORE="acl_rules.semaphore"

while true; do
  echo "Checking for semaphore"
  if [[ ! -f "${SEMAPHORE}" ]]; then
    echo -n "${NETWORK_ACL}" > "${SEMAPHORE}"

    if [[ $(cat ${SEMAPHORE}) == "${NETWORK_ACL}" ]]; then
      echo "Got the semaphore. Creating acl rules"
      break
    fi
  fi

  SLEEP_TIME=$((1 + $RANDOM % 10))
  echo "  Waiting $SLEEP_TIME seconds for semaphore"
  sleep $SLEEP_TIME
done

function finish {
  rm "${SEMAPHORE}"
}

trap finish EXIT

# Install jq if not available
JQ=$(command -v jq || command -v ./bin/jq)

if [[ -z "${JQ}" ]]; then
  echo "jq missing. Installing"
  mkdir -p ./bin && curl -Lo ./bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  JQ="${PWD}/bin/jq"
fi

echo "Getting IBM Cloud API access_token"
TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | ${JQ} -r '.access_token // empty')

if [[ -z "${TOKEN}" ]]; then
  echo "Error retrieving auth token"
  exit 1
fi

## TODO more sophisticated logic needed to 1) test for existing rules and 2) place this rule in the right order

VERSION="2021-06-30"

echo "Processing ACL_RULES"
echo "${ACL_RULES}" | ${JQ} -c '.[]' | \
  while read rule;
do
  name=$(echo "${rule}" | ${JQ} -r '.name')
  action=$(echo "${rule}" | ${JQ} -r '.action')
  direction=$(echo "${rule}" | ${JQ} -r '.direction')
  source=$(echo "${rule}" | ${JQ} -r '.source')
  destination=$(echo "${rule}" | ${JQ} -r '.destination')

  tcp=$(echo "${rule}" | ${JQ} -c '.tcp // empty')
  udp=$(echo "${rule}" | ${JQ} -c '.udp // empty')
  icmp=$(echo "${rule}" | ${JQ} -c '.icmp // empty')

  if [[ -n "${tcp}" ]] || [[ -n "${udp}" ]]; then
    if [[ -n "${tcp}" ]]; then
      type="tcp"
      config="${tcp}"
    else
      type="udp"
      config="${udp}"
    fi

    source_port_min=$(echo "${config}" | ${JQ} -r '.source_port_min')
    source_port_max=$(echo "${config}" | ${JQ} -r '.source_port_max')
    port_min=$(echo "${config}" | ${JQ} -r '.port_min')
    port_max=$(echo "${config}" | ${JQ} -r '.port_max')

    RULE=$(${JQ} -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "${type}" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      --argjson source_port_min "${source_port_min}" \
      --argjson source_port_max "${source_port_max}" \
      --argjson destination_port_min "${port_min}" \
      --argjson destination_port_max "${port_max}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, destination_port_min: $destination_port_min, destination_port_max: $destination_port_max, source_port_min: $source_port_min, source_port_max: $source_port_max}')
  elif [[ -n "${icmp}" ]]; then
    icmp_type=$(echo "${icmp}" | ${JQ} -r '.type // empty')
    icmp_code=$(echo "${icmp}" | ${JQ} -r '.code // empty')

    if [[ -n "${icmp_type}" ]] && [[ -n "${icmp_code}" ]]; then
      RULE=$(${JQ} -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson code "${icmp_code}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, code: $code, type: $type}')
    elif [[ -n "${icmp_type}" ]]; then
      RULE=$(${JQ} -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, type: $type}')
    else
      RULE=$(${JQ} -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
    fi
  else
    RULE=$(${JQ} -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "all" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
  fi

  echo "Creating rule: ${RULE}"

  RESULT=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
    -X POST \
    "https://${REGION}.iaas.cloud.ibm.com/v1/network_acls/${NETWORK_ACL}/rules?version=${VERSION}&generation=2" \
    -d "${RULE}")

  ID=$(echo "${RESULT}" | ${JQ} -r '.id // empty')

  if [[ -z "${ID}" ]]; then
    echo "Error creating rule: ${rule}"
    echo "${RESULT}"
    exit 1
  fi
done

echo "Processing SG_RULES"
echo "${SG_RULES}" | ${JQ} -c '.[]' | \
  while read rule;
do
  name=$(echo "${rule}" | ${JQ} -r '.name')
  action="allow"
  direction=$(echo "${rule}" | ${JQ} -r '.direction')
  remote=$(echo "${rule}" | ${JQ} -r '.remote')

  if [[ "${direction}" == "inbound" ]]; then
    source="${remote}"
    destination="0.0.0.0/0"
  else
    destination="${remote}"
    source="0.0.0.0/0"
  fi

  tcp=$(echo "${rule}" | ${JQ} -c '.tcp // empty')
  udp=$(echo "${rule}" | ${JQ} -c '.udp // empty')
  icmp=$(echo "${rule}" | ${JQ} -c '.icmp // empty')

  if [[ -n "${tcp}" ]] || [[ -n "${udp}" ]]; then
    if [[ -n "${tcp}" ]]; then
      type="tcp"
      config="${tcp}"
    else
      type="udp"
      config="${udp}"
    fi

    port_min=$(echo "${config}" | ${JQ} -r '.port_min')
    port_max=$(echo "${config}" | ${JQ} -r '.port_max')

    RULE=$(${JQ} -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "${type}" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      --argjson source_port_min "${port_min}" \
      --argjson source_port_max "${port_max}" \
      --argjson destination_port_min "${port_min}" \
      --argjson destination_port_max "${port_max}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, destination_port_min: $destination_port_min, destination_port_max: $destination_port_max, source_port_min: $source_port_min, source_port_max: $source_port_max}')
  elif [[ -n "${icmp}" ]]; then
    icmp_type=$(echo "${icmp}" | ${JQ} -r '.type // empty')
    icmp_code=$(echo "${icmp}" | ${JQ} -r '.code // empty')

    if [[ -n "${icmp_type}" ]] && [[ -n "${icmp_code}" ]]; then
      RULE=$(${JQ} -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson code "${icmp_code}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, code: $code, type: $type}')
    elif [[ -n "${icmp_type}" ]]; then
      RULE=$(${JQ} -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, type: $type}')
    else
      RULE=$(${JQ} -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
    fi
  else
    RULE=$(${JQ} -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "all" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
  fi

  echo "Creating rule: ${RULE}"

  RESULT=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
    -X POST \
    "https://${REGION}.iaas.cloud.ibm.com/v1/network_acls/${NETWORK_ACL}/rules?version=${VERSION}&generation=2" \
    -d "${RULE}")

  ID=$(echo "${RESULT}" | ${JQ} -r '.id // empty')

  if [[ -z "${ID}" ]]; then
    echo "Error creating rule: ${rule}"
    echo "${RESULT}"
    exit 1
  fi
done
