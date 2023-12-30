#!/usr/bin/env bash

# check if this is new helm release
IS_NEW_HELM=$(helm list -q | grep -q "^${HELM_NAME}$"; echo $?) && true

# helm install/upgrade
helm upgrade --install "${HELM_NAME}" "${HELM_CHART_PATH}" \
-f "${HELM_VALUES_PATH}" \
--set ingress.albGroup="${ALB_GROUP}",ingress.albName="${LOADBALANCER_NAME}",ingress.certificateArn="${CERT_TO_USE}",ingress.hosts[0].host="${HOST_NAME}.${DOMAIN_NAME}"

# record helm name if it's new helm release
if [[ "${IS_NEW_HELM}" -eq 1 ]]; then
  echo "HELM_NAME='${HELM_NAME}'" >> ./temp/resources
fi