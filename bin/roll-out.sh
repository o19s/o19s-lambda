#!/usr/bin/env bash

# Set the S3 Bucket and Key prefix by settingin the environment.
# S3Bucket
# S3Key
#
# Note the S3 Bucket must exist.
set -x
e_e () {
    #echo and exit
    echo >&2 $1
    exit $2
}
command -v aws >/dev/null 2>&1 || e_e "I require aws but it's not installed.  Aborting." 1

cd $(dirname "$0")/..

LAMBDA_FNS="lambda-ami-lookup"
LAMBDA_CASES=$(echo ${LAMBDA_FNS} | tr " " "|")
LAMBDA_OUTPUT_FN="lambda-stack-outputs-lookup"
LAMBDA_ALL="all"
ALL_OPTS="$LAMBDA_FNS $LAMBDA_OUTPUT_FN $LAMBDA_ALL"

usage () {
    e_e $"Usage: $(basename $0) {${ALL_OPTS}}" 1
}

[ -z "$1" ] && usage

LAMBDA=$1
FAIL=0
[ -z "$S3Bucket" ] && S3Bucket="o19s-lambda"
[ -z "$S3Key" ] && S3Key="functions"

rollout_zip () {
    test_bucket
    [ ! -d "out" ] && { mkdir -p "out/build"; }
    TMPFILE=$(pwd)/$(mktemp -u -p out/build ${1}XXXXXX)
    ZIP_CMD="zip ${TMPFILE} ${1}.js"
    pushd src > /dev/null 2>&1
    bash -c "${ZIP_CMD}" || FAIL=1
    TMPFILE=$TMPFILE.zip
    popd > /dev/null 2>&1
    S3_FULL_KEY="${S3Key}/$(basename $TMPFILE)"
    S3_TARGET="s3://${S3Bucket}/${S3_FULL_KEY}"
    aws s3 cp ${TMPFILE} ${S3_TARGET} >/dev/null 2>&1 || e_e "Failed to copy ${S3_TARGET} from ${TMPFILE}"
    return ${S3_FULL_KEY}
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
    S3_FULL_KEY=$(rollout_zip $LAMBDA)
    rollout_output_cfn $LAMBDA
    # Poll for CFN complete, sleep for now...
    sleep 60
    OUTPUT_ARN=$(bin/cfn-value.sh StackOutputsLookupRole)
    L_CMD="aws lambda create-function"
    L_CMD="${L_CMD} --function-name StackOutputsLookup"
    L_CMD="${L_CMD} --code S3Bucket=${S3Bucket},S3Key=${S3_FULL_KEY}"
    L_CMD="${L_CMD} --role ${OUTPUT_ARN}"
    L_CMD="${L_CMD} --handler index.handler"
    L_CMD="${L_CMD} --runtime nodejs"
    bash -c "${L_CMD}"
}

test_bucket () {
    bash -c "aws s3 ls s3://${S3Bucket}" >/dev/null 2>&1 || e_e "The S3 Bucket ${S3Bucket} doesn't exist please create it." 1
}

contains() { [[ $1 =~ $2 ]] && return 0 || return 1 }

case "$LAMBDA" in
    ${LAMBDA_CASES})
        S3_FULL_KEY=$(rollout_zip $LAMBDA)
        rollout_cfn $LAMBDA ${S3_FULL_KEY}
        ;;
    ${LAMBDA_OUTPUT_FN})
        rollout_output
        ;;
    ${LAMBDA_ALL})
        rollout_zip ${LAMBDA_OUTPUT_FN}
        for i in ${LAMBDA_FNS}; do
            S3_FULL_KEY=$(rollout_zip $i)
            rollout_cfn $i ${S3_FULL_KEY}
        done
        ;;
    *)
        usage
        exit 3
esac

[ ${FAIL} == 1 ] && e_e "Oops something went wrong." 4
