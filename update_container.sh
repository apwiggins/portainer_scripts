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

echo "==> Removing old volumes"
old_volumes=$(docker volume ls -q -f dangling=true)
if [ -n "$old_volumes"  ]; then                                                                        
    echo "Removing old volumes:"                                                                       
    echo "$old_volumes" | xargs docker volume rm                                                       
fi 

echo "==> pulling new ""$name"" container"
sudo docker pull "$image"
