#!/bin/bash
# Setup script for servarr stack on docker with directories and network
# Run this script with root privileges
set -e

BASE_DIR="/srv"               # Replace with the actual base dir for your apps
HOST_MEDIA_PATH="/mnt/media"  # Replace with the actual path to your media folder

echo " Starting servarr stack setup..."
echo ""

#Create Docker network
echo "Creating Docker network 'media_net'..."
if ! docker network ls | grep -q media_net; then
    docker network create media_net
    echo "✓ Docker network 'media_net' created successfully"
else
    echo "✓ Docker network 'media_net' already exists"
fi

echo ""

# Main directory
mkdir -p "$BASE_DIR/apps"

# Reverse proxy & network utilities
mkdir -p "$BASE_DIR/apps"/{traefik,fail2ban/config,duckdns/config,gluetun}

# Download management
mkdir -p "$BASE_DIR/apps"/{slskd,unpackerr/{config,cache,logs},qbitmanage/config,qbittorrent,jellyseerr/config,sabnzbd/config,beets/config}

# Media management
mkdir -p "$BASE_DIR/apps"/{sonarr,radarr,bazarr,tdarr/{config,server},prowlarr}

# App configs
mkdir -p "$BASE_DIR/apps"/{jellyfin/{config,cache},calibre-web/data,navidrome,lazylibrarian/data}

# Traefik acme.json
touch "$BASE_DIR/apps/traefik/acme.json"
chmod 600 "$BASE_DIR/apps/traefik/acme.json"

# copying traefik.yml in the work dir

cp "traefik/traefik.yml" "$BASE_DIR/apps/traefik/traefik.yml"

# Create tun device for Gluetun
mkdir /dev/net
mknod /dev/net/tun c 10 200

echo "Setting proper ownership (1000:1000)..."
chown -R 1000:1000 "$BASE_DIR"

echo "Setting proper permissions..."
chmod -R 755 "$BASE_DIR"
chmod 600 /dev/net/tun

echo "✓ Directory structure created successfully"
echo ""

echo "Add local domains to /etc/hosts"
SERVICES=(
    "jellyfin"
    "sonarr"
    "radarr"
    "bazarr"
    "qbittorrent"
    "tdarr"
    "prowlarr"
    "sabnzbd"
    "jellyseerr"
    "calibre-web"
    "navidrome"
    "lazylibrarian"
)

# Backup current /etc/hosts
cp /etc/hosts /etc/hosts.bak

# Add local domains for each service that has a directory
echo "" | sudo tee -a /etc/hosts > /dev/null
echo "# Media Server Local Domains - Added $(date)" | sudo tee -a /etc/hosts > /dev/null

for service in "${SERVICES[@]}"; do
    if [ -d "$BASE_DIR/apps/$service" ]; then
        echo "127.0.0.1       $service.local" | sudo tee -a /etc/hosts > /dev/null
    fi
done

echo "✓ Local domains added to /etc/hosts for existing services"

read -p "Are you running this script on a proxmox unprivileged LXC with a Proxmox-mounted media directory? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo ""
    echo "🎉 Complete setup finished successfully!"
    echo ""
    echo "📁 Directory structure created:"
    echo ""
    echo "$BASE_DIR/"
    echo "└── apps/ # App configurations"
    echo "    ├── traefik/"
    echo "    ├── fail2ban/"
    echo "    │   └── config/"
    echo "    ├── duckdns/"
    echo "    │   └── config/"
    echo "    ├── gluetun/"
    echo "    ├── slskd/"
    echo "    ├── unpackerr/"
    echo "    │   ├── config/"
    echo "    │   ├── cache/"
    echo "    │   └── logs/"
    echo "    ├── qbitmanage/"
    echo "    │   └── config/"
    echo "    ├── qbittorrent/"
    echo "    ├── jellyseerr/"
    echo "    │   └── config/"
    echo "    ├── sabnzbd/"
    echo "    │   └── config/"
    echo "    ├── beets/"
    echo "    │   └── config/"
    echo "    ├── sonarr/"
    echo "    ├── radarr/"
    echo "    ├── bazarr/"
    echo "    ├── tdarr/"
    echo "    │   ├── config/"
    echo "    │   └── server/"
    echo "    ├── prowlarr/"
    echo "    ├── jellyfin/"
    echo "    │   ├── config/"
    echo "    │   └── cache/"
    echo "    ├── calibre-web/"
    echo "    │   └── data/"
    echo "    ├── navidrome/"
    echo "    └── lazylibrarian/"
    echo "        └── data/"
    echo ""
    echo "Base installation completed please run install-pve.sh on your proxmox host to complete the installation process."
    exit 1
