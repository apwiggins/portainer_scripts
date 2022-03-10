#!/usr/bin/env bash

# remove dangling images
sudo docker image prune -f

# remove dangling volumes
sudo docker volume rm "$(docker volume ls -q -f dangling=true)"
