#!/bin/bash

set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

download_cloudtrail_today() {
    
    local today=$(date +%Y/%m/%d)
    local todayNice=$(date +%Y%m%d)
    local output=cloudtrail-${todayNice}.json
    debug "save cloudtrail logs into: $output"

    if ![[ "$DRY_RUN" ]]
        aws s3 sync --region=eu-west-1 --exclude "*" --include "cloudtrail/AWSLogs/$AWS_ACCOUNT_ID/CloudTrail/eu-west-1/${today}/*.json.gz"  s3://sequenceiq-cloudtrail .
    else
        debug "skipping s3 bucket synch"
    fi

    (
      for f in ./cloudtrail/AWSLogs/$AWS_ACCOUNT_ID/CloudTrail/eu-west-1/${today}/*.gz ; do
        gunzip -c $f \
         | jq .Records[]
      done
    ) > ${output}
}

filter_by_user() {
     declare username=${1:? username required}

     local json=cloudtrail-$(date +%Y%m%d).json
     cat $json | jq -s '.[]|select(.userIdentity.arn=="arn:aws:iam::$AWS_ACCOUNT_ID:user/'$username'")|[.eventSource, .eventName]' -c | sort -u
}

main() {
  : ${DEBUG:=1}

  ARN=$(aws iam list-users --query Users[0].Arn --out text)
  AWS_ACCOUNT_ID=$(cut -d: -f 5 <<<$ARN)
  debug "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"
  
  download_cloudtrail_today
  filter_by_user "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true



