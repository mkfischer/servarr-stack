#!/bin/bash
# Servarr Stack Management Script
# For Ubuntu with Podman, using NFS mount from 192.168.50.186

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NFS_SERVER="192.168.50.186"
NFS_SHARE="/mnt/array1/yoho"
MOUNT_POINT="/mnt/media"
CONFIG_DIR="/srv/apps"
COMPOSE_CMD="podman-compose"

# Active services (containers actually in use)
SERVICES=(
    "sonarr"
    "radarr"
    "bazarr"
    "prowlarr"
    "qbittorrent"
    "unpackerr"
    "qbitmanage"
    "homepage"
)

# Function to print colored messages
print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# Function to check if running on Ubuntu
check_system() {
    if [[ ! -f /etc/os-release ]]; then
        print_msg "$RED" "Error: Cannot determine OS. This script is designed for Ubuntu."
        exit 1
    fi
    
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_msg "$YELLOW" "Warning: This script is designed for Ubuntu. Current OS:"
        cat /etc/os-release | grep PRETTY_NAME
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_msg "$GREEN" "Checking prerequisites..."
    
    # Check for podman
    if ! command -v podman &> /dev/null; then
        print_msg "$RED" "Error: Podman is not installed."
        echo "Install with: sudo apt install podman podman-compose"
        exit 1
    fi
    
    # Check for podman-compose
    if ! command -v podman-compose &> /dev/null; then
        print_msg "$RED" "Error: podman-compose is not installed."
        echo "Install with: sudo apt install podman-compose"
        exit 1
    fi
    
    print_msg "$GREEN" "Prerequisites check passed."
}

# Function to setup NFS mount
setup_nfs() {
    print_msg "$GREEN" "Setting up NFS mount..."
    
    # Check if mount point exists
    if [[ ! -d "$MOUNT_POINT" ]]; then
        print_msg "$YELLOW" "Creating mount point: $MOUNT_POINT"
        sudo mkdir -p "$MOUNT_POINT"
    fi
    
    # Check if already mounted
    if mount | grep -q "$MOUNT_POINT"; then
        print_msg "$GREEN" "NFS share already mounted at $MOUNT_POINT"
    else
        print_msg "$YELLOW" "Mounting NFS share..."
        sudo mount -t nfs "${NFS_SERVER}:${NFS_SHARE}" "$MOUNT_POINT"
        
        if mount | grep -q "$MOUNT_POINT"; then
            print_msg "$GREEN" "NFS share mounted successfully."
        else
            print_msg "$RED" "Error: Failed to mount NFS share."
            exit 1
        fi
    fi
    
    # Add to fstab if not present
    if ! grep -q "${NFS_SERVER}:${NFS_SHARE}" /etc/fstab; then
        print_msg "$YELLOW" "Adding NFS mount to /etc/fstab for persistence..."
        echo "${NFS_SERVER}:${NFS_SHARE} ${MOUNT_POINT} nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
    fi
}

# Function to create config directories
setup_directories() {
    print_msg "$GREEN" "Setting up configuration directories..."
    
    for service in "${SERVICES[@]}"; do
        local dir="${CONFIG_DIR}/${service}"
        if [[ ! -d "$dir" ]]; then
            print_msg "$YELLOW" "Creating directory: $dir"
            sudo mkdir -p "$dir"
        fi
    done
    
    # Set proper permissions (UID/GID 1001 as per docker-compose.yml)
    print_msg "$YELLOW" "Setting permissions..."
    sudo chown -R 1001:1001 "$CONFIG_DIR"
    
    print_msg "$GREEN" "Directories created and permissions set."
}

# Function to get API key from user
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

