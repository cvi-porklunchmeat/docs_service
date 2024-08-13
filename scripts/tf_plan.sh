#!/usr/bin/env bash
# shellcheck disable=all
set -ue -o pipefail

namespace=$1
BACKENDBUCKET=$2
BACKENDTABLE=$3
BACKENDACCT=$4
REPONAME=$5
AWS_DEFAULT_REGION=$6
LINEBREAK="---------------------"

# FIXME: This works, but it's assuming a lot. Maybe the caller should pass it in
artifactBucket=$(echo "${NAMESPACE}-${REPONAME,,}-artifacts" | tr '_' '-')

mkdir -p code/bin # space for Built lambdas in local
mkdir -p plans/json # space for storing terraform plans for later apply

# Set current working dir
cwd=$(pwd)

# Github token added to localized files for git auth
git config --global credential.helper store
git config --global github.token $GITHUB_TOKEN
echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
echo "[user]
	name = ${GITHUB_USER}
[credential]
	helper = store" > ~/.gitconfig

# Gather information about our backend S3 Terraform state bucket
deploy_bucket_name=$(aws s3 ls | grep -w $artifactBucket | cut -d" " -f3)
kid=$(aws kms list-aliases | jq -r --arg  ns "${artifactBucket}-s3kms" '.Aliases[] | select(.AliasName | endswith($ns)) | .TargetKeyId')
deploy_bucket_key_arn=$(aws kms describe-key --key-id ${kid} | jq -r '.KeyMetadata.Arn')

echo "artifactBucket: ${artifactBucket}"
echo "deploy_bucket_name: ${deploy_bucket_name}"
echo "kid: ${kid}"
echo "deploy_bucket_key_arn: ${deploy_bucket_key_arn}"

export TF_LOG=TRACE
export TF_LOG_PROVIDER=TRACE
export TF_LOG_PATH=/tmp/terraform_trace.log

# Find correct directory in Terraform to deploy application infra, terraform it
for x in $(ls -d terraform/*/ | grep -v 'deploybucket' | cut -f2 -d'/')
    do
        # Construct our state key for use with our backend state config
        KEY="${REPONAME}/${NAMESPACE}/infra/$x/terraform.tfstate"

        # change directory to the current terraform child directory
        cd terraform/$x

        # Create a subdirectory under plans, to store our work here
        mkdir "${cwd}/plans/${x}"

        # Init terraform, which connects to our S3/DynamoDB backend for state management
        terraform init  \
            --backend-config="key=$KEY" \
            --backend-config="bucket=$BACKENDBUCKET" \
            --backend-config="dynamodb_table=$BACKENDTABLE" \
            --backend-config="region=$AWS_DEFAULT_REGION" \
            --backend-config="profile=$BACKEND_ACCT" -input=false

        if [ "${PLAN_PROD:-}" == "TRUE" ];then
            terraform plan -lock=false -input=false \
                -var="namespace=$NAMESPACE" \
                -var="reponame=$REPONAME" \
                -var="deploy_bucket_name=$deploy_bucket_name" \
                -var="deploy_bucket_key_arn=$deploy_bucket_key_arn"

            if [[ $? -ne 0 ]]; then
                echo "Unknown status returned: $result"
                exit 1
            else
                echo "Plan for ${x} succeeded."
                exit 0
            fi

        else
            # Run a terraform plan (think Dry Run)
            terraform plan -out="${cwd}/plans/${x}/tfplan" -input=false \
                -var="namespace=$NAMESPACE" \
                -var="reponame=$REPONAME" \
                -var="deploy_bucket_name=$deploy_bucket_name" \
                -var="deploy_bucket_key_arn=$deploy_bucket_key_arn"
        fi
        
        
        if [[ $? -ne 0 ]]; then
            echo "Unknown status returned: $result"
            exit 1
        fi
        
        # Save our lock file (think package-lock.json) for the terraform apply step later
        cp .terraform.lock.hcl "${cwd}/plans/${x}/.terraform.lock.hcl"

        # View the TF Plan file, but redirect the output to a .json file for compliance checking later
        terraform show -no-color -json "${cwd}/plans/${x}/tfplan" > "${cwd}/plans/json/${x}.json" 
        
        cd $cwd

    done

echo "bundle all plans into ${cwd}/plans/tfplans.tar.gz ..."
cp "${cwd}/terraform/terraform.jq" "${cwd}/plans/" && \
tar -zcvf "/tmp/tfplans.tar.gz" "plans"
echo "complete!"
