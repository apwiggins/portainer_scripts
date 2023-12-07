#!/usr/bin/env bash

# remove dangling images
sudo docker image prune -f

echo "==> Removing old volumes"
old_volumes=$(docker volume ls -q -f dangling=true)
if [ -n "$old_volumes"  ]; then                                                                        
    echo "Removing old volumes:"                                                                       
    echo "$old_volumes" | xargs docker volume rm                                                       
fi 
