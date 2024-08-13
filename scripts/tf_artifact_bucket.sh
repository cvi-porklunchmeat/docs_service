#!/usr/bin/env bash
# shellcheck disable=all
set -ue -o pipefail
# set -x # turning this one WILL expose credentials in the CCI window and logs

namespace=$1
BACKENDBUCKET=$2
BACKENDTABLE=$3
BACKENDACCT=$4
REPONAME=$5
AWS_DEFAULT_REGION=$6

artifactBucket=$(echo "${namespace}-${REPONAME,,}-artifacts" | tr '_' '-')
kid=""

#github token added to localized files for git auth
git config --global credential.helper store
git config --global github.token $GITHUB_TOKEN
echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
echo "[user]
	name = ${GITHUB_USER}
[credential]
	helper = store" > ~/.gitconfig

echo "***** Checking for S3 bucket: ${artifactBucket}"

TFSTATE_KEY="${REPONAME}/${namespace}/deployinfra/terraform.tfstate"

cd terraform/deploybucket

terraform init  \
    --backend-config="key=$TFSTATE_KEY" \
    --backend-config="bucket=$BACKENDBUCKET" \
    --backend-config="dynamodb_table=$BACKENDTABLE" \
    --backend-config="profile=$BACKENDACCT" -input=false

terraform plan -out=tfplan -input=false \
    -var="namespace=${namespace}" \
    -var="bucketname=${artifactBucket}" \
    -var="env_name=${namespace}-${REPONAME}" \
    -var="region=$AWS_DEFAULT_REGION"

terraform apply -input=false tfplan

deploy_bucket_name=$(terraform output -raw s3_bucket_id)
deploy_bucket_key_arn=$(terraform output -raw kms_key_arn)
kid=$(terraform output -raw kms_key_arn)
