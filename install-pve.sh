#!/bin/bash
# Complete setup script for media server with directories, network, and local SSL domains
# Run this script with sudo privileges
#!/bin/bash
# ------------------------------
# LXC Media Mount Script
# Run this ON THE PROXMOX HOST
# ------------------------------

# Configuration - MODIFY THESE VALUES
LXC_CONTAINER_ID="102"  # Replace with your actual LXC container ID
HOST_MEDIA_PATH="/mnt/media"  # Replace with the actual host path to your media

echo "LXC MEDIA MOUNT CONFIGURATION"
echo "This script must be run on the Proxmox HOST!"
echo ""

set -e

# Safety checks
if [ ! -f "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf" ]; then
    echo "Error: LXC container ${LXC_CONTAINER_ID} not found!"
    echo "Please update LXC_CONTAINER_ID in this script."
    exit 1
fi

if [ ! -d "$HOST_MEDIA_PATH" ]; then
    echo "Error: Host media path $HOST_MEDIA_PATH does not exist!"
    echo "Please update HOST_MEDIA_PATH in this script."
    exit 1
fi

echo "Container ID: $LXC_CONTAINER_ID"
echo "Host media path: $HOST_MEDIA_PATH"
echo ""
read -p "Are these values correct? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Please edit this script and update the configuration values."
    exit 1
fi

echo ""
echo "Stopping LXC container..."
pct stop $LXC_CONTAINER_ID

echo ""
echo "Backing up current LXC config..."
cp "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf" "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf.backup-$(date +%Y%m%d-%H%M%S)"

# Step 2: Create directory structure
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

echo ""
echo "Adding mount point to LXC config..."
# Find the next available mount point number
NEXT_MP=$(grep -E "^mp[0-9]+" "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf" | sed 's/mp\([0-9]*\):.*/\1/' | sort -n | tail -1)
if [ -z "$NEXT_MP" ]; then
    NEXT_MP=0
else
    NEXT_MP=$((NEXT_MP + 1))
fi

echo "mp${NEXT_MP}: $HOST_MEDIA_PATH,mp=$HOST_MEDIA_PATH" >> "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf"

echo ""
echo "Setting up UID/GID mapping (if not already present)..."
if ! grep -q "lxc.idmap.*1000.*1000" "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf"; then
    echo "Adding UID/GID mapping..."
    cat >> "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf" << EOF

# UID/GID mapping for Docker containers
lxc.idmap: u 0 100000 1000
lxc.idmap: g 0 100000 1000
lxc.idmap: u 1000 1000 1
lxc.idmap: g 1000 1000 1
lxc.idmap: u 1001 101001 64535
lxc.idmap: g 1001 101001 64535
EOF

    # Add subuid/subgid mappings
    if ! grep -q "root:1000:1" /etc/subuid; then
        echo "root:1000:1" >> /etc/subuid
    fi
    if ! grep -q "root:1000:1" /etc/subgid; then
        echo "root:1000:1" >> /etc/subgid
    fi
    
    echo "UID/GID mapping added"
else
    echo "UID/GID mapping already present"
fi

echo ""
echo "Step 5: Setting proper ownership on host..."
chown -R 1000:1000 "$HOST_MEDIA_PATH"

echo ""
echo "Step 6: Starting LXC container..."
pct start $LXC_CONTAINER_ID

echo ""
echo "Waiting for container to fully start..."
sleep 10

echo ""
echo "MEDIA MOUNT SUCCESSFULLY CONFIGURED!"
echo ""
echo "Current LXC configuration:"
echo "----------------------------------------"
grep -E "mp[0-9]+:|lxc.idmap:" "/etc/pve/lxc/${LXC_CONTAINER_ID}.conf"
echo ""
echo "Directory structure created:"
echo "$HOST_MEDIA_PATH/"
echo "├── library/ # Final organized media"
echo "│   ├── movies/"
echo "│   ├── tv/"
echo "│   ├── anime-series/"
echo "│   ├── anime-movies/"
echo "│   ├── music/"
echo "│   └── books/"
echo "├── downloads/ # Download staging area"
echo "│   ├── complete/{movies,tv,music,books,anime-series,anime-movies}"
echo "│   ├── incomplete/"
echo "│   ├── torrents/"
echo "│   └── usenet/"
echo "└── fonts/ # Custom fonts for Jellyfin"
echo ""
echo "   How the media stack works:"
echo "   1. Downloads land in /downloads/complete/[type]/"
echo "   2. Sonarr/Radarr/etc move files to /library/[type]/"
echo "   3. Jellyfin reads from /library/[type]/"
echo "   Next steps:"
echo "1. Enter your container: pct enter $LXC_CONTAINER_ID"
echo "2. Verify mount: ls -la $HOST_MEDIA_PATH"
echo "3. Check ownership: ls -la $HOST_MEDIA_PATH (should show 1000:1000)"
echo "4. Start your Docker containers: docker-compose up -d"
echo ""
echo "If something goes wrong, restore latest backup:"
echo "ls -la /etc/pve/lxc/${LXC_CONTAINER_ID}.conf.backup-*"