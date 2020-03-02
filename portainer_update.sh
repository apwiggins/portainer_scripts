 #!/usr/bin/env bash
 
 echo "==> Stopping portainer"
 sudo docker stop portainer
 
 echo "==> Removing old portainer image"
 sudo docker rm portainer
 
 echo "==> Pulling new portainer image"
 sudo docker pull portainer/portainer
 
 echo "==> Relaunching portainer"
 sudo docker run \
     --name "portainer" \
     --restart unless-stopped \
     -d \
     -p 8000:8000 \
     -p 9000:9000 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v portainer_data:/data portainer/portainer
 
 echo "+++> done! <+++"
