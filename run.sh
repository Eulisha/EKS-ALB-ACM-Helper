#!/usr/bin/env bash
set -e

# trap exit and move resource records in temp dir to cleanup
trap 'mv ./temp ./cleanup/$(date +%Y%m%d_%H%M%S)' EXIT

source ./script/mandatory-promp-helper.sh

mandatoryInput "Already prepare config file in script folder? (y/n) " USE_CONFIG_FILE
if [[ ${USE_CONFIG_FILE} == 'n' ]]; then
  # start prompt
  sh ./script/prompt-variables.sh
else
  # check if config file exist
  if [[ ! -f ./script/config ]]; then
    echo "Config file not found. Please write config file and place it in ./script/config first."
    exit 1
  fi
fi

source ./script/config

# create infra for playing
if [[ ${NEED_BUILD_INFRA} == 'y' ]]; then
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


