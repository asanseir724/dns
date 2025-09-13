#!/bin/bash

# اسکریپت نصب خودکار تانل
# این اسکریپت برای نصب خودکار روی هر دو سرور طراحی شده است

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
INSTALL_DIR="/opt/tunnel"
SERVICE_DIR="/etc/systemd/system"
LOG_DIR="/var/log/tunnel"

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
    echo "║                    سیستم تانل خودکار                        ║"
    echo "║              برای اتصال سرور ایران و خارج                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# تابع بررسی سیستم عامل
check_os() {
    info_message "بررسی سیستم عامل..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_message "سیستم عامل: $OS $VER"
    
    # بررسی پشتیبانی
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            PACKAGE_MANAGER="apt"
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            PACKAGE_MANAGER="yum"
            ;;
        *)
            warning_message "سیستم عامل پشتیبانی نشده: $OS"
            read -p "آیا ادامه دهید؟ (y/N): " continue_install
            if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

# تابع نصب وابستگی‌ها
install_dependencies() {
    info_message "نصب وابستگی‌های مورد نیاز..."
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt-get update
            sudo apt-get install -y curl wget git netcat-openbsd openssh-client openssh-server autossh ufw bc
            ;;
        "yum")
            sudo yum update -y
            sudo yum install -y curl wget git nc openssh-clients openssh-server autossh firewalld bc
            ;;
    esac
    
    log_message "وابستگی‌ها با موفقیت نصب شدند"
}

# تابع ایجاد دایرکتوری‌ها
create_directories() {
    info_message "ایجاد دایرکتوری‌های مورد نیاز..."
    
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$LOG_DIR"
    sudo mkdir -p "/etc/tunnel"
    
    # تنظیم مجوزها
    sudo chown -R "$USER:$USER" "$INSTALL_DIR"
    sudo chown -R "$USER:$USER" "$LOG_DIR"
    
    log_message "دایرکتوری‌ها ایجاد شدند"
}

