 #!/usr/bin/env bash
 
 app="pihole"
 spec="./stacks/"$app".yml"
 
 yecho() {
     tput setaf 3; echo "$@"; tput sgr0
 }
 
 yecho $(date)"==> pulling new image for "$app
 docker pull pihole/pihole
 
 yecho $(date)"==> stopping "$app
 docker-compose -f $spec down
 
 yecho $(date)"==> refreshing "$app
 docker-compose -p $app -f $spec up -d --build --remove-orphans
 
 yecho $(date)"==> completed update "$app
