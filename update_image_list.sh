#!/usr/bin/env bash

sudo docker image prune -a

image_list=$(cat ./image.list)
for image in $image_list
do
    sudo docker pull $image
done
