#!/bin/bash
# Setup script for Servarr stack on Ubuntu with Podman

set -e

echo "Setting up Servarr stack on Ubuntu..."

# Create config directories
echo "Creating config directories..."
sudo mkdir -p /srv/apps/{homepage,sonarr,radarr,bazarr,prowlarr,lazylibrarian,qbittorrent,qbitmanage,sabnzbd,slskd,jellyfin/{config,cache},jellyseerr,tdarr/{server,configs},unpackerr,beets}

# Set proper ownership (PUID=1000, PGID=1000)
echo "Setting permissions..."
sudo chown -R 1000:1000 /srv/apps

# Create media directories (if not using NFS)
echo "Creating media directories..."
sudo mkdir -p /mnt/media/{downloads,library/{tv,movies,anime-series,anime-movies,books,audiobooks,music},apps/tdarr/temp}
sudo mkdir -p /mnt/media/downloads/complete/{music,books,movies,tv}

# Set media permissions
sudo chown -R 1000:1000 /mnt/media

# Check if NFS is already mounted
if ! mountpoint -q /mnt/media; then
    echo "NFS not mounted. To mount manually, run:"
    echo "sudo mount -t nfs 192.168.50.186:/mnt/array1/yoho /mnt/media"
    echo ""
    echo "To mount permanently, add this line to /etc/fstab:"
    echo "192.168.50.186:/mnt/array1/yoho /mnt/media nfs defaults 0 0"
else
    echo "NFS is already mounted at /mnt/media"
fi

echo ""
echo "Setup complete! You can now run:"
echo "  podman-compose up -d"
echo ""
echo "Services will be available at:"
echo "  Homepage:     http://localhost:3000  (Dashboard)"
echo "  Sonarr:       http://localhost:8989"
echo "  Radarr:       http://localhost:7878"
echo "  Bazarr:       http://localhost:6767"
echo "  Prowlarr:     http://localhost:9696"
echo "  qBittorrent:  http://localhost:8085"
echo "  SABnzbd:      http://localhost:8082"
echo "  Jellyfin:     http://localhost:8096"
echo "  Jellyseerr:   http://localhost:5055"
echo "  LazyLibrarian: http://localhost:5299"
echo "  slskd:        http://localhost:5030"
echo "  Tdarr:        http://localhost:8265"
echo "  Beets:        http://localhost:8337"