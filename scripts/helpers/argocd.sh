#!/bin/sh

function deploy_argocd_app() {
  EXTERNAL_IP=$1
  ARGOCD_APPLICATION_NAME=$2
  ARGOCD_APP_YAML=$(cat $SCRIPT_DIR/../yaml/applications/$ARGOCD_APPLICATION_NAME.yaml)
  COMMAND=$(cat <<EOF
    export KUBECONFIG="/home/debian/.kube/config" # TODO: do not hardcode username but can't mix and match variables with heredoc
    echo "$ARGOCD_APP_YAML" | kubectl apply -f -
EOF
  )
  ssh debian@$EXTERNAL_IP "$COMMAND"
}

function get_argocd_password() {
  EXTERNAL_IP=$1
  COMMAND=$(cat <<EOF
    export KUBECONFIG="/home/debian/.kube/config"
    kubectl -n argocd get secret argocd-initial-admin-secret -o json | jq -r '.data.password' | base64 -d
EOF
)
  ARGOCD_PASSWORD=$(ssh -t debian@$EXTERNAL_IP "$COMMAND")
  echo "$ARGOCD_PASSWORD"
}

function sync_argocd_app() {
  EXTERNAL_IP=$1
  ARGOCD_APPLICATION_NAME=$2
  ARGOCD_PASSWORD=$3
  PIPELINE_YAML=$(cat $SCRIPT_DIR/../yaml/pipelines/argocd-task-sync-and-wait-pipeline.yaml)
  PIPELINE_YAML=$(echo "$PIPELINE_YAML" | sed "s/{{ARGOCD_APPLICATION_NAME}}/$ARGOCD_APPLICATION_NAME/g")
  PIPELINE_YAML=$(echo "$PIPELINE_YAML" | sed "s/{{ARGOCD_PASSWORD}}/$ARGOCD_PASSWORD/g")
  COMMAND=$(cat <<EOF
    set -e
    export KUBECONFIG="/home/debian/.kube/config" # TODO: do not hardcode username but can't mix and match variables with heredoc
    # cleanup any old?
    kubectl delete --ignore-not-found=true -n tekton pipelinerun/argocd-sync-and-wait-pipelinerun
    # apply new
    echo "$PIPELINE_YAML" | kubectl apply -f -
    while true
    do
      status=\$(kubectl get pipelinerun -n tekton argocd-sync-and-wait-pipelinerun -o jsonpath='{.status.conditions[0].status}')
      if [ "\$status" == "True" ]
      then
        echo "PipelineRun has completed successfully."
        break
      elif [ "\$status" == "False" ]
      then
        echo "PipelineRun has failed."
        exit 1
      else
        echo "PipelineRun is still running."
        sleep 10
      fi
    done
EOF
  )
  ssh debian@$EXTERNAL_IP "$COMMAND"
}

function deploy_and_sync_argocd_app() {
  EXTERNAL_IP=$1
  ARGOCD_APPLICATION_NAME=$2
  # get argocd password
  echo "getting argocd password"
  ARGOCD_PASSWORD=$(get_argocd_password "$EXTERNAL_IP")
  # droplet deploy argocd app
  echo "deploying argocd app"
  deploy_argocd_app "$EXTERNAL_IP" "$ARGOCD_APPLICATION_NAME"
  # droplet pipelinerun argocd sync + wait
  echo "deploying argocd sync + wait pipeline run + waiting"
  sync_argocd_app "$EXTERNAL_IP" "$ARGOCD_APPLICATION_NAME" "$ARGOCD_PASSWORD"
}
