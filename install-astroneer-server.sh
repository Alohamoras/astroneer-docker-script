#!/bin/bash

###############################################################################
# Astroneer Dedicated Server Installation Script for Linux
# Supports multiple Docker image options
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="${HOME}/astroneer-server"
DOCKER_IMAGE_OPTION=""

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

###############################################################################
# Check System Requirements
###############################################################################

check_requirements() {
    print_header "Checking System Requirements"

    local missing_deps=()

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        print_success "Docker is installed ($(docker --version))"
    fi

    # Check for Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        missing_deps+=("docker-compose")
    else
        print_success "Docker Compose is installed"
    fi

    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    else
        print_success "curl is installed"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        print_info "Would you like to install missing dependencies? (requires sudo)"
        read -p "Install now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies "${missing_deps[@]}"
        else
            print_error "Cannot proceed without required dependencies"
            exit 1
        fi
    else
        print_success "All requirements met!"
    fi

    # Check if user is in docker group
    if ! groups | grep -q docker; then
        print_warning "Current user is not in the 'docker' group"
        print_info "You may need to run docker commands with sudo, or add yourself to the docker group:"
        echo "  sudo usermod -aG docker $USER"
        echo "  Then log out and back in for changes to take effect"
        echo ""
    fi
}

###############################################################################
# Install Dependencies
###############################################################################

install_dependencies() {
    local deps=("$@")
    print_header "Installing Dependencies"

    # Update package list
    print_info "Updating package list..."
    sudo apt-get update

    for dep in "${deps[@]}"; do
        case $dep in
            docker)
                print_info "Installing Docker..."
                # Install Docker using official method
                sudo apt-get install -y ca-certificates curl gnupg lsb-release

                # Add Docker's official GPG key
                sudo install -m 0755 -d /etc/apt/keyrings
                if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    sudo chmod a+r /etc/apt/keyrings/docker.gpg
                fi

                # Set up repository
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                  $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
                  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                # Add user to docker group
                sudo usermod -aG docker $USER
                print_success "Docker installed. You may need to log out and back in for group changes to take effect."
                ;;
            docker-compose)
                print_info "Installing Docker Compose..."
                sudo apt-get install -y docker-compose-plugin
                print_success "Docker Compose installed"
                ;;
            curl)
                print_info "Installing curl..."
                sudo apt-get install -y curl
                print_success "curl installed"
                ;;
        esac
    done
}

###############################################################################
# Docker Image Selection
###############################################################################

select_docker_image() {
    print_header "Select Docker Image"
    echo ""
    echo "Available Astroneer server Docker images:"
    echo ""
    echo "  1) birdhimself/astroneer-docker (Recommended)"
    echo "     - Supports encryption"
    echo "     - Supports ARM and x86 CPUs"
    echo "     - Most actively maintained"
    echo ""
    echo "  2) armadous/astroneer-server"
    echo "     - No encryption support"
    echo "     - Simpler setup"
    echo ""
    echo "  3) whalybird/astroneer-server"
    echo "     - No encryption support"
    echo "     - Based on AstroTuxLauncher"
    echo ""

    while true; do
        read -p "Select an option (1-3) [1]: " choice
        choice=${choice:-1}

        case $choice in
            1)
                DOCKER_IMAGE_OPTION="birdhimself"
                print_success "Selected: birdhimself/astroneer-docker"
                break
                ;;
            2)
                DOCKER_IMAGE_OPTION="armadous"
                print_success "Selected: armadous/astroneer-server"
                print_warning "Note: This image does not support encryption"
                break
                ;;
            3)
                DOCKER_IMAGE_OPTION="whalybird"
                print_success "Selected: whalybird/astroneer-server"
                print_warning "Note: This image does not support encryption"
                break
                ;;
            *)
                print_error "Invalid choice. Please select 1, 2, or 3"
                ;;
        esac
    done
    echo ""
}

###############################################################################
# Create Server Directory Structure
###############################################################################

create_directory_structure() {
    print_header "Creating Server Directory"

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory $INSTALL_DIR already exists"
        read -p "Do you want to overwrite it? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled"
            exit 1
        fi
    fi

    mkdir -p "$INSTALL_DIR"/{server,backups,config}
    print_success "Created directory structure at $INSTALL_DIR"
}

###############################################################################
# Generate Docker Compose File
###############################################################################

