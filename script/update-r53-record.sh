#!/usr/bin/env bash

# handle hostname with wildcard
if [[ "${HOST_NAME}" == "*" ]]; then
  HOST_NAME="*"
  HOST_NAME_SEARCH="\\052"
else
  HOST_NAME_SEARCH="${HOST_NAME}"
fi

USE_PRIVATE_HOSTED_ZONE="$1"

# get hosted zone id
if [[ ${USE_PRIVATE_HOSTED_ZONE} == 'y' ]]; then
  echo "Use private hosted zone."
  ROUTE53_HOSTZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN_NAME}" \
  --query 'HostedZones[? Config.PrivateZone == `true`].Id' \
  --output text)
else
  echo "Use public hosted zone."
  ROUTE53_HOSTZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN_NAME}" \
  --query 'HostedZones[? Config.PrivateZone == `false`].Id' \
  --output text)
fi

# wait for ALB ready to get DNS name
echo "[ALB] Waiting for ALB ready..."
aws elbv2 wait load-balancer-exists --names "${LOADBALANCER_NAME}"

# get ALB DNS name
ALB_DNS_NAME=$(aws elbv2 describe-load-balancers \
--names "${LOADBALANCER_NAME}" \
--query 'LoadBalancers[0]'.DNSName \
--output text)

# check if record existed
echo "[Route53] Checking Route53 hostname record"
HOSTNAME_RECORD=$(aws route53 list-resource-record-sets \
--hosted-zone-id "${ROUTE53_HOSTZONE_ID}" \
--query "ResourceRecordSets[?Name=='${HOST_NAME_SEARCH}.${DOMAIN_NAME}.'].ResourceRecords" \
--output text) && true
echo "Record: ${HOSTNAME_RECORD}"

if [[ "${HOSTNAME_RECORD}" == "${ALB_DNS_NAME}" ]]; then
  echo "Record with ALB dns name already existed."
  exit 0
elif [[ -n "${HOSTNAME_RECORD}" && "${HOSTNAME_RECORD}" != "${ALB_DNS_NAME}" ]]; then
  echo "Record with value other than ALB dns name exist, please check it can delete first."
  exit 0
fi

echo "[Route53] Record not exist, creating..."
# add route53 record
ROUTE53_CHANGE_BATCH_HOSTNAME=$(cat <<EOM
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${HOST_NAME}.${DOMAIN_NAME}",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${ALB_DNS_NAME}"
          }
        ]
      }
    }
  ]
}
EOM
)

ROUTE53_CHANGE_BATCH_REQUEST_ID=$(aws route53 change-resource-record-sets \
--hosted-zone-id "${ROUTE53_HOSTZONE_ID}" \
--change-batch "${ROUTE53_CHANGE_BATCH_HOSTNAME}" \
--query "ChangeInfo.Id" \
--output text)
aws route53 wait resource-record-sets-changed --id "${ROUTE53_CHANGE_BATCH_REQUEST_ID}"
HOSTNAME_RECORD=$(aws route53 list-resource-record-sets --hosted-zone-id "${ROUTE53_HOSTZONE_ID}" --query "ResourceRecordSets[?Name=='${HOST_NAME_SEARCH}.${DOMAIN_NAME}.']")


# record change batch for cleanup
echo "${ROUTE53_CHANGE_BATCH_HOSTNAME}" > ./temp/svc-change-batch.json
echo "ROUTE53_HOSTZONE_ID_SERVICE='${ROUTE53_HOSTZONE_ID}'" >> ./temp/resources

# Show result
echo "route53 record update sccessfully, Record INFO: ${HOSTNAME_RECORD}"
