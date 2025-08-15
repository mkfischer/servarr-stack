# Arr Stack Installation Guide

This guide covers setting up an Arr stack (Sonarr, Radarr, etc.) using Docker Compose. The installation is compatible with most Linux systems, with an optional script for Proxmox users running unprivileged LXC containers.

---

## Prerequisites

- A Linux server (bare metal, VM, or container) with Docker and Docker Compose installed
- Basic knowledge of the Linux command line
- Appropriate storage configured for media and application data

---

## Step 1: Clone the Repository

1. **Access your server** via SSH or terminal.
2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>

---

## Step 2: Configure Installation

### For Standard Linux Installations

1. **Edit the `install.sh` script**
   - Open the script and set the variables according to your environment (paths, user, permissions, etc.).
   - Save your changes.

2. **Run the installation script**
   ```bash
   ./install.sh

---

## For Proxmox Unprivileged LXC Containers

If you are using Proxmox with an unprivileged LXC container and a Proxmox-mounted media directory, follow these steps:

1. **On the Proxmox Host:**
   - Run the Proxmox-specific installation script:
     ```bash
     ./install-pve.sh
     ```
   - Edit the script to configure paths, permissions, and other variables according to your Proxmox setup.

2. **Inside the LXC Container:**
   - Run the main installation script:
     ```bash
     ./install.sh
     ```

---

## Step 3: Deploy the Arr Stack

1. **Start the stack**:
   ```bash
   docker compose up -d

2. **Verify the deployment**:
   - Check that all containers are running:
     ```bash
     docker ps
     ```
   - Access the web interfaces for each service using the appropriate URLs (e.g., `http://<your-server-ip>:<service-port>`).
   - Complete the initial setup for each application as needed.
   - Ensure storage permissions and firewall rules are properly configured.

---

## Troubleshooting
   **Issue**            | **Solution**                                      |
 |----------------------|---------------------------------------------------|
 | Storage issues       | Verify mounts and permissions.                    |
 | Docker issues        | Confirm Docker and Docker Compose are installed.  |
 | Network issues       | Check firewall rules and port accessibility.      |
 | Performance issues   | Review resource allocation and system logs.       |

---

## Notes

- Use `install.sh` for standard Linux installations.
- Use `install-pve.sh` **only** for Proxmox unprivileged LXC environments with Proxmox-mounted media directories.
- Regularly back up your configurations and data.