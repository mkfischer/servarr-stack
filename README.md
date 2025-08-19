# Servarr Stack

Private network media automation stack using Podman on Ubuntu.

## Active Services

- **Media Management**: Sonarr, Radarr, Bazarr, Prowlarr
- **Download Client**: qBittorrent
- **Support**: Unpackerr, qBitManage
- **Dashboard**: Homepage

## Setup

```bash
# Initial setup (creates directories, mounts NFS, configures services)
./manage.sh setup

# Start all services
./manage.sh start
```

## Management

```bash
# Interactive menu
./manage.sh

# Direct commands
./manage.sh start|stop|restart|status|logs|update|homepage
```

## Access Points

- Homepage: http://localhost:3000
- Sonarr: http://localhost:8989
- Radarr: http://localhost:7878
- Bazarr: http://localhost:6767
- Prowlarr: http://localhost:9696
- qBittorrent: http://localhost:8080

## Configuration

- **NFS Mount**: `192.168.50.186:/mnt/array1/yoho` → `/mnt/media`
- **Config Directory**: `/srv/apps/`
- **Platform**: Ubuntu with Podman (developed on macOS)