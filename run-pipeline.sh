#!/bin/sh
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


echo "CI_COMMIT_REF_NAME: ${CI_COMMIT_REF_NAME}"
response=$(curl -sS --globoff --request POST --header "PRIVATE-TOKEN:${GITLAB_ACCESS_TOKEN}" \
    "https://gitlab.pep.cs.ru.nl/api/v4/projects/pep%2fcore/pipeline?ref=master&variables[][key]=RUNNER_IMAGE_TAG&variables[][value]=${CI_COMMIT_REF_NAME}")
echo "Response: ${response}"
pipelineid=$(echo "${response}" | jq ".id")
echo "Pipeline ID ${pipelineid}"
if [ "${pipelineid}" = "null" ]
then
  exit 1
fi

# POSIX shell does not have arrays, so we're using strings. The quotes are there so we can easily check for the whole word, otherwise substrings would also match
# All possible statuses are documented on https://docs.gitlab.com/ee/api/pipelines.html. I cannot fine any documentation on what these statuses mean.
# Not all statuses are listed below. I don't expect we will encounter the missing statuses, but if we do we must investigate in which category they should fall.
running_statuses="'pending' 'running' 'created' 'preparing' 'waiting_for_resource'"
success_statuses="'success' 'skipped'"
failure_statuses="'failed' 'canceled'"


status="\"pending\""
while contains "$running_statuses" "'$status'"
do
  status=$(curl -sS --header "PRIVATE-TOKEN:${GITLAB_ACCESS_TOKEN}" "https://gitlab.pep.cs.ru.nl/api/v4/projects/pep%2fcore/pipelines/${pipelineid}" | jq ".status")

  if contains "$success_statuses" "'$status'"
  then
    echo "Pipeline succeeded with status: '$status'"
    exit 0
  elif contains "$failure_statuses" "'$status'"
  then
    echo "Pipeline failed with status: '$status'"
    exit 1
  elif not contains "$running_statuses" "'$status'"
  then
    echo "Received unsupported status \"$status\" from Gitlab API"
    exit 1
  fi

  sleep 30
done