# تابع کپی فایل‌ها
copy_files() {
    info_message "کپی فایل‌های اسکریپت..."
    
    # کپی اسکریپت‌ها
    sudo cp tunnel_client.sh "$INSTALL_DIR/"
    sudo cp tunnel_server.sh "$INSTALL_DIR/"
    sudo cp tunnel_manager.sh "$INSTALL_DIR/"
    sudo cp setup_tunnel.sh "$INSTALL_DIR/"
    
    # تنظیم مجوزهای اجرا
    sudo chmod +x "$INSTALL_DIR"/*.sh
    
    # ایجاد لینک‌های نمادین
    sudo ln -sf "$INSTALL_DIR/tunnel_client.sh" /usr/local/bin/tunnel-client
    sudo ln -sf "$INSTALL_DIR/tunnel_server.sh" /usr/local/bin/tunnel-server
    sudo ln -sf "$INSTALL_DIR/tunnel_manager.sh" /usr/local/bin/tunnel-manager
    sudo ln -sf "$INSTALL_DIR/setup_tunnel.sh" /usr/local/bin/setup-tunnel
    
    log_message "فایل‌ها کپی شدند"
}

# تابع ایجاد فایل کانفیگ پیش‌فرض
create_default_config() {
    info_message "ایجاد فایل کانفیگ پیش‌فرض..."
    
    sudo tee "/etc/tunnel/default.conf" > /dev/null << 'EOF'
# تنظیمات پیش‌فرض تانل
# این فایل به عنوان الگو استفاده می‌شود

# نوع سرور (iran یا foreign)
SERVER_TYPE=""

# تنظیمات سرور ایران (کلاینت)
REMOTE_SERVER=""
REMOTE_PORT="22"
REMOTE_USER="tunnel"
LOCAL_PORT="8080"
TUNNEL_PORT="1080"

# تنظیمات سرور خارج (سرور)
SSH_PORT="2222"
TUNNEL_PORT="1080"

# تنظیمات عمومی
LOG_LEVEL="INFO"
AUTO_RESTART="true"
MONITOR_INTERVAL="30"
EOF
    
    log_message "فایل کانفیگ پیش‌فرض ایجاد شد"
}

# تابع ایجاد سرویس‌های systemd
create_systemd_services() {
    info_message "ایجاد سرویس‌های systemd..."
    
    # سرویس کلاینت
    sudo tee "$SERVICE_DIR/iran-tunnel.service" > /dev/null << EOF
[Unit]
Description=Iran Tunnel Client Service
After=network.target
Wants=network.target

[Service]
Type=forking
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/tunnel_client.sh start
ExecStop=$INSTALL_DIR/tunnel_client.sh stop
ExecReload=$INSTALL_DIR/tunnel_client.sh restart
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # سرویس سرور
    sudo tee "$SERVICE_DIR/foreign-tunnel.service" > /dev/null << EOF
[Unit]
Description=Foreign Tunnel Server Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/tunnel_server.sh start
ExecStop=$INSTALL_DIR/tunnel_server.sh stop
ExecReload=$INSTALL_DIR/tunnel_server.sh restart
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # بارگذاری مجدد systemd
    sudo systemctl daemon-reload
    
    log_message "سرویس‌های systemd ایجاد شدند"
}

# تابع تنظیم فایروال
setup_firewall() {
    info_message "تنظیم فایروال..."
    
    case $PACKAGE_MANAGER in
        "apt")
            # Ubuntu/Debian - UFW
            sudo ufw --force enable
            sudo ufw allow 22/tcp comment "SSH"
            sudo ufw allow 2222/tcp comment "Tunnel SSH"
            sudo ufw allow 8080/tcp comment "Tunnel Local"
            sudo ufw allow 1080/tcp comment "Tunnel Port"
            sudo ufw reload
            ;;
        "yum")
            # CentOS/RHEL/Fedora - firewalld
            sudo systemctl enable firewalld
            sudo systemctl start firewalld
            sudo firewall-cmd --permanent --add-port=22/tcp
            sudo firewall-cmd --permanent --add-port=2222/tcp
            sudo firewall-cmd --permanent --add-port=8080/tcp
            sudo firewall-cmd --permanent --add-port=1080/tcp
            sudo firewall-cmd --reload
            ;;
    esac
    
    log_message "فایروال تنظیم شد"
}

# تابع ایجاد کاربر تانل
create_tunnel_user() {
    info_message "ایجاد کاربر تانل..."
    
    if ! id "tunnel" &>/dev/null; then
        sudo useradd -m -s /bin/bash tunnel
        sudo usermod -aG sudo tunnel
        log_message "کاربر tunnel ایجاد شد"
    else
        log_message "کاربر tunnel قبلاً وجود دارد"
    fi
    
    # ایجاد دایرکتوری SSH
    sudo mkdir -p /home/tunnel/.ssh
    sudo chmod 700 /home/tunnel/.ssh
    sudo chown tunnel:tunnel /home/tunnel/.ssh
}

# تابع تنظیم SSH
setup_ssh() {
    info_message "تنظیم SSH..."
    
    # فعال‌سازی SSH
    sudo systemctl enable ssh
    sudo systemctl start ssh
    
    # تنظیم SSH config
    sudo tee -a /etc/ssh/sshd_config > /dev/null << 'EOF'

# تنظیمات تانل
Port 22
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ClientAliveInterval 30
ClientAliveCountMax 3
GatewayPorts yes
TCPKeepAlive yes
EOF
    
    # راه‌اندازی مجدد SSH
    sudo systemctl restart ssh
    
    log_message "SSH تنظیم شد"
}

# تابع ایجاد اسکریپت مدیریت
create_management_script() {
    info_message "ایجاد اسکریپت مدیریت..."
    
    sudo tee /usr/local/bin/tunnel > /dev/null << 'EOF'
#!/bin/bash

# اسکریپت مدیریت تانل
# این اسکریپت برای مدیریت آسان تانل طراحی شده است

case "${1:-help}" in
    "install")
        echo "نصب وابستگی‌ها..."
        /usr/local/bin/setup-tunnel install
        ;;
    "setup")
        echo "تنظیم اولیه..."
        /usr/local/bin/setup-tunnel
        ;;
    "start")
        echo "شروع تانل..."
        if [[ -f "/etc/tunnel/config.conf" ]]; then
            source /etc/tunnel/config.conf
            if [[ "$SERVER_TYPE" == "iran" ]]; then
                /usr/local/bin/tunnel-client start
            else
                /usr/local/bin/tunnel-server start
            fi
        else
            echo "ابتدا setup را اجرا کنید"
        fi
        ;;
    "stop")
        echo "متوقف کردن تانل..."
        if [[ -f "/etc/tunnel/config.conf" ]]; then
            source /etc/tunnel/config.conf
            if [[ "$SERVER_TYPE" == "iran" ]]; then
                /usr/local/bin/tunnel-client stop
            else
                /usr/local/bin/tunnel-server stop
            fi
        fi
        ;;
    "status")
        echo "وضعیت تانل..."
        /usr/local/bin/tunnel-manager status
        ;;
    "monitor")
        echo "مانیتورینگ زنده..."
        /usr/local/bin/tunnel-manager monitor
        ;;
    "help"|*)
        echo "راهنمای استفاده از تانل:"
        echo "  tunnel install    # نصب وابستگی‌ها"
        echo "  tunnel setup      # تنظیم اولیه"
        echo "  tunnel start      # شروع تانل"
        echo "  tunnel stop       # متوقف کردن تانل"
        echo "  tunnel status     # وضعیت تانل"
        echo "  tunnel monitor    # مانیتورینگ زنده"
        echo "  tunnel help       # نمایش راهنما"
        ;;
esac
EOF
    
    sudo chmod +x /usr/local/bin/tunnel
    
    log_message "اسکریپت مدیریت ایجاد شد"
}

# تابع نمایش خلاصه نصب
show_install_summary() {
    echo -e "${GREEN}=== نصب با موفقیت انجام شد ===${NC}"
    echo ""
    echo -e "${BLUE}فایل‌های نصب شده:${NC}"
    echo "  - اسکریپت کلاینت: $INSTALL_DIR/tunnel_client.sh"
    echo "  - اسکریپت سرور: $INSTALL_DIR/tunnel_server.sh"
    echo "  - اسکریپت مدیریت: $INSTALL_DIR/tunnel_manager.sh"
    echo "  - اسکریپت تنظیم: $INSTALL_DIR/setup_tunnel.sh"
    echo ""
    echo -e "${BLUE}دستورات اصلی:${NC}"
    echo "  tunnel setup      # تنظیم اولیه"
    echo "  tunnel start      # شروع تانل"
    echo "  tunnel status     # وضعیت تانل"
    echo "  tunnel monitor    # مانیتورینگ زنده"
    echo ""
    echo -e "${YELLOW}مراحل بعدی:${NC}"
    echo "1. اجرای 'tunnel setup' برای تنظیم اولیه"
    echo "2. انتخاب نوع سرور (ایران یا خارج)"
    echo "3. وارد کردن اطلاعات سرور"
    echo "4. شروع تانل با 'tunnel start'"
    echo ""
    echo -e "${GREEN}نصب کامل شد!${NC}"
}

# تابع اصلی
main() {
    show_banner
    
    # بررسی دسترسی root
    if [[ $EUID -eq 0 ]]; then
        error_message "این اسکریپت نباید با دسترسی root اجرا شود"
    fi
    
    # بررسی وجود فایل‌ها
    REQUIRED_FILES=("tunnel_client.sh" "tunnel_server.sh" "tunnel_manager.sh" "setup_tunnel.sh")
    for file in "${REQUIRED_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            error_message "فایل مورد نیاز یافت نشد: $file"
        fi
    done
    
    # مراحل نصب
    check_os
    install_dependencies
    create_directories
    copy_files
    create_default_config
    create_systemd_services
    setup_firewall
    create_tunnel_user
    setup_ssh
    create_management_script
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
