#!/usr/bin/env sh
set -e -o nounset

# Starts a pipeline in the PEP FOSS repo that builds & tests PEP with the images we just built,
# and writes its ID to $dotenv_file for check-pipeline.sh, which polls it in a separate job.
# That way a retry of the checking job keeps the same pipeline, instead of starting a new one.

image_tag="$1"
foss_ref="$2"
lockfile_job="$3"
dotenv_file="$4"

foss_project_urlencoded="$(printf %s "$FOSS_PROJECT" | jq --slurp --raw-input --raw-output @uri)"

echo "Running a $FOSS_PROJECT pipeline on $foss_ref using RUNNER_IMAGE_TAG=$image_tag"
response=$(curl --no-progress-meter --fail --globoff --request POST "$CI_API_V4_URL/projects/$foss_project_urlencoded/trigger/pipeline" \
    --data-urlencode "token=$CI_JOB_TOKEN" \
    --data-urlencode "ref=$foss_ref" \
    --data-urlencode "variables[FORCE_BUILD_STABLE_RELEASE]=yes" \
    --data-urlencode "variables[RUNNER_IMAGE_TAG]=$image_tag" \
    --data-urlencode "variables[OVERRIDE_DOCKER_BUILD_REF]=$CI_COMMIT_SHA" \
    --data-urlencode "variables[DOCKER_BUILD_LOCKFILE_JOB]=$lockfile_job" \
    --data-urlencode "variables[BUILD_ALL_TARGETS]=yes"
)
pipelineid=$(printf %s "$response" | jq ".id")
echo "Pipeline ID $pipelineid"
if [ "$pipelineid" = "null" ]
then
  exit 1
fi

# Print pipeline URL
pipeline_url=$(printf %s "$response" | jq --raw-output .web_url)
printf '%s\n' "$pipeline_url"

# Set pipeline name
>/dev/null curl --no-progress-meter --fail --globoff --request PUT "$CI_API_V4_URL/projects/$foss_project_urlencoded/pipelines/$pipelineid/metadata" \
    --data-urlencode "token=$CI_JOB_TOKEN" \
    --data-urlencode "name=Testing images for docker-build pipeline $CI_PIPELINE_ID"

# Hand the pipeline over to the checking job (see artifacts:reports:dotenv)
printf 'TEST_PIPELINE_ID=%s\nTEST_PIPELINE_URL=%s\n' "$pipelineid" "$pipeline_url" >"$dotenv_file"
