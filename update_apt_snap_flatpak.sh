#!/usr/bin/env bash

# update all the repositories - apt, snap, flatpak
# auto-apply changes

sudo apt update && \
    sudo apt dist-upgrade -y && \
    sudo apt autoremove -y && \
    sudo snap refresh && \
    sudo flatpak update -y
    
# no auto-apply

#sudo apt update && \
#    sudo apt dist-upgrade && \
#    sudo apt autoremove && \
#    sudo snap refresh && \
#    sudo flatpak update
