#!/usr/bin/env bash

if [ -n "${DEBUG}" ]; then set -x; fi
# Set the S3 Bucket and Key prefix by settingin the environment.
# S3Bucket
# S3Key
#
# Note the S3 Bucket must exist.
command -v aws >/dev/null 2>&1 || e_e "I require aws but it's not installed.  Aborting." 1

cd $(dirname "$0")/..

. bin/common.sh

[ -z "$1" ] && usage

LAMBDA=$1
FAIL=0

rollout_zip () {
    test_bucket
    [ ! -d "out/build" ] && { mkdir -p "out/build"; }
    TMPFILE=$(pwd)/$(mktemp -u -p out/build ${1}XXXXXX)
    ZIP_CMD="zip ${TMPFILE} $(basename $(ls src/${1}.*))"
    pushd src > /dev/null 2>&1
    bash -c "${ZIP_CMD}" > /dev/null 2>&1 || FAIL=1
    TMPFILE=$TMPFILE.zip
    popd > /dev/null 2>&1
    S3_FULL_KEY="${S3Key}/$(basename $TMPFILE)"
    S3_TARGET="s3://${S3Bucket}/${S3_FULL_KEY}"
    aws s3 cp ${TMPFILE} ${S3_TARGET} >/dev/null 2>&1 || e_e "Failed to copy ${S3_TARGET} from ${TMPFILE}"
}

rollout_cfn () {
    CFN_CMD="aws cloudformation create-stack"
    CFN_CMD="${CFN_CMD} --stack-name $1"
    CFN_CMD="${CFN_CMD} --capabilities CAPABILITY_IAM"
    CFN_CMD="${CFN_CMD} --parameters"
    CFN_CMD="${CFN_CMD} ParameterKey=S3Bucket,ParameterValue=${S3Bucket}"
    CFN_CMD="${CFN_CMD} ParameterKey=S3Key,ParameterValue=${2}"
    CFN_CMD="${CFN_CMD} --template-body file://./cloudformation/${1}.json"
    bash -c "${CFN_CMD}"
}

rollout_output_cfn() {
    CFN_CMD="aws cloudformation create-stack"
    CFN_CMD="${CFN_CMD} --stack-name $1"
    CFN_CMD="${CFN_CMD} --capabilities CAPABILITY_IAM"
    CFN_CMD="${CFN_CMD} --template-body file://./cloudformation/${1}.json"
    bash -c "${CFN_CMD}"
}

rollout_output () {
    rollout_zip $LAMBDA
    rollout_output_cfn $LAMBDA
    # Poll for CFN complete, sleep for now...
    sleep 60
    OUTPUT_ARN=$(bin/cfn-value.sh StackOutputsLookupRole)
    L_CMD="aws lambda create-function"
    L_CMD="${L_CMD} --function-name StackOutputsLookup"
    L_CMD="${L_CMD} --code S3Bucket=${S3Bucket},S3Key=${S3_FULL_KEY}"
    L_CMD="${L_CMD} --role ${OUTPUT_ARN}"
    L_CMD="${L_CMD} --handler lambda-stack-outputs-lookup.handler"
    L_CMD="${L_CMD} --runtime nodejs"
    L_CMD="${L_CMD} --timeout 10"
    bash -c "${L_CMD}"
}

test_bucket () {
    bash -c "aws s3 ls s3://${S3Bucket}" >/dev/null 2>&1 || e_e "The S3 Bucket ${S3Bucket} doesn't exist please create it." 1
}

case "$LAMBDA" in
    ${LAMBDA_OUTPUT_FN})
        rollout_output
        ;;
    ${LAMBDA_ALL})
        LAMBDA=${LAMBDA_OUTPUT_FN}
        rollout_output
        for i in ${LAMBDA_FNS}; do
            rollout_zip $i
            rollout_cfn $i ${S3_FULL_KEY}
        done
        ;;
esac

if [[ ${LAMBDA_FNS} =~ ${LAMBDA} ]]; then
    rollout_zip $LAMBDA
    rollout_cfn $LAMBDA ${S3_FULL_KEY}
fi

[ ${FAIL} == 1 ] && e_e "Oops something went wrong." 4
