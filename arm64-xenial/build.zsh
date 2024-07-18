#!/bin/zsh

sudo podman build --log-level=debug --squash --ulimit nofile=2048:2048 -f base/Containerfile -t base:latest
sudo podman build --log-level=debug --squash --ulimit nofile=2048:2048 -f crosstool/Containerfile -t crosstool:latest
sudo podman build --log-level=debug --squash --ulimit nofile=2048:2048 -f Containerfile -t arm64:latest
