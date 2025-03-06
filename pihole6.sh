#!/usr/bin/env bash

app="pihole"

# Path to the corresponding Docker Compose specification file
spec="./stacks/"$app".yml"

# Function to print messages in yellow
yecho() {
    tput setaf 3; echo "$@"; tput sgr0
}

yecho $(date)" ==> pulling new image for "$app
docker pull pihole/pihole

yecho $(date)" ==> stopping "$app
docker-compose -f $spec down

# Restart the application with the latest image
yecho $(date)" ==> refreshing "$app
# Use -p to assign a unique project name, avoiding conflicts when managing multiple apps
docker-compose -p $app -f $spec up -d --build --remove-orphans

yecho $(date)" ==> completed update "$app
