#!/usr/bin/env bash

. bin/common.sh

ALL_OPTS="${ALL_OPTS} s3"

[ -z "$1" ] && usage

LAMBDA=$1
FAIL=0


nuke_output () {
    echo $"Nuking $LAMBDA"
    L_CMD="aws lambda delete-function"
    L_CMD="${L_CMD} --function-name StackOutputsLookup"
    bash -c "${L_CMD}"
    nuke_cfn $LAMBDA
}

nuke_cfn () {
    echo $"Nuking $LAMBDA"
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
    ${LAMBDA_CASES})
        nuke_cfn $LAMBDA
        ;;
    ${LAMBDA_OUTPUT_FN})
        nuke_output
        ;;
    ${LAMBDA_ALL})
        LAMBDA=${LAMBDA_OUTPUT_FN}
        for i in ${LAMBDA_FNS}; do
	    LAMBDA=$i
            nuke_cfn $i
        done
        nuke_output
        ;;
    "s3")
        nuke_s3
        ;;
    *)
        usage
        exit 3
esac
