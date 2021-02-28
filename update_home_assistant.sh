#!/usr/bin/env bash

name='home-assistant'
image='homeassistant/home-assistant:stable'

sh ./update_container.sh $name $image

sudo docker create \
    --name=$name \
    --net=host \
    -e PUID=1000 \
    -e GUID=1000 \
    -v /home/docker/homeassistant:/config \
    -v /etc/localtime:/etc/localtime:ro \
    --restart unless-stopped \
    $image

sudo docker start $name
