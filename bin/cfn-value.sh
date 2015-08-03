#!/usr/bin/env bash

# Program will return OutputValues for key provided as the first argument of program.

command -v aws >/dev/null 2>&1 || { echo >&2 "I require aws but it's not installed.  Aborting."; exit 1; }
[ -z "$1" ] && { echo >&2 "You must provide an OutputKey to lookup."; exit 2; }
OUTPUT=$(aws cloudformation describe-stacks --output text --query 'Stacks[].Outputs[?OutputKey==`'$1'`].[OutputValue]')
[ -z "$OUTPUT" ] && { echo >&2 "Couldn't find output $1 in any Cloudformations."; exit 3; }
echo ${OUTPUT}
