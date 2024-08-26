#!/usr/bin/env bash

set -e

ping -c 1 8.8.8.8 > /dev/null 2>&1 || { echo "No internet connection"; exit 1; }

# update all the repositories - apt, snap, flatpak
# auto-apply changes
sudo apt update && \
    sudo apt dist-upgrade -y && \
    sudo apt autoremove -y && \
    sudo snap refresh && \
    sudo flatpak update -y

# Quit and refresh Snap Store
snap-store --quit || { echo "Failed to quit snap-store"; }
sudo snap refresh snap-store

# Update Rust channel
rust_channel='stable-x86_64-unknown-linux-gnu'
RUSTUP=$HOME/.cargo/bin/rustup

$RUSTUP update $rust_channel

# no auto-apply

#sudo apt update && \
#    sudo apt dist-upgrade && \
#    sudo apt autoremove && \
#    sudo snap refresh && \
#    sudo flatpak update
