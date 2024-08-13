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
mkdir -p code/bin

# Set current working dir
cwd=$(pwd)

#github token added to localized files for git auth
git config --global credential.helper store
git config --global github.token $GITHUB_TOKEN
echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
echo "[user]
	name = ${GITHUB_USER}
[credential]
	helper = store" > ~/.gitconfig

# Gather information about the deploybucket
deploy_bucket_name=$(aws s3 ls | grep -w $artifactBucket | cut -d" " -f3)
kid=$(aws kms list-aliases | jq -r --arg  ns "${artifactBucket}-s3kms" '.Aliases[] | select(.AliasName | endswith($ns)) | .TargetKeyId')
deploy_bucket_key_arn=$(aws kms describe-key --key-id ${kid} | jq -r '.KeyMetadata.Arn')

# Loop over all terraform directories but skip deploybucket
for x in $(ls -d terraform/*/ | grep -v 'deploybucket' | cut -f2 -d'/')
    do
        KEY="${REPONAME}/${namespace}/infra/$x/terraform.tfstate"

        cd terraform/$x

        terraform init \
            --backend-config="key=$KEY" \
            --backend-config="bucket=$BACKENDBUCKET" \
            --backend-config="dynamodb_table=$BACKENDTABLE" \
            --backend-config="region=$AWS_DEFAULT_REGION" \
            --backend-config="profile=$BACKEND_ACCT" -input=false

        terraform destroy \
            -var="namespace=$namespace" \
            -var="reponame=$REPONAME" \
            -var="deploy_bucket_name=$deploy_bucket_name" \
            -var="deploy_bucket_key_arn=$deploy_bucket_key_arn" \
            -auto-approve
        
        if [[ $? -ne 0 ]]; then
            echo "Unknown status returned: $result"
            exit 1
        fi

        cd $cwd

    done || exit 1

# Destroy deploybucket
cd terraform/deploybucket

TFSTATE_KEY="${REPONAME}/${namespace}/deployinfra/terraform.tfstate"

terraform init  \
    --backend-config="key=$TFSTATE_KEY" \
    --backend-config="bucket=$BACKENDBUCKET" \
    --backend-config="dynamodb_table=$BACKENDTABLE" \
    --backend-config="region=$AWS_DEFAULT_REGION" \
    --backend-config="profile=$BACKEND_ACCT" -input=false

terraform destroy \
    -var="namespace=${namespace}" \
    -var="bucketname=${artifactBucket}" \
    -var="region=$AWS_DEFAULT_REGION" \
    -auto-approve
