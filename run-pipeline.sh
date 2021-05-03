#!/bin/sh
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

status="\"pending\""
while [ "$status" = "\"pending\"" ] || [ "$status" = "\"running\"" ]
do
  status=$(curl -sS --header "PRIVATE-TOKEN:${GITLAB_ACCESS_TOKEN}" "https://gitlab.pep.cs.ru.nl/api/v4/projects/pep%2fcore/pipelines/${pipelineid}" | jq ".status")
  if [ "$status" = "\"success\"" ]
  then
    echo "Pipeline succeeded"
    exit 0
  elif [ "$status" = "\"skipped\"" ]
  then
    echo "Pipeline skipped"
    exit 0
  elif [ "$status" = "\"failed\"" ]
  then
    echo "Pipeline failed"
    exit 1
  elif [ "$status" = "\"canceled\"" ]
  then
    echo "Pipeline canceled"
    exit 1
  elif [ "$status" != "\"pending\"" ] && [ "$status" != "\"running\"" ]
    echo "Received unsupported status \"$status\" from Gitlab API"
    exit 1
  fi

  sleep 30
done
