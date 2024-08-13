#!/usr/bin/env bash
# shellcheck disable=all
GH_PR_URL="https://api.github.com/repos/cloud-investors/$CIRCLE_PROJECT_REPONAME/pulls/${CIRCLE_PULL_REQUEST##*/}"
OP_URL="https://cloud.openproject.com/work_packages/"

UNICORN="🦄"
CHECK="✅"
SEARCH="🔎"
BUG="🐛"
OP_REGEX=".*[a-zA-Z]{1,9}[-_#]([0-9]{1,9}).*"
OP_NUMBER_REGEX="OP#[0-9]{1,9}"
OP_IN_TITLE=0
OP_IN_BRANCH=0
ACCEPT_HEADER="Accept: application/vnd.github.v3+json"

pr_branch=$(curl -s -u "${GITHUB_USER}:${GITHUB_TOKEN}" -H ${ACCEPT_HEADER} ${GH_PR_URL} | jq -r .head.ref)
pr_body=$(curl -s -u "${GITHUB_USER}:${GITHUB_TOKEN}" -H ${ACCEPT_HEADER} ${GH_PR_URL} | jq .body)
pr_title=$(curl -s -u "${GITHUB_USER}:${GITHUB_TOKEN}" -H ${ACCEPT_HEADER} ${GH_PR_URL} | jq -r .title)

#echo "PR Title: ${pr_title}"
#echo "PR Branch: ${pr_branch}"
#echo "PR Body: $pr_body"

echo "--------------------"

echo "${SEARCH} Checking for OP# in title or branch..."
if [[ "$( echo ${pr_title} | grep -E ${OP_REGEX})" ]]; then

    op_match=$(echo ${pr_title} | grep -E ${OP_REGEX})
    echo "${CHECK} Matched on Title: ${op_match}"
    OP_IN_TITLE=1

elif [[ "$( echo ${pr_branch} | grep -E ${OP_REGEX})" ]]; then

    op_match=$(echo ${pr_branch} | grep -E ${OP_REGEX})
    echo "${CHECK} Matched on Branch: ${op_match}"
    OP_IN_BRANCH=1

else
    echo "${UNICORN} OP# was not found in branch or title. Skipping PR update logic"
    exit 0
fi

# Capture the OP number to use later
op=$(echo ${op_match} | pcre2grep -o1 ${OP_REGEX})
echo "${CHECK} Captured: ${op}"

echo "--------------------"

echo "${SEARCH} Checking for OP# in body..."
if [[ -z "$(echo $pr_body | grep -E ${OP_NUMBER_REGEX})" ]]; then
    echo "${UNICORN} Attempting to update body..."

    # Due to the possible carriage returns in the body, we manipulate the body on the fly
    # If we echo the body into a variable at anypoint to change it, the structure breaks and fails to PATCH
    get_body=$(curl -s -u "${GITHUB_USER}:${GITHUB_TOKEN}" -H ${ACCEPT_HEADER} ${GH_PR_URL} | jq .body | sed "s|\"|\"[OP#${op}](${OP_URL}${op})\\\r\\\n|")
    
    if [[ $? -ne 0 ]]; then
        echo "${BUG} Unable to GET PR Body\n${BUG} Skipping"
        echo "${get_body}"
        #exit 0
    fi
    
    # Construct the new JSON to PATCH to GitHub
    new_body="{\"body\": ${get_body}}"

    update_body=$(curl -s -X PATCH -u "${GITHUB_USER}:${GITHUB_TOKEN}" -H ${ACCEPT_HEADER} ${GH_PR_URL} --data-binary "${new_body}")

    if [[ $? -ne 0 ]]; then
        echo "${BUG} Unable to PATCH PR Body\n${BUG} Skipping"
        echo "${update_body}"
        #exit 0
    fi

else
    body_match=$(echo ${pr_body} | grep -E ${OP_NUMBER_REGEX})
    echo "${CHECK} Found: ${body_match}"

fi

echo "--------------------"

if [[ ${OP_IN_TITLE} -eq 0 ]]; then
    echo "${SEARCH} Checking for OP# in title..."
    if [[ -z "$( echo ${pr_title} | grep -E ${OP_NUMBER_REGEX})" ]]; then
        echo "${UNICORN} Attempting to update title..."
        update_title=$(curl -s -X PATCH -u "${GITHUB_USER}:${GITHUB_TOKEN}" -H ${ACCEPT_HEADER} ${GH_PR_URL} -d "{\"title\":\"[OP#${op}] ${pr_title}\"}")

        if [[ $? -ne 0 ]]; then
            echo "${BUG} Unable to PATCH PR Title\n${BUG} Stopping script"
            echo "${update_title}"
            exit 0
        fi

    else
        title_match=$(echo ${pr_title} | grep -E ${OP_NUMBER_REGEX})
        echo "${CHECK} Found: ${title_match}"
    fi
else
    echo "${CHECK} Found OP# in title, so no need to modify it."
fi

echo "--------------------"