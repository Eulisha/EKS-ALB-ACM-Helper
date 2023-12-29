#!/usr/bin/env bash

# ask user to input variables

# mandatory variables
source ./script/mandatory-promp-helper.sh
mandatoryInput "1. host name of your service? " HOST_NAME
mandatoryInput "2. domain name of your service? " DOMAIN_NAME
mandatoryInput "3. helm chart name? (will create if not exist) " HELM_NAME
mandatoryInput "4. loadbalancer name? (will create if not exist) " LOADBALANCER_NAME

# optional variables
read -e -r -p "5. (optional) insert the alb group name if you want to use shared ALB: " 
ALB_GROUP="${ALB_GROUP:-""}"
read -e -r -p "6. (optional) helm chart path? (default to ./helm) " HELM_CHART_PATH
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm}"
read -e -r -p "7. (optional) helm values path? (default to ./helm/values.yaml) " HELM_VALUES_PATH
HELM_VALUES_PATH="${HELM_VALUES_PATH:-./helm/values.yaml}"
read -e -r -p  "8. (optional) insert 'true' if you want to use build infra feature. " NEED_BUILD_INFRA
NEED_BUILD_INFRA="${NEED_BUILD_INFRA:-}"
read -e -r -p  "9. (optional) insert 'true' if using Route53 private hosted zone. " USE_PRIVATE_HOSTED_ZONE
USE_PRIVATE_HOSTED_ZONE="${USE_PRIVATE_HOSTED_ZONE:-}"

# write config to file
printf "HOST_NAME=%s\nDOMAIN_NAME=%s\nHELM_NAME=%s\nLOADBALANCER_NAME=%s\nALB_GROUP=%s\nHELM_CHART_PATH=%s\nHELM_VALUES_PATH=%s\nNEED_BUILD_INFRA=%s\nUSE_PRIVATE_HOSTED_ZONE=%s\n" \
  "${HOST_NAME}" "${DOMAIN_NAME}" "${HELM_NAME}" "${LOADBALANCER_NAME}" "${ALB_GROUP}" "${HELM_CHART_PATH}" "${HELM_VALUES_PATH}" "${NEED_BUILD_INFRA}" "${USE_PRIVATE_HOSTED_ZONE}" > ./script/config