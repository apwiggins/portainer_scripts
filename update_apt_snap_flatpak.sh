#!/usr/bin/env bash

# update all the repositories - apt, snap, flatpak
# auto-apply changes

sudo apt update && \
    sudo apt dist-upgrade -y && \
    sudo apt autoremove -y && \
    sudo snap refresh && \
    sudo flatpak update -y  && \
    /snap/bin/rustup update 'stable-x86_64-unknown-linux-gnu' && \
    snap-store --quit && sudo snap refresh snap-store
    
# no auto-apply

#sudo apt update && \
#    sudo apt dist-upgrade && \
#    sudo apt autoremove && \
#    sudo snap refresh && \
#    sudo flatpak update
