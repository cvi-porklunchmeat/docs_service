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

mkdir -p code/bin # space for Built lambdas in local

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

# Find correct directory in Terraform to deploy application infra, terraform it
for x in $(ls -d terraform/*/ | grep -v 'deploybucket' | cut -f2 -d'/')
    do  
        KEY="${REPONAME}/${namespace}/infra/$x/terraform.tfstate"
        nampre="dev"

        cd terraform/$x

        cp "${cwd}/plans/${x}/.terraform.lock.hcl" .terraform.lock.hcl
        cp "${cwd}/plans/${x}/tfplan" tfplan

        terraform init -lockfile=readonly \
            --backend-config="key=$KEY" \
            --backend-config="bucket=$BACKENDBUCKET" \
            --backend-config="dynamodb_table=$BACKENDTABLE" \
            --backend-config="profile=$BACKENDACCT" -input=false

        echo "#############################################################"
        echo "🚧 🚧 🚧 Running Terraform apply for: ${x} 🚧 🚧 🚧"
        echo "#############################################################"
        
        terraform apply -input=false tfplan

        if [[ $? -ne 0 ]]; then
            echo "Terraform apply failed"
            exit 1
        fi

        cd $cwd

    done || exit 1
