#!/usr/bin/env bash
# shellcheck disable=all
set -ue -o pipefail

terraform fmt --recursive -check -diff
