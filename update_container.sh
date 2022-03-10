#!/usr/bin/env bash

# usage: update_container.sh [container_name] [container_image]

name=$1
image=$2

echo "==> stopping " "$name"
sudo docker stop "${name}"

echo "==> removing old ""${name}"" container"
sudo docker rm "$name"

echo "==> removing old images"
sudo docker image prune -f

echo "==> removing old volumes"
sudo docker volume rm " 'docker volume ls -q -f dangling=true}' "

echo "==> pulling new ""$name"" container"
sudo docker pull "$image"
