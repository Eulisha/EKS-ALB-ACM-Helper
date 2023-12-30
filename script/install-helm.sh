#!/usr/bin/env bash

echo "CERT_TO_USE:${CERT_TO_USE} LOADBALANCER_NAME:${LOADBALANCER_NAME} HOST_NAME:${HOST_NAME} DOMAIN_NAME:${DOMAIN_NAME} HELM_NAME:${HELM_NAME} ALB_GROUP:${ALB_GROUP} USE_PRIVATE_HOSTED_ZONE:${USE_PRIVATE_HOSTED_ZONE} NEED_BUILD_INFRA:${NEED_BUILD_INFRA}"

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