#!/usr/bin/env bash

echo "CERT_TO_USE:${CERT_TO_USE} LOADBALANCER_NAME:${LOADBALANCER_NAME} HOST_NAME:${HOST_NAME} DOMAIN_NAME:${DOMAIN_NAME} HELM_NAME:${HELM_NAME} ALB_GROUP:${ALB_GROUP} USE_PRIVATE_HOSTED_ZONE:${USE_PRIVATE_HOSTED_ZONE} NEED_BUILD_INFRA:${NEED_BUILD_INFRA}"

# check if load balancer exist
echo "[ALB] Checking if load balancer exist..."
LOADBALANCER_ARN=$(aws elbv2 describe-load-balancers --names "${LOADBALANCER_NAME}" --query LoadBalancers[0].LoadBalancerArn --output text) && true
if [[ -z "${LOADBALANCER_ARN}" ]]; then
  echo "Load balancer not exist, need to create new one."
  source ./script/create-acm-cert.sh
  return 0
fi
echo "Load balancer already exist, ARN: '${LOADBALANCER_ARN}' "

# list all certificates on load balancer
HTTPS_LISTENER=$(aws elbv2 describe-listeners \
--load-balancer-arn "${LOADBALANCER_ARN}" \
--query Listeners[?Protocol==\`HTTPS\`].ListenerArn \
--output text)
CERTIFICATE_ARNS=$(aws elbv2 describe-listener-certificates \
--listener-arn "${HTTPS_LISTENER}" \
--query Certificates[0].CertificateArn \
--output text)
IFS=' ' read -a CERTIFICATE_ARNS_ARRAY <<< "${CERTIFICATE_ARNS}"

echo "[ALB] Checking if load balancer already has cert..."
# check if load balancer has ACM certificate with project hostname
for certArn in "${CERTIFICATE_ARNS_ARRAY[@]}"
do
  CERT_INFO=$(aws acm describe-certificate --certificate-arn "${certArn}" --query Certificate.[DomainName,Status] --output text)
  if [[ "$(echo "${CERT_INFO}" | awk '{print $1}')" == "${HOST_NAME}.${DOMAIN_NAME}" && "$(echo "${CERT_INFO}" | awk '{print $2}')" == "ISSUED" ]]; then
    CERT_TO_USE=${certArn}
    echo "Load balancer has valid certificate with project hostname existed, ARN: ""${certArn}"" "
    # write cert arn to file
    echo "CERT_TO_USE=${CERT_TO_USE}" >> ./script/config
    return 0
  fi
done
# check if load balancer has ACM certificate with wildcard domain
for certArn in "${CERTIFICATE_ARNS_ARRAY[@]}"
do
  CERT_INFO=$(aws acm describe-certificate --certificate-arn "${certArn}" --query Certificate.[DomainName,Status] --output text)
  if [[ "$(echo "${CERT_INFO}" | awk '{print $1}')" == "*.${DOMAIN_NAME}" && "$(echo "${CERT_INFO}" | awk '{print $2}')" == "ISSUED" ]]; then
    CERT_TO_USE=${certArn}
    echo "Load balancer has a wildcard certificate, ARN: ""${certArn}"" "
    # write cert arn to file
    echo "CERT_TO_USE=${CERT_TO_USE}" >> ./script/config
    return 0
  fi
done

echo "No existed certificate with project hostname on load balancer."
source ./script/create-acm-cert.sh
