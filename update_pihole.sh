#!/usr/bin/env bash

# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
name=pihole
image='pihole/pihole:latest'
external_dns='1.1.1.1'

echo "==> Pulling a new image from docker hub"
docker pull $image
echo "==> Stopping pihole"
docker stop $name
echo "==> removing old pihole container"
docker rm $name
echo "==> creating new container with latest image"
docker create \
    --name $name \
    -p 53:53/tcp -p 53:53/udp \
    -p 80:80 \
    -p 443:443 \
    -e TZ="America/Halifax" \
    -v "/home/docker/pihole/etc-pihole/:/etc/pihole/" \
    -v "/home/docker/pihole/etc-dnsmasq.d/:/etc/dnsmasq.d/" \
    --dns=127.0.0.1 --dns=$external_dns \
    --restart=unless-stopped \
    $image

printf '==> Starting up pihole container '
docker start $name 
for i in $(seq 1 20); do
    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
        printf ' OK'
        echo -e "\n$(docker logs pihole 2> /dev/null | grep 'password:') for your pi-hole: https://${IP}/admin/"
        exit 0
    else
        sleep 3
        printf '.'
    fi

    if [ "${i}" -eq 20 ] ; then
        echo -e "\nTimed out waiting for Pi-hole start, consult check your container logs for more info (\`docker logs pihole\`)"
        exit 1
    fi
done;

echo "==> Removing dangling volumes from old container"
docker volume rm "$(docker volume ls -q -f dangling=true)"
