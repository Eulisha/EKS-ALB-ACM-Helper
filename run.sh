#!/usr/bin/env bash
# set -e

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

# create temp dir for cleanup
mkdir ./temp

# check if alb existed and have certificate with same hostname
sh ./script/get-cert-on-alb.sh

# install helm chart
sh ./script/install-helm.sh

# update route53 record
sh ./script/update-r53-record.sh "${USE_PRIVATE_HOSTED_ZONE}"

# move temp dir to cleanup dir with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mv ./temp "./cleanup/${TIMESTAMP}"