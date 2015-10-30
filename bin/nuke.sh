#!/usr/bin/env bash

. bin/common.sh

ALL_OPTS="${ALL_OPTS} s3"

[ -z "$1" ] && usage

LAMBDA=$1
FAIL=0


nuke_output () {
    echo $"Nuking ${LAMBDA_OUTPUT_FN} Lambda function."
    L_CMD="aws lambda delete-function"
    L_CMD="${L_CMD} --function-name StackOutputsLookup"
    bash -c "${L_CMD}"
    nuke_cfn ${LAMBDA_OUTPUT_FN}
}

nuke_cfn () {
    echo $"Nuking $1 CloudFormation"
    CFN_CMD="aws cloudformation delete-stack"
    CFN_CMD="${CFN_CMD} --stack-name $1"
    bash -c "${CFN_CMD}"
}

nuke_s3 () {
    S3_TARGET="s3://${S3Bucket}/${S3Key}"
    echo $"Nuking ${S3_TARGET}"
    aws s3 rm ${S3_TARGET} --recursive
}
case "$LAMBDA" in
    ${LAMBDA_OUTPUT_FN})
        nuke_output
        ;;
    ${LAMBDA_ALL})
        for i in ${LAMBDA_FNS}; do
            nuke_cfn $i
        done
        nuke_output
        ;;
    "s3")
        nuke_s3
        ;;
esac

if [[ ${LAMBDA_FNS} =~ ${LAMBDA} ]]; then
    nuke_cfn $LAMBDA
fi
