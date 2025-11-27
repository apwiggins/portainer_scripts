#!/usr/bin/env bash

app="pihole"

# Path to the corresponding Docker Compose specification file
spec="./stacks/"$app".yml"

# Function to print messages in yellow
yecho() {
    tput setaf 3; echo "$@"; tput sgr0
}

# Detect whether to use 'docker compose' or 'docker-compose'
if docker compose version &>/dev/null; then
    DC=(docker compose)
elif docker-compose version &>/dev/null; then
    DC=(docker-compose)
else
    echo " Error: Neither 'docker compose' nor 'docker-compose' isinstalled."
    exit 1
fi
 
yecho $(date)" ==> pulling new image for "${app}
"${DC[@]}" -f "${spec}" pull

yecho $(date)" ==> stopping "${app}
"${DC[@]}" -f "${spec}" down

# Restart the application with the latest image
yecho $(date)" ==> refreshing "{$app}
# Use -p to assign a unique project name, avoiding conflicts when managing multiple apps
"${DC[@]}" -p "${app}" -f "${spec}" up -d --build --remove-orphans
 
yecho $(date)" ==> completed update "$app
