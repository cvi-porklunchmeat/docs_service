#!/usr/bin/env bash
# shellcheck disable=all
set -ue -o pipefail
mkdir -p /tmp/code

NAMESPACE=$1
REPONAME=$2

artifactBucket=$(echo "${NAMESPACE}-${REPONAME,,}-artifacts" | tr '_' '-')

# Set current working dir
cwd=$(pwd)

# Iterate over lambda code directories and install requirements.txt
for l in $(ls -d code/lambdas/*/ | cut -f3 -d'/')
    do

        if [[ -f code/lambdas/$l/package.json ]];then
            cd code/lambdas/$l && npm ci && cd "${cwd}"
        elif [[ -f code/lambdas/$l/requirements.txt ]];then
            # Lambda environment and build env are different
            # See: https://github.com/pyca/cryptography/issues/6391
            pip3 install \
            --platform manylinux2014_x86_64 \
            --implementation cp \
            --python 3.10 \
            --only-binary=:all: \
            --upgrade \
            -r code/lambdas/$l/requirements.txt \
            --target code/lambdas/$l/
        fi

        if [ $? -ne 0 ]; then
            echo 'ERROR: Cant install code'
            exit 1
        fi

    done || exit 1

# Iterate over lambda code directories and build zip files for deploy
for l in $(ls -d code/lambdas/*/ | cut -f3 -d'/')
    do
        cd code/lambdas/$l
        zip -r9 --must-match \
        /tmp/code/$l.zip \
        ./*

        if [ $? -ne 0 ]; then
            echo 'ERROR: Cant zip code'
            exit 1
        fi

        cd $cwd

    done || exit 1
