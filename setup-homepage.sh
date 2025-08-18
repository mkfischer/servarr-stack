#!/bin/bash
# Setup script for Homepage dashboard configuration

set -e

echo "Setting up Homepage dashboard configuration..."
echo ""
echo "This script will help you configure API keys for service widgets."
echo "You'll need to get API keys from each service's settings."
echo ""

# Function to get API key
get_api_key() {
    local service=$1
    local url=$2
    echo ""
    echo "For $service:"
    echo "1. Go to $url"
    echo "2. Navigate to Settings -> General -> Security"
    echo "3. Copy the API Key"
    read -p "Enter $service API key (or press Enter to skip): " api_key
    echo "$api_key"
}

CONFIG_DIR="/srv/apps/homepage"

# Check if running on Ubuntu
if [ ! -d "$CONFIG_DIR" ]; then
    CONFIG_DIR="./config/homepage"
    echo "Using local config directory: $CONFIG_DIR"
fi

# Backup existing services.yaml if it exists
if [ -f "$CONFIG_DIR/services.yaml" ]; then
    cp "$CONFIG_DIR/services.yaml" "$CONFIG_DIR/services.yaml.bak"
    echo "Backed up existing services.yaml to services.yaml.bak"
fi

# Copy configuration files if they don't exist
if [ ! -f "$CONFIG_DIR/services.yaml" ]; then
    cp ./config/homepage/*.yaml "$CONFIG_DIR/" 2>/dev/null || true
    cp ./config/homepage/*.css "$CONFIG_DIR/" 2>/dev/null || true
    echo "Copied configuration files to $CONFIG_DIR"
fi

echo ""
echo "=== Service API Configuration ==="
echo "Note: You can skip any service and configure it later by editing $CONFIG_DIR/services.yaml"

# Get API keys for services
SONARR_KEY=$(get_api_key "Sonarr" "http://localhost:8989/settings/general")
RADARR_KEY=$(get_api_key "Radarr" "http://localhost:7878/settings/general")
BAZARR_KEY=$(get_api_key "Bazarr" "http://localhost:6767/settings/general")
PROWLARR_KEY=$(get_api_key "Prowlarr" "http://localhost:9696/settings/general")
SABNZBD_KEY=$(get_api_key "SABnzbd" "http://localhost:8082/config/general/")
JELLYFIN_KEY=$(get_api_key "Jellyfin" "http://localhost:8096 (Dashboard -> API Keys)")
JELLYSEERR_KEY=$(get_api_key "Jellyseerr" "http://localhost:5055/settings/main")

echo ""
echo "For qBittorrent:"
echo "Default credentials are usually admin/adminadmin"
echo "You should change these in qBittorrent settings!"
read -p "Enter qBittorrent username (default: admin): " QBIT_USER
QBIT_USER=${QBIT_USER:-admin}
read -s -p "Enter qBittorrent password: " QBIT_PASS
echo ""

# Update services.yaml with API keys
if [ -n "$SONARR_KEY" ]; then
    sed -i "s|key: # Add your API key here|key: $SONARR_KEY|" "$CONFIG_DIR/services.yaml"
fi

# Create a simple update script for API keys
cat > "$CONFIG_DIR/update-api-keys.sh" << 'EOF'
#!/bin/bash
# Quick script to update API keys in services.yaml

CONFIG_FILE="/srv/apps/homepage/services.yaml"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="./services.yaml"

echo "Current configuration file: $CONFIG_FILE"
echo ""
echo "Edit this file directly to add/update API keys for each service."
echo "Look for lines with 'key:' under each service widget configuration."
echo ""
echo "Opening in default editor..."
${EDITOR:-nano} "$CONFIG_FILE"
EOF

chmod +x "$CONFIG_DIR/update-api-keys.sh"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Homepage dashboard configuration has been created!"
echo ""
echo "To finish setup:"
echo "1. Start the Homepage container: podman-compose up -d homepage"
echo "2. Access Homepage at: http://localhost:3000"
echo "3. Edit API keys later: $CONFIG_DIR/services.yaml"
echo ""
echo "Configuration files location: $CONFIG_DIR"
echo "- services.yaml: Service definitions and widgets"
echo "- settings.yaml: Dashboard appearance settings"
echo "- widgets.yaml: System widgets configuration"
echo "- bookmarks.yaml: Additional bookmarks"
echo "- custom.css: Custom styling"
echo ""
echo "To update API keys later, run: $CONFIG_DIR/update-api-keys.sh"