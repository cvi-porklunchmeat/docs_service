#!/usr/bin/env bash
# shellcheck disable=all
#set -ue -o pipefail

logo="[🅰 🅱 cloud]"
cyan='\e[1;36m'
reset='\e[m'

function banner (){
    local columns=$(tput cols)
    local script="[${0##*/}]"
    local width="(( ${#logo} + ${#script} ))"
    local adjust=$((columns - width ))
    printf "${logo}"
    printf '%0.s-' $(seq 1 $adjust)
    printf [${0##*/}]
    printf "\n"
}

function log (){
    printf "${logo} ${cyan}${1:-}${reset}\n"
}

function init_local () {

    banner
    log "Params: ${*}"
    banner

    # List of AWS accounts we need to authenticate to
    local required_accounts=("00000000001" "314133070617" "648155496553")

    local script_location
    local parent_dir
    local repo_name
    local namespace
    local key
    local region

    local "${@}"

    local bucket="cloud-mgmt-terraform-state-s3"
    local table="cloud-mgmt-terraform-state-dynamo"

    if [[ $(cat ~/.aws/config | grep "[sso-session abcloud]") ]]
    then
        log "Found AWS Session Profile: abcloud"
    else
        log "Unable to find sso-session profile: abcloud in ~/.aws/config"
        log "Adding a this SSO session profile to ~/.aws/config ..."
        printf "\n[sso-session abcloud]\nsso_start_url = https://d-90670bdc4f.awsapps.com/start\nsso_region = us-east-1\nsso_registration_scopes = sso:account:access\n\n" >> ~/.aws/config
    fi

    script_location=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    tf_dir="${script_location##*/}"
    repo_name=$(basename `git rev-parse --show-toplevel`)

    while [[ ! "${namespace}" =~ ^pr-[0-9]{1,}$ ]]
    do
        read -p "Namespace: " namespace
    done

    while [[ ! "${region}" ]]
    do
        read -p "Region: " region
    done

    key="${repo_name}/${namespace}/infra/${tf_dir}/terraform.tfstate"

    rm -rf .terraform

    banner
    log "Checking for an AWS profile tied to accounts: ${required_accounts[*]} ..."
    banner

    local current_profile
    local current_account_id
    local profiles=()

    # Read the file line by line
    while IFS= read -r line; do
        # Check if the line is a profile header
        if [[ $line =~  ^\[profile\ ([^\]]+)\]$ ]]; then
            # Extract the profile name and update the current profile
            current_profile="${BASH_REMATCH[1]}"
        elif [[ $line == *"sso_account_id"* ]]; then
            # Extract the account ID using sed
            current_account_id=$(echo "$line" | sed -n 's/^sso_account_id[[:space:]]*=[[:space:]]*\([0-9]*\).*$/\1/p')
            profiles+=("$current_account_id=$current_profile")
        fi
    done < ~/.aws/config

    for req in ${required_accounts[*]}
    do 
        log "🔍 - Required account: ${req}"
        local found=false
        for prof in ${profiles[*]}
        do 
            if [[ "${req}" == "${prof%%=*}" ]]; then
                log "✅ Found profile: ${prof} for account: ${req}"
                [[ $(aws sts get-caller-identity --profile "${prof#*=}") ]] && log "✅ - Active creds found" || aws sso login --sso-session abcloud
                found=true
                [[ ${req} == "00000000001" ]] && local mgmt_acct="${prof#*=}"
                break
            fi
        done
        if [[ "${found}" == "false" ]]; then
            log "❌ - No profile found for account: ${req}"
            log "Please run 'aws configure sso' and use the SSO session name 'abcloud' and run this script again"
            exit 1
        fi
    done

    banner
    log "Targeting TF: ${tf_dir}"
    log "Backend State Key: ${key}"
    log "Backend Bucket: ${bucket}"
    log "Backend Table: ${table}"
    log "Backend Region: ${region}"
    log "Backend Profile: ${mgmt_acct}"
    banner

    terraform init  \
        --backend-config="key=${key}" \
        --backend-config="bucket=${bucket}" \
        --backend-config="dynamodb_table=${table}" \
        --backend-config="region=${region}" \
        --backend-config="profile=${mgmt_acct}" -input=false

    log
    log "Terraform: Success 🎉"
    banner
    log ">>> Make sure your terraform providers are using the correct profiles"
}

init_local "${@}"