generate_docker_compose() {
    print_header "Generating Docker Compose Configuration"

    case $DOCKER_IMAGE_OPTION in
        birdhimself)
            cat > "$INSTALL_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  astroneer:
    image: birdhimself/astroneer-docker:latest
    container_name: astroneer-server
    stdin_open: true
    tty: true
    restart: unless-stopped

    ports:
      # Astroneer game ports
      - "8777:8777/udp"
      - "7777:7777/udp"

    volumes:
      - ./server:/home/steam/server
      - ./config:/home/steam/.wine/drive_c/users/steam/AppData/Local/Astro/Saved/Config/WindowsServer
      - ./backups:/home/steam/backups

    environment:
      # Server configuration
      - SERVER_NAME=${SERVER_NAME:-Astroneer Server}
      - SERVER_PASSWORD=${SERVER_PASSWORD:-}
      - MAX_PLAYERS=${MAX_PLAYERS:-8}
      - PUBLIC_IP=${PUBLIC_IP:-}

      # Performance settings
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-America/New_York}

      # Automatic updates
      - AUTO_UPDATE=${AUTO_UPDATE:-true}
      - UPDATE_INTERVAL=${UPDATE_INTERVAL:-3600}

      # Backup settings
      - AUTO_BACKUP=${AUTO_BACKUP:-true}
      - BACKUP_INTERVAL=${BACKUP_INTERVAL:-3600}
      - BACKUP_RETENTION=${BACKUP_RETENTION:-10}
EOF
            ;;
        armadous)
            cat > "$INSTALL_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  astroneer:
    image: armadous/astroneer-server:latest
    container_name: astroneer-server
    stdin_open: true
    tty: true
    restart: unless-stopped

    ports:
      - "8777:8777/udp"
      - "7777:7777/udp"

    volumes:
      - ./server:/astroneer
      - ./config:/config

    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-America/New_York}
EOF
            ;;
        whalybird)
            cat > "$INSTALL_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  astroneer:
    image: whalybird/astroneer-server:latest
    container_name: astroneer-server
    stdin_open: true
    tty: true
    restart: unless-stopped

    ports:
      - "8777:8777/udp"
      - "7777:7777/udp"

    volumes:
      - ./server:/server
      - ./config:/config

    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-America/New_York}
EOF
            ;;
    esac

    print_success "Docker Compose file created"
}

###############################################################################
# Generate Environment File
###############################################################################

generate_env_file() {
    print_header "Configuring Server Settings"

    echo ""
    print_info "Please provide the following information (press Enter for defaults):"
    echo ""

    # Get server name
    read -p "Server Name [Astroneer Private Server]: " server_name
    server_name=${server_name:-Astroneer Private Server}

    # Get server password
    read -p "Server Password (leave empty for no password): " server_password

    # Get max players
    read -p "Max Players [8]: " max_players
    max_players=${max_players:-8}

    # Get public IP
    print_info "Detecting public IP address..."
    public_ip=$(curl -s ifconfig.me || echo "")
    if [ -n "$public_ip" ]; then
        read -p "Public IP [$public_ip]: " input_ip
        public_ip=${input_ip:-$public_ip}
    else
        read -p "Public IP (could not auto-detect): " public_ip
    fi

    # Get timezone
    system_tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "America/New_York")
    read -p "Timezone [$system_tz]: " timezone
    timezone=${timezone:-$system_tz}

    # Create .env file
    cat > "$INSTALL_DIR/.env" << EOF
# Server Configuration
SERVER_NAME=$server_name
SERVER_PASSWORD=$server_password
MAX_PLAYERS=$max_players
PUBLIC_IP=$public_ip

# System Configuration
PUID=$(id -u)
PGID=$(id -g)
TZ=$timezone

# Update Settings
AUTO_UPDATE=true
UPDATE_INTERVAL=3600

# Backup Settings
AUTO_BACKUP=true
BACKUP_INTERVAL=3600
BACKUP_RETENTION=10
EOF

    print_success "Environment configuration saved to .env"
}

###############################################################################
# Configure Firewall
###############################################################################

