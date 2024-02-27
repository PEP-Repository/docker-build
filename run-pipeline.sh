#!/bin/sh
set -e -o nounset

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

image_tag="$1"
core_ref="$2"

echo "Running a core pipeline on $core_ref using RUNNER_IMAGE_TAG=$image_tag"
response=$(curl -sS --globoff --request POST "${CI_API_V4_URL}/projects/pep%2fcore/trigger/pipeline" \
    --data-urlencode "token=${CI_JOB_TOKEN}" \
    --data-urlencode "ref=$core_ref" \
    --data-urlencode "variables[RUNNER_IMAGE_TAG]=$image_tag")
echo "Response: ${response}"
pipelineid=$(echo "${response}" | jq ".id")
echo "Pipeline ID ${pipelineid}"
if [ "${pipelineid}" = "null" ]
then
  exit 1
fi

# Wait for pipeline to complete, see https://gitlab.com/gitlab-org/gitlab/-/issues/201882
# Alternative would be to use https://docs.gitlab.com/ee/ci/yaml/#trigger, but then one cannot override CORE_TEST_REF manually

# All possible statuses are documented on https://docs.gitlab.com/ee/api/pipelines.html. I cannot fine any documentation on what these statuses mean.
# Not all statuses are listed below. I don't expect we will encounter the missing statuses, but if we do we must investigate in which category they should fall.
running_statuses="\"pending\" \"running\" \"created\" \"preparing\" \"waiting_for_resource\""
success_statuses="\"success\" \"skipped\""
failure_statuses="\"failed\" \"canceled\""

echo 'Polling status'

last_status=''
while true
do
  status=$(curl -sS --header "PRIVATE-TOKEN:${GITLAB_ACCESS_TOKEN}" "${CI_API_V4_URL}/projects/pep%2fcore/pipelines/${pipelineid}" | jq ".status")

  if [ "$status" != "$last_status" ]; then
    printf '\n%s' "$status"
    last_status="$status"
  fi
  printf '.'

  if contains "$success_statuses" "$status"
  then
    echo "Pipeline succeeded with status: '$status'"
    exit 0
  elif contains "$failure_statuses" "$status"
  then
    echo "Pipeline failed with status: '$status'"
    exit 1
  elif ! contains "$running_statuses" "$status"
  then
    echo "Received unsupported status \"$status\" from Gitlab API"
    exit 1
  fi

  sleep 30
done
