#!/usr/bin/env bash
set -euo pipefail

CURRENT_NODE=""
trap 'printf "\nERROR: line %d: %s" "$LINENO" "$BASH_COMMAND"; \
      [[ -n "$CURRENT_NODE" ]] && printf " [node: %s]" "$CURRENT_NODE"; \
      printf "\n" >&2' ERR

# ==========================================
# Cluster & Target Configuration
# ==========================================
TALOS_VERSION="v1.14.2"
SCHEMATIC_ID="dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586"
FACTORY_IMAGE="factory.talos.dev/installer/${SCHEMATIC_ID}:${TALOS_VERSION}"

STATE_FILE=".talos_upgrade_completed"
touch "$STATE_FILE"

# ==========================================
# Helper Functions
# ==========================================

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: Required command not found: $1"
    exit 1
  }
}

is_node_completed() {
  local ip="$1"

  if grep -qxF "${ip}|${TALOS_VERSION}" "$STATE_FILE"; then
    return 0
  fi

  # Avoid grep -q in pipelines under set -o pipefail to prevent SIGPIPE (exit code 141)
  if talosctl -n "$ip" version --client=false 2>/dev/null | grep -F "$TALOS_VERSION" >/dev/null; then
    mark_node_completed "$ip"
    return 0
  fi

  return 1
}

mark_node_completed() {
  local ip="$1"
  local entry="${ip}|${TALOS_VERSION}"

  if ! grep -qxF "$entry" "$STATE_FILE"; then
    printf '%s\n' "$entry" >>"$STATE_FILE"
  fi
}

verify_node_health() {
  local ip="$1"
  local retries=10
  local delay=5
  local version_out=""
  local success=false

  echo -n "Verifying node ($ip) version via Talos API..."

  for ((i = 1; i <= retries; i++)); do
    if version_out=$(talosctl -n "$ip" version --client=false 2>&1); then
      if echo "$version_out" | grep -F "$TALOS_VERSION" >/dev/null; then
        success=true
        break
      fi
    fi
    echo -n "."
    sleep "$delay"
  done

  if [[ "$success" == "true" ]]; then
    echo " [API Verified: $TALOS_VERSION]"
  else
    echo
    echo "ERROR: Failed to verify $TALOS_VERSION on $ip after $retries attempts."
    if [[ -n "$version_out" ]]; then
      echo "Last Talos API response:"
      echo "$version_out"
    fi
    exit 1
  fi

  echo -n "Verifying Kubernetes 'Ready' status on $ip..."
  until kubectl get nodes -o jsonpath="{.items[?(@.status.addresses[*].address=='$ip')].status.conditions[?(@.type=='Ready')].status}" 2>/dev/null | grep "True" >/dev/null; do
    echo -n "."
    sleep 5
  done
  echo " [Node Ready]"
}

process_node_group() {
  local role="$1"
  shift
  local nodes=("$@")

  echo "=========================================="
  echo " Starting $role Upgrades"
  echo "=========================================="

  for ip in "${nodes[@]}"; do
    if is_node_completed "$ip"; then
      echo "[SKIP] Node $ip is already upgraded to $TALOS_VERSION."
      continue
    fi

    echo
    read -p "Upgrade $role node ($ip) to $TALOS_VERSION? [y/n/q]: " -n 1 -r reply
    echo
    case "$reply" in
    [Yy]*)
      echo "Issuing upgrade command to $ip..."
      CURRENT_NODE="$ip"
      
      talosctl -n "$ip" upgrade --image "$FACTORY_IMAGE" --preserve=true

      verify_node_health "$ip"

      mark_node_completed "$ip"
      CURRENT_NODE=""
      echo "[SUCCESS] Node $ip upgrade complete and verified."
      ;;
    [Qq]*)
      echo "Aborting script execution."
      exit 0
      ;;
    *)
      echo "[SKIP] Skipped node $ip by user choice."
      ;;
    esac
  done
}

# ==========================================
# Pre-flight Checks & Discovery
# ==========================================

require_command talosctl
require_command kubectl

echo "Checking Kubernetes API accessibility..."
if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ERROR: Unable to query Kubernetes cluster."
  exit 1
fi

NOT_READY="$(kubectl get nodes --no-headers | awk '$2 !~ /^Ready/ {print $1}')"
if [[ -n "$NOT_READY" ]]; then
  echo "ERROR: Kubernetes has nodes that are not Ready:"
  echo "$NOT_READY"
  exit 1
fi
echo "All Kubernetes nodes are Ready."

CP_IPS=$(kubectl get nodes -l node-role.kubernetes.io/control-plane \
  -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' ',')

WORKER_IPS=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' \
  -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' ',')

IFS=',' read -r -a CP_NODES <<< "$CP_IPS"
IFS=',' read -r -a WORKER_NODES <<< "$WORKER_IPS"

printf "\n==========================================\n"
printf " Sequential Extension & API Discovery\n"
printf "==========================================\n"

printf "\n=== Control Plane Nodes ===\n"
for ip in "${CP_NODES[@]}"; do
  printf "\n--- Node: %s ---\n" "$ip"
  if ! talosctl -n "$ip" get extensions 2>/dev/null; then
    echo "ERROR: Failed to query Talos extensions on Control Plane node $ip"
    exit 1
  fi
done

printf "\n=== Worker Nodes ===\n"
for ip in "${WORKER_NODES[@]}"; do
  printf "\n--- Node: %s ---\n" "$ip"
  if ! talosctl -n "$ip" get extensions 2>/dev/null; then
    echo "ERROR: Failed to query Talos extensions on Worker node $ip"
    exit 1
  fi
done

echo
echo "All node Talos APIs and extensions verified sequentially."

printf "\n=== Proposed Schematic =========================== \n"
curl -s https://factory.talos.dev/schematics/"${SCHEMATIC_ID}"
printf "\n================================================== \n\n"

# ==========================================
# Main Execution Flow
# ==========================================
echo "Talos Target Version : $TALOS_VERSION"
echo "Factory Image        : $FACTORY_IMAGE"
echo "State File           : $STATE_FILE"
echo

# 1. Process Control Plane Nodes first
process_node_group "Control Plane" "${CP_NODES[@]}"

# 2. Process Worker Nodes second
process_node_group "Worker" "${WORKER_NODES[@]}"

echo
echo "=========================================="
echo " All node groups processed successfully!"
echo "=========================================="
