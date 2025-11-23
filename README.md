# Astroneer Dedicated Server for Linux

This project provides an easy-to-use installation script for running an Astroneer dedicated server on Linux using Docker.

## Features

- **Automated Installation**: One-command setup of everything you need
- **Multiple Docker Images**: Choose from several community-maintained images
- **Easy Management**: Simple scripts to start, stop, restart, and monitor your server
- **Automatic Updates**: Built-in support for keeping your server up-to-date
- **Automatic Backups**: Configurable backup system
- **Firewall Configuration**: Automated UFW setup

## System Requirements

- Linux (tested on Linux Mint/Ubuntu)
- 4GB+ RAM recommended
- 10GB+ free disk space
- Docker and Docker Compose
- Open ports 7777/udp and 8777/udp

## Quick Start

### 1. Run the Installer

```bash
chmod +x install-astroneer-server.sh
./install-astroneer-server.sh
```

The installer will:
- Check and install Docker if needed
- Let you choose a Docker image
- Configure your server settings
- Set up firewall rules
- Create management scripts

### 2. Start Your Server

```bash
cd ~/astroneer-server
./start.sh
```

### 3. Monitor the Logs

First startup takes 10-15 minutes to download server files (~2-3GB):

```bash
./logs.sh
```

Press `Ctrl+C` to exit logs (server keeps running).

## Management Commands

All commands should be run from the `~/astroneer-server` directory:

| Command | Description |
|---------|-------------|
| `./start.sh` | Start the server |
| `./stop.sh` | Stop the server |
| `./restart.sh` | Restart the server |
| `./logs.sh` | View live server logs |
| `./update.sh` | Update server to latest version |
| `./backup.sh` | Create a manual backup |

## Configuration

### Server Settings

Edit `~/astroneer-server/.env` to change server settings:

```bash
# Server Configuration
SERVER_NAME=My Astroneer Server
SERVER_PASSWORD=secretpassword
MAX_PLAYERS=8
PUBLIC_IP=YOUR_IP_HERE

# Automatic Updates (in seconds)
AUTO_UPDATE=true
UPDATE_INTERVAL=3600  # Check every hour

# Automatic Backups
AUTO_BACKUP=true
BACKUP_INTERVAL=3600  # Backup every hour
BACKUP_RETENTION=10   # Keep last 10 backups
```

After editing, restart the server:
```bash
./restart.sh
```

### Advanced Configuration

Astroneer-specific settings can be found in:
```
~/astroneer-server/config/
```

These files are created after the first server startup.

## Docker Images

The installer offers three Docker image options:

### 1. birdhimself/astroneer-docker (Recommended)
- ✅ Supports encryption
- ✅ Supports ARM and x86 CPUs
- ✅ Most actively maintained
- ✅ Better for public servers

### 2. armadous/astroneer-server
- ❌ No encryption support
- ✅ Simpler configuration
- ✅ Good for private servers

### 3. whalybird/astroneer-server
- ❌ No encryption support
- ✅ Based on AstroTuxLauncher
- ✅ Good for private servers

## Connecting to Your Server

### From Windows

1. Launch Astroneer
2. Go to **Join Game** → **Server Browser**
3. Look for your server name or add manually using your public IP

### From Linux/Steam Deck

If your server doesn't use encryption (armadous or whalybird images), you must disable client-side encryption:

1. Navigate to:
   ```
   ~/.steam/steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved/Config/WindowsNoEditor/
   ```

2. Edit or create `Engine.ini` and add:
   ```ini
   [SystemSettings]
   Net.AllowEncryption=False
   ```

3. Save and launch Astroneer through Steam

See [CLIENT_ENCRYPTION.md](CLIENT_ENCRYPTION.md) for detailed instructions.

## Port Forwarding

If you're behind a router, forward these ports to your server's local IP:

- **7777/UDP** - Game port
- **8777/UDP** - Query port

Consult your router's manual for specific instructions.

## Troubleshooting

### Server won't start

```bash
cd ~/astroneer-server
./logs.sh
```

Common issues:
- First startup takes 10-15 minutes (downloading files)
- Ports already in use (check with `sudo netstat -tulpn | grep -E '7777|8777'`)
- Insufficient disk space
- Docker not running (`sudo systemctl start docker`)

