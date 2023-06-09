#!/bin/sh

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
. "$SCRIPT_DIR/config.sh"
. "$SCRIPT_DIR/helpers/digitalocean.sh"
. "$SCRIPT_DIR/helpers/argocd.sh"

# get droplet external IP
echo "getting droplet external IP..."
EXTERNAL_IP=$(digitalocean_get_droplet_external_ip_by_name "$DROPLET_NAME")
if [ "$EXTERNAL_IP" == "null" ]
then
  echo "failed to get EXTERNAL_IP"
  exit 1
fi
# get argocd password
echo "getting argocd password"
ARGOCD_PASSWORD=$(get_argocd_password "$EXTERNAL_IP")
# droplet pipeline run argocd sync + wait
echo "deploying argocd sync + wait pipeline run + waiting"
# sync
ARGOCD_APPLICATION_NAME=$1
sync_argocd_app "$EXTERNAL_IP" "$ARGOCD_APPLICATION_NAME" "$ARGOCD_PASSWORD"
