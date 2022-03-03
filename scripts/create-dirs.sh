#!/usr/bin/env bash

INPUT=$(tee)

TMP_DIR=$(echo "${INPUT}" | grep "tmp_dir" | sed -E 's/.*"tmp_dir": ?"([^"]*)".*/\1/g')
CLUSTER_CONFIG_DIR=$(echo "${INPUT}" | grep "cluster_config_dir" | sed -E 's/.*"cluster_config_dir": ?"([^"]*)".*/\1/g')

if [[ -n "${TMP_DIR}" ]]; then
  mkdir -p "${TMP_DIR}"
fi

if [[ -n "${CLUSTER_CONFIG_DIR}" ]]; then
  mkdir -p "${CLUSTER_CONFIG_DIR}"
fi

echo "{\"tmp_dir\": \"${TMP_DIR}\", \"cluster_config_dir\": \"${CLUSTER_CONFIG_DIR}\"}"
