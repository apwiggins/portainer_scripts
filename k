#!/usr/bin/env bash
# k is for local kubeconfig

configs=()

# check for local configs in the current working directory
for local_file in "./kubeconfig" "./.kubeconfig" "./config"; do
  if [[ -f "$local_file" ]]; then
    configs+=("$(realpath "$local_file")")
  fi
done

# include existing KUBECONFIG environment variable paths if set
if [[ -n "${KUBECONFIG:-}" ]]; then
  IFS=':' read -ra env_configs <<<"$KUBECONFIG"
  for cfg in "${env_configs[@]}"; do
    if [[ -f "$cfg" ]]; then
      configs+=("$cfg")
    fi
  done
fi

# fall back to global default (~/.kube/config)
if [[ -f "$HOME/.kube/config" ]]; then
  configs+=("$HOME/.kube/config")
fi

# merge paths into colon-separated KUBECONFIG list
if [[ ${#configs[@]} -gt 0 ]]; then
  export KUBECONFIG=$(
    IFS=:
    echo "${configs[*]}"
  )
fi

# Locate the kubectl binary, excluding this script to prevent recursion
REAL_KUBECTL=$(which -a kubectl | grep -v "$0" | head -n 1)

if [[ -z "$REAL_KUBECTL" ]]; then
  echo "Error: standard kubectl binary not found in PATH." >&2
  exit 1
fi

exec "$REAL_KUBECTL" "$@"
