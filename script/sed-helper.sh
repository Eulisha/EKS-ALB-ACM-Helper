#!/usr/bin/env bash

function SED_HELPER() {
  local TARGET="$1"
  local REPLACE="$2"
  local FILE="$3"

  if [[ "$(uname)" == 'Linux' ]]; then
    sed -i "s|${TARGET}|${REPLACE}|g" "${FILE}"
  elif [[ "$(uname)" == 'Darwin' ]]; then
    sed -i "" "s|${TARGET}|${REPLACE}|g" "${FILE}"
  else
    echo "Only support Mac and Linux OS"
    exit 1
  fi
}