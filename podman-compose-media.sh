#!/bin/bash
# Wrapper script for podman-compose with keep-id namespace
# This ensures proper permissions with NFS mounts

cd "$(dirname "$0")"
PODMAN_USERNS=keep-id podman-compose "$@"