### Can't connect to server

1. Verify server is running: `docker ps`
2. Check logs: `./logs.sh`
3. Verify ports are open: `sudo ufw status`
4. Check port forwarding on your router
5. Verify you're using the correct public IP
6. If on Linux/Steam Deck, ensure client encryption is disabled

### Performance issues

1. Check system resources: `docker stats`
2. Reduce `MAX_PLAYERS` in `.env`
3. Ensure no other heavy processes are running
4. Consider upgrading RAM if consistently high usage

### Update to latest server version

```bash
cd ~/astroneer-server
./update.sh
```

## Backups

### Automatic Backups

Backups are created automatically based on `BACKUP_INTERVAL` in `.env`.

Location: `~/astroneer-server/backups/`

### Manual Backup

```bash
./backup.sh
```

### Restore from Backup

```bash
cd ~/astroneer-server
./stop.sh

# Extract backup (replace with your backup filename)
tar -xzf backups/astroneer-backup-YYYYMMDD-HHMMSS.tar.gz

./start.sh
```

## Uninstalling

To completely remove the server:

```bash
cd ~/astroneer-server
./stop.sh
cd ~
docker rmi $(docker images | grep astroneer | awk '{print $3}')
rm -rf ~/astroneer-server
```

## Security Notes

### Encryption Warning

If using armadous or whalybird images:
- Server traffic is **not encrypted**
- Only use for private servers with trusted players
- Consider the birdhimself image if you need encryption

### Password Protection

Set a strong password in `.env`:
```bash
SERVER_PASSWORD=YourStrongPasswordHere
```

### Firewall

The installer configures UFW to only allow necessary ports. Keep your system updated:

```bash
sudo apt update && sudo apt upgrade -y
```

## Advanced Usage

### Custom Docker Compose

Edit `~/astroneer-server/docker-compose.yml` to customize:
- Port mappings
- Volume mounts
- Environment variables
- Resource limits

Example - Add CPU/memory limits:

```yaml
services:
  astroneer:
    # ... existing config ...
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
```

### Running Multiple Servers

Create separate directories for each server:

```bash
# Copy the installation script
cp install-astroneer-server.sh install-server2.sh

# Edit and change INSTALL_DIR
nano install-server2.sh
# Change: INSTALL_DIR="${HOME}/astroneer-server2"

# Run installer and use different ports in docker-compose.yml
./install-server2.sh
```

### Logs to File

Redirect logs to a file for analysis:

```bash
docker-compose logs -f astroneer > server.log
```

## Contributing

Found an issue or have a suggestion? Feel free to:
- Open an issue on GitHub
- Submit a pull request
- Share your improvements

## Resources

- [Official Astroneer Dedicated Server Guide](https://blog.astroneer.space/p/astroneer-dedicated-server-details/)
- [birdhimself/astroneer-docker](https://github.com/birdhimself/astroneer-docker)
- [AstroTuxLauncher](https://github.com/JoeJoeTV/AstroTuxLauncher)
- [Docker Documentation](https://docs.docker.com/)

## License

This installation script is provided as-is without warranty. Astroneer is property of System Era Softworks.

## FAQ

**Q: How much does it cost to run?**
A: The server software is free. You only need a Linux machine (can be your own PC, a spare machine, or a VPS).

**Q: Can I run this on a Raspberry Pi?**
A: Yes, if using the birdhimself image which supports ARM. However, performance may vary.

**Q: How many players can join?**
A: Default is 8. You can adjust `MAX_PLAYERS` in `.env`, but performance depends on your hardware.

**Q: Does this work on WSL (Windows Subsystem for Linux)?**
A: Yes, WSL2 supports Docker and should work, though native Windows servers are recommended for Windows hosts.

**Q: My friends can't find the server in the browser**
A: Give them your public IP address to manually add the server. Check that ports are forwarded correctly.

**Q: How do I change the server name after setup?**
A: Edit `~/astroneer-server/.env`, change `SERVER_NAME`, and run `./restart.sh`.

**Q: Can I migrate from Windows to this Linux setup?**
A: Yes! Copy your save files from the Windows server to `~/astroneer-server/server/` and restart.
