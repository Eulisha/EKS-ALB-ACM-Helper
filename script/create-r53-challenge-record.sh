#!/usr/bin/env bash

echo "CERT_TO_USE:${CERT_TO_USE} LOADBALANCER_NAME:${LOADBALANCER_NAME} HOST_NAME:${HOST_NAME} DOMAIN_NAME:${DOMAIN_NAME} HELM_NAME:${HELM_NAME} ALB_GROUP:${ALB_GROUP} USE_PRIVATE_HOSTED_ZONE:${USE_PRIVATE_HOSTED_ZONE} NEED_BUILD_INFRA:${NEED_BUILD_INFRA}"

# get dns challengae record
echo "[ACM] Geting validation DNS challenge info..."
TIMEOUT=60
START=$(date +%s)
while [[ -z "${DNS_CHALLENGE_NAME}" || -z "${DNS_CHALLENGE_VALUE}" ]]; 
do
  sleep 3
  DNS_CHALLENGE_NAME="$(aws acm describe-certificate \
  --certificate-arn "${CERT_TO_USE}" \
  --query "Certificate.DomainValidationOptions[?DomainName==\`${HOST_NAME}.${DOMAIN_NAME}\`].ResourceRecord.Name" \
  --output text)" && true
  DNS_CHALLENGE_VALUE="$(aws acm describe-certificate \
  --certificate-arn "${CERT_TO_USE}" \
  --query "Certificate.DomainValidationOptions[?DomainName==\`${HOST_NAME}.${DOMAIN_NAME}\`].ResourceRecord.Value" \
  --output text)" && true
  echo "dns challenge name: '${DNS_CHALLENGE_NAME}' value: '${DNS_CHALLENGE_VALUE}'"

  # check if timeout has been reached
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if [[ "${ELAPSED}" -gt "${TIMEOUT}" ]]; then
    echo "Someting wrong with issuing acm cert, please check."
    exit 1
  fi
done


# Create Route53 record for ACM validation
ROUTE53_CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DNS_CHALLENGE_NAME}",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${DNS_CHALLENGE_VALUE}"
          }
        ]
      }
    }
  ]
}
EOF
)

# get hosted zone id
  ROUTE53_HOSTZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN_NAME}" \
  --query 'HostedZones[? Config.PrivateZone == `false`].Id' \
  --output text)
# Create Route53 record for ACM validation
  ROUTE53_CHANGE_BATCH_REQUEST_ID="$(aws route53 change-resource-record-sets \
  --hosted-zone-id "${ROUTE53_HOSTZONE_ID}" \
  --change-batch "${ROUTE53_CHANGE_BATCH}" \
  --query "ChangeInfo.Id" \
  --output text)"

echo "[Route 53] Creating validation records..."
aws route53 wait resource-record-sets-changed --id "${ROUTE53_CHANGE_BATCH_REQUEST_ID}"

# record change batch for cleanup
echo "${ROUTE53_CHANGE_BATCH}" > ./temp/challenge-change-batch.json
echo "ROUTE53_HOSTZONE_ID_CHALLENGE='${ROUTE53_HOSTZONE_ID}'" >> ./temp/resources