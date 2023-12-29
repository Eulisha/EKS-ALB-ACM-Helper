#!/usr/bin/env bash
# set -e
# export CERT_TO_USE
source ./script/config
echo "CERT_TO_USE:${CERT_TO_USE} LOADBALANCER_NAME:${LOADBALANCER_NAME} HOST_NAME:${HOST_NAME} DOMAIN_NAME:${DOMAIN_NAME} HELM_NAME:${HELM_NAME} ALB_GROUP:${ALB_GROUP} USE_PRIVATE_HOSTED_ZONE:${USE_PRIVATE_HOSTED_ZONE} NEED_BUILD_INFRA:${NEED_BUILD_INFRA}"

# request new ACM certificate
echo "ACM certificate not exist, need to create new one."
echo "[ACM] creating certificate..."
CERT_TO_USE=$(aws acm request-certificate \
--domain-name "${HOST_NAME}.${DOMAIN_NAME}" \
--validation-method DNS \
--output text)
# write cert arn to file
echo "CERT_TO_USE=${CERT_TO_USE}" >> ./script/config

# execute DNS challenge validation
sh ./script/create-r53-challenge-record.sh

# Wait ACM certificate validation
echo "[ACM] Validating certificate..."
aws acm wait certificate-validated --certificate-arn "${CERT_TO_USE}"

# Show cert result
ACM_CERTIFICATE="$(aws acm describe-certificate --certificate-arn "${CERT_TO_USE}" --output json)"
echo "acm issued sccessfully, CERT INFO: ${ACM_CERTIFICATE} "
echo "NEW_CERT_ARN='${CERT_TO_USE}'" >> ./temp/resources