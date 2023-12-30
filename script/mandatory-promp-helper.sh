#!/usr/bin/env bash

MAX_TRIES=3

function mandatoryInput() {
    local PROMPT="$1"
    local VARIABLE_NAME="$2"
    local TRIES=0

    while [[ $TRIES -lt $MAX_TRIES ]]; do
        read -e -r -p "${PROMPT}" "${VARIABLE_NAME}"

        if [[ -n "${!VARIABLE_NAME}" ]]; then
            echo "You entered: ${!VARIABLE_NAME}"
            return 0
        else
            (( TRIES++ ))
            echo "This is the mandatory argument. Please enter a value."
        fi
    done

    echo "Exceeded maximum number of tries. Exiting."
    exit 1
}
