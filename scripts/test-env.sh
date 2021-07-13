#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-env.sh
#
# This script is used predominantly by CI in order to deploy a testing environment
# for running the chart tests in this repository. The testing environment includes
# a fully functional Kubernetes cluster, usually based on a local Kubernetes
# distribution like Kubernetes in Docker (KIND).
#
# Note: Callers are responsible for cleaning up after themselves, the testing env
#       created here can be torn down with `ktf environments delete --name <NAME>`.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

if [[ -z $TEST_ENV_NAME ]]
then
    TEST_ENV_NAME="kong-charts-tests"
fi

if [[ -z $KIND_VERSION ]]
then
    KIND_VERSION="v0.11.1"
fi

if [[ ! -z $1 ]]
then
    if [[ "$1" == "cleanup" ]]
    then
        ktf environments delete --name ${TEST_ENV_NAME}
        exit $?
    fi
fi

# ------------------------------------------------------------------------------
# Shell Configuration
# ------------------------------------------------------------------------------

set -eu

# ------------------------------------------------------------------------------
# Setup Tools - Docker
# ------------------------------------------------------------------------------

# ensure docker command is accessible
if ! command -v docker &> /dev/null
then
    echo "ERROR: docker command not found"
    exit 10
fi

# ensure docker is functional
docker info 1>/dev/null

# ------------------------------------------------------------------------------
# Setup Tools - Kind
# ------------------------------------------------------------------------------

# ensure kind command is accessible
if ! command -v kind &> /dev/null
then
    go get -v sigs.k8s.io/kind@${KIND_VERSION}
fi

# ensure kind is functional
kind version 1>/dev/null

# ------------------------------------------------------------------------------
# Setup Tools - KTF
# ------------------------------------------------------------------------------

# ensure ktf command is accessible
if ! command -v ktf 1>/dev/null
then
    mkdir -p ${HOME}/.local/bin
    curl --proto '=https' -sSf https://raw.githubusercontent.com/Kong/kubernetes-testing-framework/fix/bash-install/docs/install.sh | bash
    export PATH="${HOME}/.local/bin:$PATH"
fi

# ensure kind is functional
ktf 1>/dev/null

# ------------------------------------------------------------------------------
# Configure Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
    ktf environments delete --name ${TEST_ENV_NAME}
    exit 1
}

trap cleanup SIGTERM SIGINT

# ------------------------------------------------------------------------------
# Create Testing Environment
# ------------------------------------------------------------------------------

ktf environments create --name ${TEST_ENV_NAME} --addon metallb
