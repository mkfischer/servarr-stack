# Servarr Stack - Ubuntu Deployment Guide

## Prerequisites

- Ubuntu system with Podman installed
- NFS client tools: `sudo apt-get install nfs-common`
- At least 20GB free space for config and temp files
- Network access to NFS server (192.168.50.186)

## Quick Start

1. **Clone or copy this repository to your Ubuntu system**

2. **Run the setup script:**
   ```bash
   chmod +x setup-ubuntu.sh
   ./setup-ubuntu.sh
   ```

3. **Mount NFS share (if not already mounted):**
   ```bash
   sudo mount -t nfs 192.168.50.186:/mnt/array1/yoho /mnt/media
   ```

4. **Start the stack:**
   ```bash
   podman-compose up -d
   ```

## Manual Setup (if not using setup script)

### 1. Create Required Directories
```bash
# Config directories
sudo mkdir -p /srv/apps/{sonarr,radarr,bazarr,prowlarr,lazylibrarian,qbittorrent,qbitmanage,sabnzbd,slskd,jellyfin/{config,cache},jellyseerr,tdarr/{server,configs},unpackerr,beets}

# Set ownership
sudo chown -R 1000:1000 /srv/apps

# Media directories (if not using NFS)
sudo mkdir -p /mnt/media/{downloads,library/{tv,movies,anime-series,anime-movies,books,audiobooks,music},apps/tdarr/temp}
sudo mkdir -p /mnt/media/downloads/complete/{music,books,movies,tv}
sudo chown -R 1000:1000 /mnt/media
```

### 2. Mount NFS Share
```bash
# Temporary mount
sudo mount -t nfs 192.168.50.186:/mnt/array1/yoho /mnt/media

# Permanent mount (add to /etc/fstab)
echo "192.168.50.186:/mnt/array1/yoho /mnt/media nfs defaults 0 0" | sudo tee -a /etc/fstab
```

### 3. Start Services
```bash
# Start all services
podman-compose up -d

# Or start specific services
podman-compose up -d sonarr radarr prowlarr
```

## Service Management

### View running containers:
```bash
podman ps
```

### View logs:
```bash
podman logs <container_name>
podman logs -f <container_name>  # Follow logs
```

### Restart a service:
```bash
podman-compose restart <service_name>
```

### Update containers:
```bash
podman-compose pull
podman-compose up -d
```

### Stop all services:
```bash
podman-compose down
```

## Service URLs

After starting, services are available at:

| Service | URL | Port |
|---------|-----|------|
| **Homepage** | **http://localhost:3000** | **3000** |
| Sonarr | http://localhost:8989 | 8989 |
| Radarr | http://localhost:7878 | 7878 |
| Bazarr | http://localhost:6767 | 6767 |
| Prowlarr | http://localhost:9696 | 9696 |
| qBittorrent | http://localhost:8085 | 8085 |
| SABnzbd | http://localhost:8082 | 8082 |
| Jellyfin | http://localhost:8096 | 8096 |
| Jellyseerr | http://localhost:5055 | 5055 |
| LazyLibrarian | http://localhost:5299 | 5299 |
| slskd | http://localhost:5030 | 5030 |
| Tdarr | http://localhost:8265 | 8265 |
| Beets | http://localhost:8337 | 8337 |

## Troubleshooting

### Container won't start
- Check logs: `podman logs <container_name>`
- Verify directories exist: `ls -la /srv/apps/`
- Check permissions: `ls -la /srv/apps/ | grep <service>`
- Verify NFS mount: `df -h | grep /mnt/media`

### Permission issues
```bash
# Fix ownership
sudo chown -R 1000:1000 /srv/apps/<service_name>
sudo chown -R 1000:1000 /mnt/media
```

### Port conflicts
- Check what's using a port: `sudo netstat -tlnp | grep <port>`
- Modify port in docker-compose.yml if needed

### Network issues
- Verify network exists: `podman network ls`
- Recreate network if needed: `podman network create media_net --subnet 172.20.0.0/24`

## Notes

- All services use PUID=1000 and PGID=1000
- Config files are stored in `/srv/apps/<service_name>/`
- Media files are stored in `/mnt/media/` (NFS mount)
- The network subnet is 172.20.0.0/24 (media_net)