# Function to setup Homepage dashboard
setup_homepage() {
    print_msg "$GREEN" "Setting up Homepage dashboard configuration..."
    
    local homepage_dir="${CONFIG_DIR}/homepage"
    
    # Copy configuration files from template if they exist
    if [[ -d "./config/homepage" ]]; then
        if [[ ! -f "${homepage_dir}/services.yaml" ]]; then
            print_msg "$YELLOW" "Copying Homepage configuration templates..."
            sudo cp -r ./config/homepage/* "${homepage_dir}/" 2>/dev/null || true
            sudo chown -R 1001:1001 "${homepage_dir}"
        fi
    fi
    
    print_msg "$YELLOW" "Configure Homepage API keys for service widgets..."
    echo ""
    echo "You can configure API keys now or edit ${homepage_dir}/services.yaml later."
    read -p "Configure API keys now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Get API keys for active services
        SONARR_KEY=$(get_api_key "Sonarr" "http://localhost:8989/settings/general")
        RADARR_KEY=$(get_api_key "Radarr" "http://localhost:7878/settings/general")
        BAZARR_KEY=$(get_api_key "Bazarr" "http://localhost:6767/settings/general")
        PROWLARR_KEY=$(get_api_key "Prowlarr" "http://localhost:9696/settings/general")
        
        echo ""
        echo "For qBittorrent:"
        echo "Default credentials are usually admin/adminadmin"
        echo "You should change these in qBittorrent settings!"
        read -p "Enter qBittorrent username (default: admin): " QBIT_USER
        QBIT_USER=${QBIT_USER:-admin}
        read -s -p "Enter qBittorrent password: " QBIT_PASS
        echo ""
        
        # Update services.yaml with API keys if provided
        local services_file="${homepage_dir}/services.yaml"
        if [[ -f "$services_file" ]]; then
            [[ -n "$SONARR_KEY" ]] && sudo sed -i "s|key: 12c3cf446b4f4cb7aa77d796b653f8c9|key: $SONARR_KEY|" "$services_file"
            [[ -n "$RADARR_KEY" ]] && sudo sed -i "s|key: 91c421d1238d402b8eeb9f083107205a|key: $RADARR_KEY|" "$services_file"
            [[ -n "$BAZARR_KEY" ]] && sudo sed -i "s|key: 07b3286400830ae2fffc82e91e733cfb|key: $BAZARR_KEY|" "$services_file"
            [[ -n "$PROWLARR_KEY" ]] && sudo sed -i "s|key: 35ccdc07d49347188b462d2af114cc5e|key: $PROWLARR_KEY|" "$services_file"
            [[ -n "$QBIT_USER" ]] && sudo sed -i "s|username: admin|username: $QBIT_USER|" "$services_file"
            [[ -n "$QBIT_PASS" ]] && sudo sed -i "s|password: dose.caution.Blow.2|password: $QBIT_PASS|" "$services_file"
        fi
    fi
    
    print_msg "$GREEN" "Homepage configuration complete."
}

# Function to start services
start_services() {
    print_msg "$GREEN" "Starting services..."
    cd "$(dirname "$0")"
    $COMPOSE_CMD up -d
    print_msg "$GREEN" "Services started."
}

# Function to stop services
stop_services() {
    print_msg "$YELLOW" "Stopping services..."
    cd "$(dirname "$0")"
    $COMPOSE_CMD down
    print_msg "$GREEN" "Services stopped."
}

# Function to restart services
restart_services() {
    print_msg "$YELLOW" "Restarting services..."
    cd "$(dirname "$0")"
    $COMPOSE_CMD restart
    print_msg "$GREEN" "Services restarted."
}

# Function to show service status
show_status() {
    print_msg "$GREEN" "Service Status:"
    echo ""
    podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show logs
show_logs() {
    local service=$1
    if [[ -z "$service" ]]; then
        print_msg "$YELLOW" "Available services:"
        for s in "${SERVICES[@]}"; do
            echo "  - $s"
        done
        read -p "Enter service name: " service
    fi
    
    if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
        podman logs -f "$service"
    else
        print_msg "$RED" "Error: Unknown service '$service'"
    fi
}

# Function to update containers
update_containers() {
    print_msg "$GREEN" "Updating containers..."
    cd "$(dirname "$0")"
    
    read -p "Update all containers? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_msg "$YELLOW" "Pulling latest images..."
        $COMPOSE_CMD pull
        print_msg "$YELLOW" "Recreating containers..."
        $COMPOSE_CMD up -d
    else
        print_msg "$YELLOW" "Available services:"
        for s in "${SERVICES[@]}"; do
            echo "  - $s"
        done
        read -p "Enter service name to update: " service
        
        if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
            print_msg "$YELLOW" "Pulling latest image for $service..."
            podman pull $(grep -A5 "^  $service:" docker-compose.yml | grep "image:" | awk '{print $2}')
            print_msg "$YELLOW" "Recreating $service container..."
            $COMPOSE_CMD up -d "$service"
        else
            print_msg "$RED" "Error: Unknown service '$service'"
        fi
    fi
    
    print_msg "$GREEN" "Update complete."
}

# Function for initial setup
initial_setup() {
    print_msg "$GREEN" "=== Servarr Stack Initial Setup ==="
    echo ""
    
    check_system
    check_prerequisites
    setup_nfs
    setup_directories
    setup_homepage
    
    print_msg "$GREEN" ""
    print_msg "$GREEN" "=== Setup Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Start services: $0 start"
    echo "2. Access Homepage at: http://localhost:3000"
    echo "3. Configure each service through their web interfaces:"
    echo "   - Sonarr: http://localhost:8989"
    echo "   - Radarr: http://localhost:7878"
    echo "   - Bazarr: http://localhost:6767"
    echo "   - Prowlarr: http://localhost:9696"
    echo "   - qBittorrent: http://localhost:8080"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    print_msg "$GREEN" "=== Servarr Stack Management ==="
    echo ""
    echo "1) Initial Setup (first time)"
    echo "2) Start Services"
    echo "3) Stop Services"
    echo "4) Restart Services"
    echo "5) Show Status"
    echo "6) Show Logs"
    echo "7) Update Containers"
    echo "8) Setup Homepage API Keys"
    echo "9) Exit"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) initial_setup ;;
        2) start_services ;;
        3) stop_services ;;
        4) restart_services ;;
        5) show_status ;;
        6) show_logs ;;
        7) update_containers ;;
        8) setup_homepage ;;
        9) exit 0 ;;
        *) print_msg "$RED" "Invalid option" ;;
    esac
}

# Command line arguments
if [[ $# -gt 0 ]]; then
    case $1 in
        setup) initial_setup ;;
        start) start_services ;;
        stop) stop_services ;;
        restart) restart_services ;;
        status) show_status ;;
        logs) show_logs "$2" ;;
        update) update_containers ;;
        homepage) setup_homepage ;;
        *) 
            print_msg "$RED" "Unknown command: $1"
            echo "Usage: $0 [setup|start|stop|restart|status|logs|update|homepage]"
            exit 1
            ;;
    esac
else
    # Interactive menu
    while true; do
        show_menu
    done
fi