fi

#Create directory structure
echo "Creating media directory structure at $HOST_MEDIA_PATH..."

# Create main directories
mkdir -p "$HOST_MEDIA_PATH"/{library,downloads,fonts}

# Create library directories (final media storage)
mkdir -p "$HOST_MEDIA_PATH/library"/{movies,tv,music,books,anime-series,anime-movies}

# Create downloads structure
mkdir -p "$HOST_MEDIA_PATH/downloads"/{complete,incomplete,torrents,usenet,unpackerr}
mkdir -p "$HOST_MEDIA_PATH/downloads/complete"/{movies,tv,music,books,anime-series,anime-movies}

echo "Setting proper ownership (1000:1000)..."
chown -R 1000:1000 "$HOST_MEDIA_PATH"

echo "Setting proper permissions..."
chmod -R 755 "$HOST_MEDIA_PATH"
chmod -R 775 "$HOST_MEDIA_PATH/downloads"

echo "Directory structure created successfully"
echo ""

echo "✓ Local domains added to /etc/hosts"

echo ""
echo "Complete setup finished successfully!"
echo ""
echo "Directory structure created:"
echo ""
echo "$BASE_DIR/"
echo "├── apps/ # App configurations"
echo "│   ├── traefik/"
echo "│   ├── fail2ban/"
echo "│   │   └── config/"
echo "│   ├── duckdns/"
echo "│   │   └── config/"
echo "│   ├── gluetun/"
echo "│   ├── slskd/"
echo "│   ├── unpackerr/"
echo "│   │   ├── config/"
echo "│   │   ├── cache/"
echo "│   │   └── logs/"
echo "│   ├── qbitmanage/"
echo "│   │   └── config/"
echo "│   ├── qbittorrent/"
echo "│   ├── jellyseerr/"
echo "│   │   └── config/"
echo "│   ├── sabnzbd/"
echo "│   │   └── config/"
echo "│   ├── beets/"
echo "│   │   └── config/"
echo "│   ├── sonarr/"
echo "│   ├── radarr/"
echo "│   ├── bazarr/"
echo "│   ├── tdarr/"
echo "│   │   ├── config/"
echo "│   │   └── server/"
echo "│   ├── prowlarr/"
echo "│   ├── jellyfin/"
echo "│   │   ├── config/"
echo "│   │   └── cache/"
echo "│   ├── calibre-web/"
echo "│   │   └── data/"
echo "│   ├── navidrome/"
echo "│   └── lazylibrarian/"
echo "│       └── data/"
echo "├── library/ # Final organized media"
echo "│   ├── movies/"
echo "│   ├── tv/"
echo "│   ├── music/"
echo "│   ├── books/"
echo "│   ├── anime-movies/"
echo "│   └── anime-series/"
echo "├── downloads/ # Download staging area"
echo "│   ├── complete/"
echo "│   │   ├── movies/"
echo "│   │   ├── tv/"
echo "│   │   ├── music/"
echo "│   │   ├── books/"
echo "│   │   ├── anime-series/"
echo "│   │   └── anime-movies/"
echo "│   ├── incomplete/"
echo "│   ├── torrents/"
echo "│   ├── usenet/"
echo "│   └── unpackerr/"
echo "└── fonts/ # Custom fonts for Jellyfin"
echo ""
echo "   How the media stack works:"
echo "   1. Downloads land in /downloads/complete/[type]/"
echo "   2. Sonarr/Radarr/etc move files to /library/[type]/"
echo "   3. Jellyfin/Navidrome/Calibre reads from /library/[type]/"
echo "   4. All services communicate via 'media_net' Docker network"
echo ""
echo "   Ready to start! Run:"
echo "   docker-compose up -d"
echo ""