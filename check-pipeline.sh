#!/usr/bin/env sh
set -e -o nounset

# Checks the PEP FOSS pipeline that trigger-pipeline.sh started: waits for it to complete
# and exits with its status.
#
# Wait for pipeline to complete, see https://gitlab.com/gitlab-org/gitlab/-/issues/201882
# Alternative would be to use https://docs.gitlab.com/ee/ci/yaml/#trigger, but then cannot override FOSS_REF when manually activating the job
# because this is not supported. Besides, nested variables such as `$FOSS_REF: $CI_COMMIT_BRANCH` don't work with trigger:branch

contains() {
    string="$1"
    substring="$2"
    if [ "${string#*$substring}" != "$string" ]
    then
        return 0
    else
        return 1
    fi
}

pipelineid="$1"
pipeline_url="${2-}"  # Only for logging, may be empty: the API gives us one as well

if [ -z "$pipelineid" ] || [ "$pipelineid" = null ]
then
  >&2 echo 'No pipeline ID was passed on by the job that starts the pipeline.'
  >&2 echo 'Retry that job (which starts a new pipeline) and then this one.'
  exit 1
fi

foss_project_urlencoded="$(printf %s "$FOSS_PROJECT" | jq --slurp --raw-input --raw-output @uri)"
pipeline_api="$CI_API_V4_URL/projects/$foss_project_urlencoded/pipelines/$pipelineid"

echo "Waiting for $FOSS_PROJECT pipeline $pipelineid"
if [ -n "$pipeline_url" ]; then printf '%s\n' "$pipeline_url"; fi

# All possible statuses are documented on https://docs.gitlab.com/ee/api/pipelines.html. I cannot find any documentation on what these statuses mean.
# Not all statuses are listed below. I don't expect we will encounter the missing statuses, but if we do we must investigate in which category they should fall.
running_statuses="\"pending\" \"running\" \"created\" \"preparing\" \"waiting_for_resource\" \"canceling\""
success_statuses="\"success\" \"skipped\" \"manual\""
failure_statuses="\"failed\" \"canceled\""

echo 'Polling status'

last_status=''
while true
do
  response=$(curl --no-progress-meter --fail --header "JOB-TOKEN: $CI_JOB_TOKEN" "$pipeline_api")
  status=$(printf %s "$response" | jq ".status")
  pipeline_url=$(printf %s "$response" | jq --raw-output '.web_url // empty')

  if [ "$status" != "$last_status" ]; then
    printf '\n%s' "$status"
    last_status="$status"
  fi
  printf '.'

  if contains "$success_statuses" "$status"
  then
    echo
    echo "Pipeline succeeded with status: '$status'"
    exit 0
  elif contains "$failure_statuses" "$status"
  then
    echo
    echo "Pipeline failed with status: '$status'"
    echo "Retry its failed job(s) at $pipeline_url and then retry this job,"
    echo "to avoid running a whole new $FOSS_PROJECT pipeline"
    exit 1
  elif ! contains "$running_statuses" "$status"
  then
    echo
    echo "Received unsupported status \"$status\" from Gitlab API"
    exit 1
  fi

  sleep 30
done
