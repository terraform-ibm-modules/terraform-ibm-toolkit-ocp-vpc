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

if [[ -n "${ACL_RULES}" ]] || [[ -n "${SG_RULES}" ]]; then
  echo "ACL_RULES or SG_RULES provided"
else
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

if ! ibmcloud account show 1> /dev/null 2> /dev/null; then
  ibmcloud login --apikey "${IBMCLOUD_API_KEY}" -g "${RESOURCE_GROUP}" -r "${REGION}"
fi

# Install jq if not available
JQ=$(command -v jq || command -v ./bin/jq)

if [[ -z "${JQ}" ]]; then
  echo "jq missing. Installing"
  mkdir -p ./bin && curl -Lo ./bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  JQ="${PWD}/bin/jq"
fi

## TODO more sophisticated logic needed to 1) test for existing rules and 2) place this rule in the right order

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

    ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" "${type}" "${source}" "${destination}" \
      --name "${name}" \
      --source-port-min "${source_port_min}" \
      --source-port-max "${source_port_max}" \
      --destination-port-min "${port_min}" \
      --destination-port-max "${port_max}" \
      || exit 1
  elif [[ -n "${icmp}" ]]; then
    icmp_type=$(echo "${icmp}" | ${JQ} -r '.type // empty')
    icmp_code=$(echo "${icmp}" | ${JQ} -r '.code // empty')

    if [[ -n "${icmp_type}" ]] && [[ -n "${icmp_code}" ]]; then
      ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" icmp "${source}" "${destination}" \
        --name "${name}" \
        --icmp-type "${icmp_type}" \
        --icmp-code "${icmp_code}" \
        || exit 1
    elif [[ -n "${icmp_type}" ]]; then
      ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" icmp "${source}" "${destination}" \
        --name "${name}" \
        --icmp-type "${icmp_type}" \
        || exit 1
    else
      ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" icmp "${source}" "${destination}" \
        --name "${name}" \
        || exit 1
    fi
  else
    ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" all "${source}" "${destination}" \
      --name "${name}" \
      || exit 1
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

  RC=0

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

    ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" "${type}" "${source}" "${destination}" \
      --name "${name}" \
      --source-port-min "${port_min}" \
      --source-port-max "${port_max}" \
      --destination-port-min "${port_min}" \
      --destination-port-max "${port_max}" \
      || exit 1
  elif [[ -n "${icmp}" ]]; then
    icmp_type=$(echo "${icmp}" | ${JQ} -r '.type // empty')
    icmp_code=$(echo "${icmp}" | ${JQ} -r '.code // empty')

    if [[ -n "${icmp_type}" ]] && [[ -n "${icmp_code}" ]]; then
      ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" icmp "${source}" "${destination}" \
        --name "${name}" \
        --icmp-type "${icmp_type}" \
        --icmp-code "${icmp_code}" \
        || exit 1
    elif [[ -n "${icmp_type}" ]]; then
      ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" icmp "${source}" "${destination}" \
        --name "${name}" \
        --icmp-type "${icmp_type}" \
        || exit 1
    else
      ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" icmp "${source}" "${destination}" \
        --name "${name}" \
        || exit 1
    fi
  else
    ibmcloud is network-acl-rule-add "${NETWORK_ACL}" "${action}" "${direction}" all "${source}" "${destination}" \
      --name "${name}" \
      || exit 1
  fi
done
