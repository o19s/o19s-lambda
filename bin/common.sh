#!/usr/bin/env bash

e_e () {
    #echo and exit
    echo >&2 "$1"
    exit $2
}

usage () {
    e_e $"Usage: $(basename $0) {${ALL_OPTS} all}" 1
}

lambda_fn_name () {
    eval ${2}=$(echo ${1} | tr "-" "_")
}
LAMBDA_FNS="lambda-ami-lookup lambda-ec2-sleep"
LAMBDA_OUTPUT_FN="lambda-stack-outputs-lookup"
LAMBDA_ALL="all"
ALL_OPTS="$LAMBDA_OUTPUT_FN $LAMBDA_FNS"
lambda_ami_lookup="AMILookup"
lambda_stack_outputs_lookup="StackOutputsLookup"

S3_FULL_KEY=
S3_TARGET=
[ -z "$S3Bucket" ] && S3Bucket="o19s-lambda"
[ -z "$S3Key" ] && S3Key="functions"
