#!/bin/bash
# Test script to verify Servarr stack configuration

echo "=== Servarr Stack Configuration Test ==="
echo ""

# Check if running on Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "✓ OS: $NAME $VERSION"
else
    echo "⚠ Cannot determine OS version"
fi

# Check if Podman is installed
if command -v podman &> /dev/null; then
    echo "✓ Podman version: $(podman --version)"
else
    echo "✗ Podman is not installed"
    echo "  Install with: sudo apt-get install podman"
fi

# Check if podman-compose is installed
if command -v podman-compose &> /dev/null; then
    echo "✓ Podman-compose is installed"
else
    echo "✗ Podman-compose is not installed"
    echo "  Install with: pip3 install podman-compose"
fi

# Check NFS mount
echo ""
echo "=== NFS Mount Status ==="
if mountpoint -q /mnt/media; then
    echo "✓ /mnt/media is mounted"
    df -h /mnt/media | tail -1
else
    echo "✗ /mnt/media is not mounted"
    echo "  Mount with: sudo mount -t nfs 192.168.50.186:/mnt/array1/yoho /mnt/media"
fi

# Check config directories
echo ""
echo "=== Config Directories ==="
if [ -d /srv/apps ]; then
    echo "✓ /srv/apps exists"
    # Check ownership
    OWNER=$(stat -c %u /srv/apps)
    if [ "$OWNER" = "1000" ]; then
        echo "✓ Ownership is correct (UID 1000)"
    else
        echo "⚠ Ownership is UID $OWNER (should be 1000)"
        echo "  Fix with: sudo chown -R 1000:1000 /srv/apps"
    fi
else
    echo "✗ /srv/apps does not exist"
    echo "  Create with: sudo mkdir -p /srv/apps && sudo chown -R 1000:1000 /srv/apps"
fi

# Check media directories
echo ""
echo "=== Media Directories ==="
for dir in downloads library library/tv library/movies library/music library/books; do
    if [ -d "/mnt/media/$dir" ]; then
        echo "✓ /mnt/media/$dir exists"
    else
        echo "✗ /mnt/media/$dir does not exist"
    fi
done

# Check network
echo ""
echo "=== Podman Network ==="
if podman network exists media_net 2>/dev/null; then
    echo "✓ media_net network exists"
else
    echo "⚠ media_net network will be created on first run"
fi

# Check port availability
echo ""
echo "=== Port Availability ==="
PORTS="3000 8989 7878 6767 9696 8085 8082 8096 5055 5299 5030 8265 8337"
for PORT in $PORTS; do
    if netstat -tln 2>/dev/null | grep -q ":$PORT "; then
        SERVICE=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f2)
        echo "⚠ Port $PORT is in use by: $SERVICE"
    else
        echo "✓ Port $PORT is available"
    fi
done

echo ""
echo "=== Test Complete ==="
echo ""
echo "If all checks pass, you can start the stack with:"
echo "  podman-compose up -d"
echo ""
echo "To start a specific service first:"
echo "  podman-compose up -d prowlarr"
echo "  podman-compose up -d qbittorrent"
echo "  podman-compose up -d sonarr radarr"