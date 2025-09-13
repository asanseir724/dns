#!/bin/bash

# اسکریپت نصب کاملاً خودکار - نسخه غیرتعاملی
# این اسکریپت از متغیرهای محیطی استفاده می‌کند

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
REPO_URL="https://github.com/asanseir724/dns.git"
DNS_INSTALL_DIR="/opt/dns"
TUNNEL_INSTALL_DIR="/opt/tunnel"
TEMP_DIR="/tmp/dns-install"

# تابع نمایش پیام
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error_message() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning_message() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# تابع نمایش بنر
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              سیستم مدیریت DNS و تانل خودکار                ║"
    echo "║                    نصب کاملاً خودکار v3.0                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# تابع نمایش راهنما
show_help() {
    echo -e "${BLUE}=== Usage Examples ===${NC}"
    echo ""
    echo -e "${YELLOW}For Iran Server (Client):${NC}"
    echo "SERVER_TYPE=iran FOREIGN_IP=1.2.3.4 FOREIGN_PORT=2222 FOREIGN_USER=tunnel LOCAL_PORT=8080 TUNNEL_PORT=1080 curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install_auto.sh | bash"
    echo ""
    echo -e "${YELLOW}For Foreign Server (Server):${NC}"
    echo "SERVER_TYPE=foreign curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install_auto.sh | bash"
    echo ""
    echo -e "${YELLOW}Default (Foreign Server):${NC}"
    echo "curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install_auto.sh | bash"
    echo ""
    echo -e "${BLUE}=== Environment Variables ===${NC}"
    echo "SERVER_TYPE     - Server type: 'iran' or 'foreign' (default: foreign)"
    echo "FOREIGN_IP      - Foreign server IP (required for iran server)"
    echo "FOREIGN_PORT    - SSH port (default: 2222)"
    echo "FOREIGN_USER    - SSH username (default: tunnel)"
    echo "LOCAL_PORT      - Local tunnel port (default: 8080)"
    echo "TUNNEL_PORT     - Tunnel port on foreign server (default: 1080)"
}

# تابع بررسی وابستگی‌ها
check_dependencies() {
    info_message "Checking dependencies..."
    
    # بررسی git
    if ! command -v git &> /dev/null; then
        warning_message "git not installed - installing..."
        if command -v apt-get &> /dev/null; then
            $SUDO_CMD apt-get update && $SUDO_CMD apt-get install -y git
        elif command -v yum &> /dev/null; then
            $SUDO_CMD yum update -y && $SUDO_CMD yum install -y git
        elif command -v dnf &> /dev/null; then
            $SUDO_CMD dnf update -y && $SUDO_CMD dnf install -y git
        else
            error_message "Cannot install git"
        fi
    fi
    
    # بررسی curl
    if ! command -v curl &> /dev/null; then
        warning_message "curl not installed - installing..."
        if command -v apt-get &> /dev/null; then
            $SUDO_CMD apt-get install -y curl
        elif command -v yum &> /dev/null; then
            $SUDO_CMD yum install -y curl
        elif command -v dnf &> /dev/null; then
            $SUDO_CMD dnf install -y curl
        fi
    fi
    
    log_message "Dependencies checked"
}

# تابع دانلود پروژه
download_project() {
    info_message "Downloading project from GitHub..."
    
    # پاکسازی دایرکتوری موقت
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # کلون کردن پروژه
    if git clone "$REPO_URL" "$TEMP_DIR"; then
        log_message "Project downloaded successfully"
    else
        error_message "Error downloading project from GitHub"
    fi
}

# تابع نصب وابستگی‌های سیستم
install_system_dependencies() {
    info_message "Installing system dependencies..."
    
    if command -v apt-get &> /dev/null; then
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install -y openssh-client openssh-server autossh ufw netcat-openbsd bc docker.io
    elif command -v yum &> /dev/null; then
        $SUDO_CMD yum update -y
        $SUDO_CMD yum install -y openssh-clients openssh-server autossh firewalld nc bc docker
    elif command -v dnf &> /dev/null; then
        $SUDO_CMD dnf update -y
        $SUDO_CMD dnf install -y openssh-clients openssh-server autossh firewalld nc bc docker
    fi
    
    log_message "System dependencies installed"
}

