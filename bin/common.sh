#!/usr/bin/env bash

e_e () {
    #echo and exit
    echo >&2 $1
    exit $2
}

usage () {
    e_e $"Usage: $(basename $0) {${ALL_OPTS} all}" 1
}

LAMBDA_FNS="lambda-ami-lookup"
LAMBDA_CASES=$(echo ${LAMBDA_FNS} | tr " " "|")
LAMBDA_OUTPUT_FN="lambda-stack-outputs-lookup"
LAMBDA_ALL="all"
ALL_OPTS="$LAMBDA_OUTPUT_FN $LAMBDA_FNS"

S3_FULL_KEY=
S3_TARGET=
[ -z "$S3Bucket" ] && S3Bucket="o19s-lambda"
[ -z "$S3Key" ] && S3Key="functions"