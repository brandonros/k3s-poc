#!/bin/sh

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
. "$SCRIPT_DIR/tekton.sh"

function kaniko_build_and_push() {
  EXTERNAL_IP=$1
  GIT_URL=$2
  IMAGE=$3
  DOCKERFILE=$4
  CONTEXT=$5
  PIPELINE_YAML=$(cat $SCRIPT_DIR/../../yaml/templates/kaniko-build-and-push-pipeline.yaml)
  PIPELINE_YAML=$(echo "$PIPELINE_YAML" | sed "s#{{GIT_URL}}#$GIT_URL#g")
  PIPELINE_YAML=$(echo "$PIPELINE_YAML" | sed "s#{{IMAGE}}#$IMAGE#g")
  PIPELINE_YAML=$(echo "$PIPELINE_YAML" | sed "s#{{DOCKERFILE}}#$DOCKERFILE#g")
  PIPELINE_YAML=$(echo "$PIPELINE_YAML" | sed "s#{{CONTEXT}}#$CONTEXT#g")
  tekton_run_pipeline "$EXTERNAL_IP" "kaniko-build-and-push-pipeline-run" "$PIPELINE_YAML"
  get_tekton_pipeline_run_logs "$EXTERNAL_IP" "kaniko-build-and-push-pipeline-run"
}