# تابع نصب DNS Project
install_dns_project() {
    info_message "Installing DNS Project..."
    
    # ایجاد دایرکتوری نصب
    $SUDO_CMD mkdir -p "$DNS_INSTALL_DIR"
    
    # کپی فایل‌های dns-project
    if [[ -d "$TEMP_DIR/dns-project" ]]; then
        $SUDO_CMD cp -r "$TEMP_DIR/dns-project"/* "$DNS_INSTALL_DIR/"
        log_message "dns-project files copied"
    else
        warning_message "dns-project folder not found - skipping..."
        return
    fi
    
    # تنظیم مجوزها
    $SUDO_CMD chown -R "$USER:$USER" "$DNS_INSTALL_DIR"
    $SUDO_CMD chmod +x "$DNS_INSTALL_DIR"/*.sh
    
    log_message "DNS Project installed"
}

# تابع نصب Tunnel Project
install_tunnel_project() {
    info_message "Installing Tunnel Project..."
    
    # ایجاد دایرکتوری نصب
    $SUDO_CMD mkdir -p "$TUNNEL_INSTALL_DIR"
    
    # کپی فایل‌های tunnel-project
    if [[ -d "$TEMP_DIR/tunnel-project" ]]; then
        $SUDO_CMD cp -r "$TEMP_DIR/tunnel-project"/* "$TUNNEL_INSTALL_DIR/"
        log_message "tunnel-project files copied"
    else
        warning_message "tunnel-project folder not found - skipping..."
        return
    fi
    
    # تنظیم مجوزها
    $SUDO_CMD chown -R "$USER:$USER" "$TUNNEL_INSTALL_DIR"
    $SUDO_CMD chmod +x "$TUNNEL_INSTALL_DIR"/*.sh
    
    log_message "Tunnel Project installed"
}

# تابع تنظیم خودکار DNS
setup_dns_automatically() {
    info_message "Setting up DNS Project automatically..."
    
    # ایجاد پوشه تنظیمات
    mkdir -p ~/.byosh/profiles
    
    # ایجاد پروفایل پیش‌فرض
    cat > ~/.byosh/profiles/default << 'EOF'
# ByoSH Profile - default
# Created: $(date)

PROFILE_NAME="default"
DISPLAY_NAME="Default Server"
PUB_IP="127.0.0.1"
DNS_PORT="53"
CONTAINER_NAME="byosh-default"
DESCRIPTION="Default DNS server"
CREATED_DATE="$(date)"
EOF

    log_message "Default DNS profile created"
}

# تابع تنظیم خودکار Tunnel
setup_tunnel_automatically() {
    info_message "Setting up Tunnel Project automatically..."
    
    # تنظیم متغیرهای پیش‌فرض
    SERVER_TYPE=${SERVER_TYPE:-"foreign"}
    FOREIGN_IP=${FOREIGN_IP:-"0.0.0.0"}
    FOREIGN_PORT=${FOREIGN_PORT:-"2222"}
    FOREIGN_USER=${FOREIGN_USER:-"tunnel"}
    LOCAL_PORT=${LOCAL_PORT:-"8080"}
    TUNNEL_PORT=${TUNNEL_PORT:-"1080"}
    
    # نمایش تنظیمات
    echo -e "${BLUE}=== Tunnel Configuration ===${NC}"
    echo "Server Type: $SERVER_TYPE"
    if [[ "$SERVER_TYPE" == "iran" ]]; then
        echo "Foreign IP: $FOREIGN_IP"
        echo "Foreign Port: $FOREIGN_PORT"
        echo "Foreign User: $FOREIGN_USER"
        echo "Local Port: $LOCAL_PORT"
        echo "Tunnel Port: $TUNNEL_PORT"
    else
        echo "SSH Port: $FOREIGN_PORT"
        echo "Tunnel Port: $TUNNEL_PORT"
    fi
    
    # ایجاد پوشه تنظیمات
    $SUDO_CMD mkdir -p /etc/tunnel
    
    # ایجاد فایل کانفیگ
    $SUDO_CMD tee /etc/tunnel/config.conf > /dev/null << EOF
# Tunnel Configuration - $(date)
SERVER_TYPE="$SERVER_TYPE"
FOREIGN_IP="$FOREIGN_IP"
FOREIGN_PORT="$FOREIGN_PORT"
FOREIGN_USER="$FOREIGN_USER"
LOCAL_PORT="$LOCAL_PORT"
TUNNEL_PORT="$TUNNEL_PORT"
EOF

    log_message "Tunnel configuration created for $SERVER_TYPE server"
}

# تابع ایجاد اسکریپت‌های مدیریت
create_management_scripts() {
    info_message "Creating management scripts..."
    
    # اسکریپت مدیریت DNS
    $SUDO_CMD tee /usr/local/bin/byosh > /dev/null << 'EOF'
#!/bin/bash

# DNS ByoSH Management Script
case "${1:-help}" in
    "list")
        if [[ -d ~/.byosh/profiles ]]; then
            echo "Available profiles:"
            ls ~/.byosh/profiles/ 2>/dev/null || echo "No profiles found"
        else
            echo "Profiles folder not found"
        fi
        ;;
    "start")
        PROFILE="${2:-default}"
        if [[ -f ~/.byosh/profiles/$PROFILE ]]; then
            source ~/.byosh/profiles/$PROFILE
            echo "Starting container $CONTAINER_NAME..."
            docker run -d --name "$CONTAINER_NAME" -p "$DNS_PORT:53/udp" --restart unless-stopped byosh/byosh || {
                echo "Container already running or error occurred"
            }
        else
            echo "Profile $PROFILE not found"
        fi
        ;;
    "stop")
        PROFILE="${2:-default}"
        if [[ -f ~/.byosh/profiles/$PROFILE ]]; then
            source ~/.byosh/profiles/$PROFILE
            echo "Stopping container $CONTAINER_NAME..."
            docker stop "$CONTAINER_NAME" 2>/dev/null || echo "Container already stopped"
        else
            echo "Profile $PROFILE not found"
        fi
        ;;
    "status")
        echo "DNS Container Status:"
        docker ps -a --filter "name=byosh-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    "logs")
        PROFILE="${2:-default}"
        if [[ -f ~/.byosh/profiles/$PROFILE ]]; then
            source ~/.byosh/profiles/$PROFILE
            docker logs "$CONTAINER_NAME" 2>/dev/null || echo "Container not found"
        else
            echo "Profile $PROFILE not found"
        fi
        ;;
    "clean")
        echo "Cleaning stopped containers..."
        docker container prune -f
        ;;
    "help"|*)
        echo "ByoSH Usage:"
        echo "  byosh list                # List profiles"
        echo "  byosh start [profile]     # Start profile"
        echo "  byosh stop [profile]     # Stop profile"
        echo "  byosh status             # Container status"
        echo "  byosh logs [profile]     # Show logs"
        echo "  byosh clean              # Clean up"
        ;;
esac
EOF

    # اسکریپت مدیریت Tunnel
    $SUDO_CMD tee /usr/local/bin/tunnel > /dev/null << 'EOF'
#!/bin/bash

# Tunnel Management Script
case "${1:-help}" in
    "start")
        echo "Starting tunnel..."
        if [[ -f /etc/tunnel/config.conf ]]; then
            source /etc/tunnel/config.conf
            if [[ "$SERVER_TYPE" == "iran" ]]; then
                /opt/tunnel/tunnel_client.sh start
            else
                /opt/tunnel/tunnel_server.sh start
            fi
        else
            echo "Config file not found - run setup first"
        fi
        ;;
    "stop")
        echo "Stopping tunnel..."
        if [[ -f /etc/tunnel/config.conf ]]; then
            source /etc/tunnel/config.conf
            if [[ "$SERVER_TYPE" == "iran" ]]; then
                /opt/tunnel/tunnel_client.sh stop
            else
                /opt/tunnel/tunnel_server.sh stop
            fi
        fi
        ;;
    "status")
        echo "Tunnel Status:"
        if [[ -f /etc/tunnel/config.conf ]]; then
            source /etc/tunnel/config.conf
            echo "Server Type: $SERVER_TYPE"
            echo "Foreign IP: $FOREIGN_IP"
            echo "Foreign Port: $FOREIGN_PORT"
            echo "Local Port: $LOCAL_PORT"
        else
            echo "Config file not found"
        fi
        ;;
    "monitor")
        echo "Live monitoring..."
        /opt/tunnel/tunnel_manager.sh monitor
        ;;
    "optimize")
        echo "Optimizing tunnel..."
        /opt/tunnel/optimize_tunnel.sh all
        ;;
    "restart")
        tunnel stop
        sleep 2
        tunnel start
        ;;
    "help"|*)
        echo "Tunnel Usage:"
        echo "  tunnel start      # Start tunnel"
        echo "  tunnel stop       # Stop tunnel"
        echo "  tunnel restart    # Restart tunnel"
        echo "  tunnel status     # Tunnel status"
        echo "  tunnel monitor    # Live monitoring"
        echo "  tunnel optimize   # Optimization"
        ;;
esac
EOF
    
    $SUDO_CMD chmod +x /usr/local/bin/byosh
    $SUDO_CMD chmod +x /usr/local/bin/tunnel
    
    log_message "Management scripts created"
}

# تابع پاکسازی
cleanup() {
    info_message "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    log_message "Cleanup completed"
}

# تابع نمایش خلاصه نصب
show_install_summary() {
    echo -e "${GREEN}=== Installation Completed Successfully ===${NC}"
    echo ""
    echo -e "${BLUE}✅ Installed Projects:${NC}"
    echo "  - DNS Project: $DNS_INSTALL_DIR"
    echo "  - Tunnel Project: $TUNNEL_INSTALL_DIR"
    echo "  - DNS Management Script: /usr/local/bin/byosh"
    echo "  - Tunnel Management Script: /usr/local/bin/tunnel"
    echo ""
    echo -e "${BLUE}🌐 Server Configuration:${NC}"
    echo "  - Server Type: $SERVER_TYPE"
    if [[ "$SERVER_TYPE" == "iran" ]]; then
        echo "  - Foreign IP: $FOREIGN_IP"
        echo "  - SSH Port: $FOREIGN_PORT"
        echo "  - Username: $FOREIGN_USER"
        echo "  - Local Port: $LOCAL_PORT"
        echo "  - Tunnel Port: $TUNNEL_PORT"
    else
        echo "  - SSH Port: $FOREIGN_PORT"
        echo "  - Tunnel Port: $TUNNEL_PORT"
    fi
    echo ""
    echo -e "${BLUE}🚀 Ready to Use Commands:${NC}"
    echo ""
    echo -e "${YELLOW}DNS Commands:${NC}"
    echo "  byosh list                # List profiles"
    echo "  byosh start               # Start DNS"
    echo "  byosh status              # DNS status"
    echo "  byosh logs                # Show logs"
    echo ""
    echo -e "${YELLOW}Tunnel Commands:${NC}"
    echo "  tunnel start              # Start tunnel"
    echo "  tunnel stop               # Stop tunnel"
    echo "  tunnel status             # Tunnel status"
    echo "  tunnel monitor            # Live monitoring"
    echo "  tunnel optimize            # Optimization"
    echo ""
    echo -e "${GREEN}🎉 Everything is ready!${NC}"
    echo -e "${BLUE}💡 You can use the commands above immediately${NC}"
    echo ""
    echo -e "${YELLOW}📝 Note: For advanced settings, edit config files${NC}"
    echo "  - DNS: ~/.byosh/profiles/"
    echo "  - Tunnel: /etc/tunnel/config.conf"
}

# تابع اصلی
main() {
    show_banner
    
    # بررسی دسترسی root و تنظیم متغیرها
    if [[ $EUID -eq 0 ]]; then
        warning_message "Running script with root privileges - setting variables..."
        USER="root"
        USER_HOME="/root"
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi
    
    # نمایش راهنما اگر درخواست شده
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # مراحل نصب
    check_dependencies
    download_project
    install_system_dependencies
    install_dns_project
    install_tunnel_project
    create_management_scripts
    
    # تنظیم خودکار پروژه‌ها
    info_message "Starting automatic project setup..."
    
    # تنظیم خودکار DNS
    setup_dns_automatically
    log_message "✅ DNS Project ready"
    
    # تنظیم خودکار Tunnel
    setup_tunnel_automatically
    log_message "✅ Tunnel Project ready"
    
    cleanup
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
