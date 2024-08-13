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

function run_local () {

    local namespace
    local action
    local "${@}"

    banner
    log "Params: ${*}"

    local repo_name
    repo_name=$(basename `git rev-parse --show-toplevel`)
    
    local git_sha
    local git_sha=$(git rev-parse --short HEAD)

    while [[ ! "${namespace}" =~ ^pr-[0-9]{1,}$ ]]
    do
        read -p "Namespace: " namespace
    done

    while [[ ! "${action}" =~ ^(plan|apply)$ ]]
    do
        log "What would you like to do?: plan, apply, or destroy"
        read -p "Action: " action
    done

    banner
    log "Running terraform"
    log "Action: ${action}"
    log "Repo: ${repo_name}"
    log "Namespace:${namespace}"
    log "Git sha: ${git_sha}"
    banner

    terraform "${action}" \
      -var="namespace=${namespace}" \
      -var="reponame=${repo_name}" \
      -var="git_sha=${git_sha}" \
      -var="main_account=AWSAdministratorAccess-314133070617" \
      -var="data_account=AWSAdministratorAccess-648155496553"
    
    banner

}

run_local "${@}"