configure_firewall() {
    print_header "Firewall Configuration"

    if command -v ufw &> /dev/null; then
        print_info "UFW firewall detected"
        read -p "Configure UFW to allow Astroneer ports? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ufw allow 8777/udp comment 'Astroneer Server'
            sudo ufw allow 7777/udp comment 'Astroneer Server'
            print_success "Firewall rules added"
        fi
    else
        print_warning "UFW not detected. Make sure the following ports are open:"
        echo "  - 8777/udp"
        echo "  - 7777/udp"
    fi
    echo ""
    print_info "If you're behind a router, don't forget to forward these ports!"
}

###############################################################################
# Create Management Scripts
###############################################################################

create_management_scripts() {
    print_header "Creating Management Scripts"

    # Start script
    cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose up -d
echo "Astroneer server started!"
echo "View logs with: ./logs.sh"
EOF
    chmod +x "$INSTALL_DIR/start.sh"

    # Stop script
    cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose down
echo "Astroneer server stopped!"
EOF
    chmod +x "$INSTALL_DIR/stop.sh"

    # Restart script
    cat > "$INSTALL_DIR/restart.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose restart
echo "Astroneer server restarted!"
EOF
    chmod +x "$INSTALL_DIR/restart.sh"

    # Logs script
    cat > "$INSTALL_DIR/logs.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose logs -f astroneer
EOF
    chmod +x "$INSTALL_DIR/logs.sh"

    # Update script
    cat > "$INSTALL_DIR/update.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Pulling latest Docker image..."
docker-compose pull
echo "Restarting server with new image..."
docker-compose up -d
echo "Server updated!"
EOF
    chmod +x "$INSTALL_DIR/update.sh"

    # Backup script
    cat > "$INSTALL_DIR/backup.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
BACKUP_NAME="astroneer-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
echo "Creating backup: $BACKUP_NAME"
tar -czf "backups/$BACKUP_NAME" server/ config/
echo "Backup created: backups/$BACKUP_NAME"
EOF
    chmod +x "$INSTALL_DIR/backup.sh"

    print_success "Management scripts created"
}

###############################################################################
# Final Instructions
###############################################################################

show_final_instructions() {
    print_header "Installation Complete!"

    echo ""
    print_success "Astroneer dedicated server has been set up at: $INSTALL_DIR"
    echo ""
    echo "Quick Start Commands:"
    echo "  cd $INSTALL_DIR"
    echo "  ./start.sh      - Start the server"
    echo "  ./stop.sh       - Stop the server"
    echo "  ./restart.sh    - Restart the server"
    echo "  ./logs.sh       - View server logs (Ctrl+C to exit)"
    echo "  ./update.sh     - Update server to latest version"
    echo "  ./backup.sh     - Create a backup"
    echo ""

    print_info "Configuration Files:"
    echo "  - $INSTALL_DIR/.env                  - Server settings"
    echo "  - $INSTALL_DIR/docker-compose.yml    - Docker configuration"
    echo "  - $INSTALL_DIR/config/               - Astroneer config files"
    echo ""

    print_warning "Important Notes:"
    echo "  1. First startup will download ~2-3GB of server files"
    echo "  2. This may take 10-15 minutes depending on your connection"
    echo "  3. Use './logs.sh' to monitor the download progress"

    if [ "$DOCKER_IMAGE_OPTION" != "birdhimself" ]; then
        echo ""
        print_warning "Encryption Disabled:"
        echo "  - Your server runs without encryption (Wine limitation)"
        echo "  - Friends connecting from Linux/Steam Deck must disable client encryption"
        echo "  - See README.md for instructions on how to disable client encryption"
    fi

    echo ""
    print_info "Connecting to Your Server:"
    echo "  1. Launch Astroneer"
    echo "  2. Go to 'Join Game' -> 'Server Browser'"
    echo "  3. Look for your server name or add it manually using your IP"
    echo ""

    read -p "Would you like to start the server now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$INSTALL_DIR"
        ./start.sh
        echo ""
        print_info "Server is starting. Use './logs.sh' to monitor progress."
    else
        print_info "You can start the server later with: cd $INSTALL_DIR && ./start.sh"
    fi
}

###############################################################################
# Main Installation Flow
###############################################################################

main() {
    clear
    print_header "Astroneer Dedicated Server Installer for Linux"
    echo ""
    echo "This script will set up an Astroneer dedicated server using Docker"
    echo ""

    check_requirements
    select_docker_image
    create_directory_structure
    generate_docker_compose
    generate_env_file
    configure_firewall
    create_management_scripts
    show_final_instructions
}

# Run main installation
main
