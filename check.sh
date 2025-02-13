#!/bin/bash

### a script to check for newer image versions of currently running containers

# Function to get the current digest of a running container
get_local_digest() {
    local image=$1
    docker inspect --format='{{index .RepoDigests 0}}' "$image" 2>/dev/null | awk -F'@' '{print $2}'
}

# Function to get the latest digest from the registry
get_remote_digest() {
    local image=$1
    local repo=${image%:*}  # Remove tag (e.g., "akhilrex/podgrab")
    local tag=${image##*:}  # Extract tag (e.g., "latest")

    # Special handling for lscr.io images
    if [[ "$repo" == "lscr.io"* ]]; then
        # For lscr.io, use their API or pull directly to verify the latest image
        remote_digest=$(curl -fsSL "https://api.linuxserver.io/api/v1/images?include_config=false&include_deprecated=false" \
            | jq -r ".data.repositories.linuxserver[] | select(.name == \"${repo#lscr.io/}\") | .version" 2>/dev/null)
        echo "$remote_digest"
        return
    fi

    # Try using skopeo first if available
    if command -v skopeo &>/dev/null; then
        skopeo inspect --format "{{.Digest}}" "docker://$repo:$tag" 2>/dev/null
    else
        # Fallback to Docker Hub API for official and public images
        if [[ "$repo" == "library/"* ]]; then
            repo="${repo#library/}"  # Strip "library/" prefix
        fi

        remote_digest=$(curl -fsSL "https://registry.hub.docker.com/v2/repositories/$repo/tags/$tag" | jq -r '.images[0].digest' 2>/dev/null)
        echo "$remote_digest"
    fi
}

# Get running containers and check for updates
updates=()
while IFS= read -r container_id; do
    image=$(docker inspect --format='{{.Config.Image}}' "$container_id")
    local_digest=$(get_local_digest "$image")
    remote_digest=$(get_remote_digest "$image")

    if [[ -z "$remote_digest" || "$remote_digest" == "null" ]]; then
        echo "Warning: Could not retrieve remote digest for $image. Skipping..."
        continue
    fi

    if [[ "$local_digest" != "$remote_digest" ]]; then
        updates+=("- $container_id ($image) - $local_digest → $remote_digest")
    fi
done < <(docker ps -q)

# Print results
if [[ ${#updates[@]} -eq 0 ]]; then
    echo "All containers are up to date."
else
    echo "The following containers have updates available:"
    printf '%s\n' "${updates[@]}"
fi
