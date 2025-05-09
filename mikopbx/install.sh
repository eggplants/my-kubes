#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

helm install mikopbx "$SCRIPT_DIR" --set wwwUser.uid="$(id -u www-user)" --set wwwUser.gid="$(id -g www-user)"
