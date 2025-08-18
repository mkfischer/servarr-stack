# Homepage Dashboard Configuration

Homepage is a modern, fully customizable dashboard for your homelab services.

## Quick Start

1. Start Homepage container:
   ```bash
   podman-compose up -d homepage
   ```

2. Access the dashboard:
   ```
   http://localhost:3000
   ```

## Configuration Files

All configuration is done through YAML files in this directory:

### services.yaml
Defines all your services organized by groups. Each service can have:
- Icon (from dashboard-icons or custom URL)
- Description
- Link (href)
- Widget integration for live stats

### widgets.yaml
System widgets displayed on the dashboard:
- Resource monitor (CPU, RAM, Disk)
- Date/time
- Weather
- Search bar
- Docker stats

### settings.yaml
Dashboard appearance and behavior:
- Theme (dark/light)
- Background image
- Layout configuration
- Title and favicon

### bookmarks.yaml
Additional links organized by categories

### custom.css
Custom styling to personalize your dashboard

## Adding API Keys

Most service widgets require API keys to display live information:

### Get API Keys from Services:

**Sonarr/Radarr/Bazarr/Prowlarr:**
1. Go to Settings → General → Security
2. Copy the API Key
3. Add to services.yaml under the service's widget configuration

**Jellyfin:**
1. Go to Dashboard → API Keys
2. Create a new API key for Homepage
3. Add to services.yaml

**qBittorrent:**
1. Default login: admin/adminadmin
2. Change password in settings!
3. Add username/password to services.yaml

**SABnzbd:**
1. Go to Config → General
2. Copy the API Key
3. Add to services.yaml

## Widget Types

Homepage supports 100+ service widgets. Common ones in this stack:

- `sonarr` - Shows series, episodes, queue
- `radarr` - Shows movies, queue, upcoming
- `bazarr` - Shows subtitle stats
- `prowlarr` - Shows indexers, grabs
- `jellyfin` - Shows libraries, active streams
- `qbittorrent` - Shows active torrents, speeds
- `sabnzbd` - Shows queue, speed, remaining
- `tdarr` - Shows transcode queue, workers

## Customization

### Icons
Icons can be sourced from:
- [Dashboard Icons](https://github.com/walkxcode/dashboard-icons) - Use `iconname.png`
- Material Design Icons - Use `mdi-iconname`
- Simple Icons - Use `si-iconname`
- Custom URL - Full URL to image

### Themes
Available themes: dark, light
Color schemes: slate, gray, zinc, neutral, stone

### Background
Supports images with filters:
- blur: none, sm, md, lg, xl
- brightness: 0-100
- saturate: 0-100

## Troubleshooting

### Widgets not showing data
- Check API keys are correct
- Verify service URLs use container IPs (172.20.0.x)
- Check container logs: `podman logs homepage`

### Can't connect to services
- Ensure all containers are on the same network (media_net)
- Verify firewall rules allow internal container communication

### Docker stats not working
- Requires mounting docker/podman socket
- May need additional permissions

## Advanced Configuration

### Environment Variables
```yaml
HOMEPAGE_CONFIG_DIR: /app/config
HOMEPAGE_PORT: 3000
LOG_LEVEL: info
```

### Multiple Dashboards
Create subdirectories in config folder for different dashboard configurations

### Authentication
Homepage doesn't have built-in auth. Use a reverse proxy like Nginx or Traefik for authentication.

## Resources

- [Homepage Documentation](https://gethomepage.dev)
- [Dashboard Icons](https://github.com/walkxcode/dashboard-icons)
- [Widget Documentation](https://gethomepage.dev/widgets/)