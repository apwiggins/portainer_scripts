#!/usr/bin/env bash
set -e

# NOTE to future self
# this hasn't been tested yet!  Good luck!

# ==========================================
# Kubernetes Upgrade Variables
# ==========================================
NODE_IP="10.0.10.100" # Control plane node to route the upgrade through
FROM_VERSION="1.36.4" # Current version (used for logging and verification)
TO_VERSION="1.36.5"   # Target Kubernetes version

echo "=========================================="
echo " Kubernetes Cluster Upgrade"
echo "=========================================="
echo "Targeting VIP/Node : $NODE_IP"
echo "Upgrading From     : $FROM_VERSION"
echo "Upgrading To       : $TO_VERSION"
echo "=========================================="

# Perform a dry-run first so you can review the changes
echo "Performing a dry-run to check for validation errors..."
talosctl upgrade-k8s --nodes "$NODE_IP" --to "$TO_VERSION" --dry-run
echo

read -p "Does the dry-run output look correct? Proceed with upgrade? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Initiating Kubernetes upgrade..."
  talosctl upgrade-k8s --nodes "$NODE_IP" --to "$TO_VERSION"
  echo "Upgrade command issued successfully. Monitor your nodes with: watch kubectl get nodes"
else
  echo "Upgrade aborted by user."
fi
