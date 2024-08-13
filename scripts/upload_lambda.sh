#!/usr/bin/env bash
# shellcheck disable=all
set -ue -o pipefail

NAMESPACE=$1
REPONAME=$2

artifactBucket=$(echo "${NAMESPACE}-${REPONAME,,}-artifacts" | tr '_' '-')

# Find all Lambda artifacts and upload them to the S3 artifact bucket
for i in $(ls -d /tmp/code/*.zip)
    do
        mod_name=$(basename ${i} | cut -f 1 -d '.')
        fn_name="${mod_name}-${NAMESPACE}"

        # Upload zip file to S3
        aws s3 cp \
          $i \
          "s3://${artifactBucket}/lambda/${mod_name}.zip" \
          --sse

        if [ $? -ne 0 ]; then
            echo 'ERROR: Cant upload to S3'
            exit 1
        fi

    done || exit 1
