#!/usr/bin/env bash
# shellcheck disable=all
set -ue -o pipefail
# set -x # turning this one WILL expose credentials in the CCI window and logs

# This script populates the credentials for the pipeline
BACKEND_REGION=$1
NAMESPACE=$2
ACCT_SECRET=$3
ACCTS=($4)
# ACCTS+=($3) #uncomment to build array of secret names

# GH creds secret string
gh_creds="GITHUB_AUTO_CREDS"

# Setup credentials file
if [ ! -f ~/.aws/credentials ]; then
    mkdir -p ~/.aws
fi

# Get secrets for accounts
sj=$(aws secretsmanager get-secret-value --secret-id $ACCT_SECRET --region $BACKEND_REGION | jq -r '.SecretString')
read -d "\n" acct_id acct_key bucket table <<<$(echo $sj | jq -r '.AWS_ACCESS_KEY_ID,.AWS_SECRET_ACCESS_KEY,.BACKEND_BUCKET,.BACKEND_TABLE') || true

default=0
# place in profiles for multi-account use (first is default)
echo "[$NAMESPACE]
aws_access_key_id=$acct_id
aws_secret_access_key=$acct_key" >> ~/.aws/credentials

for acct in "${ACCTS[@]}"
do
    read ASS_KEY_ID ASS_KEY ASS_TOKEN < <(echo $(aws sts assume-role --role-arn "arn:aws:iam::${acct}:role/OrganizationAccountAccessRole" --role-session-name AWSCLI-Session --profile ${NAMESPACE} | jq -r '.Credentials | .AccessKeyId,.SecretAccessKey,.SessionToken')) && \
    if [ $default -eq 0 ]; then
        acct="default"
    fi
    echo "[$acct]
    aws_access_key_id=$ASS_KEY_ID
    aws_secret_access_key=$ASS_KEY 
    aws_session_token=$ASS_TOKEN" >> ~/.aws/credentials
    default=1
done

# github token added to localized files for git auth
read -d "\n" GITHUB_USER GITHUB_TOKEN <<<$(aws secretsmanager get-secret-value --secret-id "$gh_creds" --region $BACKEND_REGION | jq -r '.SecretString' | jq -r '.GITHUB_USER,.GITHUB_TOKEN') || true
# setup creds file for store
git config --global credential.helper store
echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
echo "[user]
	name = ${GITHUB_USER}
[credential]
	helper = store" > ~/.gitconfig
# export to shell for other use
export GITHUB_USER=$GITHUB_USER
export GITHUB_TOKEN=$GITHUB_TOKEN

# set TF backend vars in shell
if [ $bucket != "null" -a $table != "null" ]; then
    export BACKEND_BUCKET=$bucket
    export BACKEND_TABLE=$table
fi
