#!/bin/bash
# set -e

printf \
"[CAUTION] Careful!!! The following steps will remove resources created by this project:\n \
1. Route53 record \n \
2. ACM certificate \n \
3. Helm release \n \
4. Terraform resources (EKS/VPC)"

# remind user to confirm the cleanup
read -e -n 1 -p "ARE YOU SURE TO REMOVE ALL THE RESOURCES? (Y/N)" CONFIRM
if [[ "${CONFIRM}" != "Y" ]]; then
  echo "Cancel cleanup"
  exit 0
fi

# load sed helper to adapt to different OS
source ./script/sed-helper.sh

# remove resources recorded in cleanup dir
if [[ ! -f './cleanup/*' ]]; then
  echo "No resources need to cleanup."
else
  for dir in cleanup/*/; do
    cd "${dir}" || exit
    printf \
    "###########################################################\n \
    cleaning up resources recorded in %s\n\
  ###########################################################\n" \
    "${dir}"

    # unset variables and load variables from resources file
    unset ROUTE53_HOSTZONE_ID_CHALLENGE NEW_CERT_ARN HELM_NAME ROUTE53_HOSTZONE_ID_SERVICE
    if [[ -f "./resources" ]]; then
      source ./resources

      # clean up resources reocrded in resources file
      echo "deleting helm release..."
      helm uninstall "${HELM_NAME}" --wait
      echo "deleting acm cert..."
      aws acm delete-certificate --certificate-arn "${NEW_CERT_ARN}"
    fi

    # clean up route53 dns challenge record
    if [[ -f "./challenge-change-batch.json" ]]; then
      SED_HELPER '"Action": "UPSERT"' '"Action": "DELETE"' './challenge-change-batch.json'
      echo "[Route53] Deleting Route53 challenge record..."
      ROUTE53_CHANGE_BATCH_CHALLENGE_REQUEST_ID=$(aws route53 change-resource-record-sets \
      --hosted-zone-id "${ROUTE53_HOSTZONE_ID_CHALLENGE}" \
      --change-batch file://challenge-change-batch.json \
      --query "ChangeInfo.Id" \
      --output text)
      aws route53 wait resource-record-sets-changed --id "${ROUTE53_CHANGE_BATCH_CHALLENGE_REQUEST_ID}" && echo "dns challenge record deleted."
    fi
    # clean up route53 service hostname record
    if [[ -f "./svc-change-batch.json" ]]; then
      SED_HELPER '"Action": "UPSERT"' '"Action": "DELETE"' './svc-change-batch.json'
      echo "[Route53] Deleting Route53 service hostname record..."
      ROUTE53_CHANGE_BATCH_SVC_REQUEST_ID=$(aws route53 change-resource-record-sets \
      --hosted-zone-id "${ROUTE53_HOSTZONE_ID_SERVICE}" \
      --change-batch file://svc-change-batch.json \
      --query "ChangeInfo.Id" \
      --output text)
      aws route53 wait resource-record-sets-changed --id "${ROUTE53_CHANGE_BATCH_SVC_REQUEST_ID}" \
      && echo "dns service hostname record deleted."
    fi
    cd ../..
  done

  rm -rf ./cleanup/*
fi

# remove terraform resources if state file exists
if [[ -f './infra/terraform.tfstate' ]]; then
  read -e -n 1 -p "Do you want to destroy terraform resources (EKS/VPC)? (Y/N)" DESTROY
  if [[ "${DESTROY}" == "Y" ]]; then
    echo "[Terraform] Destroying terraform resources..."
    terraform -chdir=./infra destroy
  fi
fi

echo "Cleanup completed."
