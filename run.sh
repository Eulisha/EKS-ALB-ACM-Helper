#!/usr/bin/env bash
set -e

# trap exit and move resource records in temp dir to cleanup
trap 'mv ./temp ./cleanup/$(date +%Y%m%d_%H%M%S)' EXIT

sh ./script/prompt-variables.sh

source ./script/config
echo "CERT_TO_USE:${CERT_TO_USE} LOADBALANCER_NAME:${LOADBALANCER_NAME} HOST_NAME:${HOST_NAME} DOMAIN_NAME:${DOMAIN_NAME} HELM_NAME:${HELM_NAME} ALB_GROUP:${ALB_GROUP} USE_PRIVATE_HOSTED_ZONE:${USE_PRIVATE_HOSTED_ZONE} NEED_BUILD_INFRA:${NEED_BUILD_INFRA} HELM_VALUES_PATH:${HELM_VALUES_PATH}"

# create infra for playing
if [[ ${NEED_BUILD_INFRA} == 'true' ]]; then
  echo "Creating infra..."
  terraform -chdir=./infra init && terraform -chdir=./infra apply
fi

# create temp dir for cleanup resources recorded
rm -rf ./temp && mkdir ./temp

# check if alb existed and have certificate with same hostname
source ./script/get-cert-on-alb.sh

# install helm chart
source ./script/install-helm.sh

# update route53 record
source ./script/update-r53-record.sh "${USE_PRIVATE_HOSTED_ZONE}"


