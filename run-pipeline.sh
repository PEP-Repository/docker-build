#!/bin/sh
pipelineid=$(curl -sS --request POST --header "PRIVATE-TOKEN:${GITLAB_ACCESS_TOKEN}" "https://gitlab.pep.cs.ru.nl/api/v4/projects/pep%2fcore/pipeline?ref=753-run-a-core-pipeline-in-docker-build-ci" | jq ".id")
echo "Pipeline ID ${pipelineid}"

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
  fi

  sleep 30
done