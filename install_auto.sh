#!/bin/bash

# اسکریپت نصب کاملاً خودکار
# این اسکریپت همه چیز را با یک دستور نصب می‌کند

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
    echo "║                    نصب کاملاً خودکار                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# تابع بررسی وابستگی‌ها
check_dependencies() {
    info_message "بررسی وابستگی‌های مورد نیاز..."
    
    # بررسی git
    if ! command -v git &> /dev/null; then
        warning_message "git نصب نیست - در حال نصب..."
        if command -v apt-get &> /dev/null; then
            $SUDO_CMD apt-get update && $SUDO_CMD apt-get install -y git
        elif command -v yum &> /dev/null; then
            $SUDO_CMD yum update -y && $SUDO_CMD yum install -y git
        elif command -v dnf &> /dev/null; then
            $SUDO_CMD dnf update -y && $SUDO_CMD dnf install -y git
        else
            error_message "نمی‌توان git را نصب کرد"
        fi
    fi
    
    # بررسی curl
    if ! command -v curl &> /dev/null; then
        warning_message "curl نصب نیست - در حال نصب..."
        if command -v apt-get &> /dev/null; then
            $SUDO_CMD apt-get install -y curl
        elif command -v yum &> /dev/null; then
            $SUDO_CMD yum install -y curl
        elif command -v dnf &> /dev/null; then
            $SUDO_CMD dnf install -y curl
        fi
    fi
    
    log_message "وابستگی‌ها بررسی شدند"
}

# تابع دانلود پروژه
download_project() {
    info_message "دانلود پروژه از گیت‌هاب..."
    
    # پاکسازی دایرکتوری موقت
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # کلون کردن پروژه
    if git clone "$REPO_URL" "$TEMP_DIR"; then
        log_message "پروژه با موفقیت دانلود شد"
    else
        error_message "خطا در دانلود پروژه از گیت‌هاب"
    fi
}

# تابع نصب وابستگی‌های سیستم
install_system_dependencies() {
    info_message "نصب وابستگی‌های سیستم..."
    
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
    
    log_message "وابستگی‌های سیستم نصب شدند"
}

# تابع نصب DNS Project
install_dns_project() {
    info_message "نصب DNS Project..."
    
    # ایجاد دایرکتوری نصب
    $SUDO_CMD mkdir -p "$DNS_INSTALL_DIR"
    
    # کپی فایل‌های dns-project
    if [[ -d "$TEMP_DIR/dns-project" ]]; then
        $SUDO_CMD cp -r "$TEMP_DIR/dns-project"/* "$DNS_INSTALL_DIR/"
        log_message "فایل‌های dns-project کپی شدند"
    else
        warning_message "پوشه dns-project یافت نشد - رد شدن..."
        return
    fi
    
    # تنظیم مجوزها
    $SUDO_CMD chown -R "$USER:$USER" "$DNS_INSTALL_DIR"
    $SUDO_CMD chmod +x "$DNS_INSTALL_DIR"/*.sh
    
    log_message "DNS Project نصب شد"
}

# تابع نصب Tunnel Project
install_tunnel_project() {
    info_message "نصب Tunnel Project..."
    
    # ایجاد دایرکتوری نصب
    $SUDO_CMD mkdir -p "$TUNNEL_INSTALL_DIR"
    
    # کپی فایل‌های tunnel-project
    if [[ -d "$TEMP_DIR/tunnel-project" ]]; then
        $SUDO_CMD cp -r "$TEMP_DIR/tunnel-project"/* "$TUNNEL_INSTALL_DIR/"
        log_message "فایل‌های tunnel-project کپی شدند"
    else
        warning_message "پوشه tunnel-project یافت نشد - رد شدن..."
        return
    fi
    
    # تنظیم مجوزها
    $SUDO_CMD chown -R "$USER:$USER" "$TUNNEL_INSTALL_DIR"
    $SUDO_CMD chmod +x "$TUNNEL_INSTALL_DIR"/*.sh
    
    log_message "Tunnel Project نصب شد"
}

# تابع تنظیم خودکار DNS
setup_dns_automatically() {
    info_message "تنظیم خودکار DNS Project..."
    
    # ایجاد پوشه تنظیمات
    mkdir -p ~/.byosh/profiles
    
    # ایجاد پروفایل پیش‌فرض
    cat > ~/.byosh/profiles/default << 'EOF'
# پروفایل ByoSH - default
# ایجاد شده در: $(date)

PROFILE_NAME="default"
DISPLAY_NAME="سرور پیش‌فرض"
PUB_IP="127.0.0.1"
DNS_PORT="53"
CONTAINER_NAME="byosh-default"
DESCRIPTION="سرور DNS پیش‌فرض"
CREATED_DATE="$(date)"
EOF

    log_message "پروفایل پیش‌فرض DNS ایجاد شد"
}

# تابع تشخیص نوع سرور
detect_server_type() {
    echo -e "${BLUE}=== Server Type Detection ===${NC}"
    echo "Please select your server type:"
    echo "1) Iran Server (Client) - Connect to foreign server"
    echo "2) Foreign Server (Server) - Receive connection from Iran server"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Please type your answer in the terminal where this script is running!${NC}"
    echo ""
    
    while true; do
        read -p "Your server type (1 or 2): " choice
        case $choice in
            1)
                SERVER_TYPE="iran"
                echo -e "${GREEN}✅ Iran Server (Client) selected${NC}"
                break
                ;;
            2)
                SERVER_TYPE="foreign"
                echo -e "${GREEN}✅ Foreign Server (Server) selected${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Please enter 1 or 2${NC}"
                echo -e "${YELLOW}💡 Make sure you're typing in the correct terminal window!${NC}"
                ;;
        esac
    done
}

# تابع دریافت اطلاعات سرور
get_server_info() {
    if [[ "$SERVER_TYPE" == "iran" ]]; then
        echo -e "${BLUE}=== Foreign Server Information ===${NC}"
        echo "Please enter foreign server details:"
        echo -e "${YELLOW}💡 Example: IP = 1.2.3.4, Port = 2222, Username = tunnel${NC}"
        echo ""
        
        read -p "Foreign server IP address: " FOREIGN_IP
        read -p "Foreign server SSH port [2222]: " FOREIGN_PORT
        FOREIGN_PORT=${FOREIGN_PORT:-2222}
        
        read -p "Foreign server username [tunnel]: " FOREIGN_USER
        FOREIGN_USER=${FOREIGN_USER:-tunnel}
        
        read -p "Local tunnel port [8080]: " LOCAL_PORT
        LOCAL_PORT=${LOCAL_PORT:-8080}
        
        read -p "Tunnel port on foreign server [1080]: " TUNNEL_PORT
        TUNNEL_PORT=${TUNNEL_PORT:-1080}
        
        echo -e "${GREEN}✅ Foreign server information saved${NC}"
    else
        echo -e "${BLUE}=== Foreign Server Configuration ===${NC}"
        echo "Default settings for foreign server:"
        
        FOREIGN_IP="0.0.0.0"
        FOREIGN_PORT="2222"
        FOREIGN_USER="tunnel"
        LOCAL_PORT="8080"
        TUNNEL_PORT="1080"
        
        echo -e "${GREEN}✅ Default foreign server settings applied${NC}"
    fi
}

# تابع تنظیم خودکار Tunnel
setup_tunnel_automatically() {
    info_message "تنظیم خودکار Tunnel Project..."
    
    # تشخیص نوع سرور
    detect_server_type
    
    # دریافت اطلاعات سرور
    get_server_info
    
    # ایجاد پوشه تنظیمات
    $SUDO_CMD mkdir -p /etc/tunnel
    
    # ایجاد فایل کانفیگ
    $SUDO_CMD tee /etc/tunnel/config.conf > /dev/null << EOF
# تنظیمات تانل - $(date)
SERVER_TYPE="$SERVER_TYPE"
FOREIGN_IP="$FOREIGN_IP"
FOREIGN_PORT="$FOREIGN_PORT"
FOREIGN_USER="$FOREIGN_USER"
LOCAL_PORT="$LOCAL_PORT"
TUNNEL_PORT="$TUNNEL_PORT"
EOF

    log_message "تنظیمات Tunnel برای سرور $SERVER_TYPE ایجاد شد"
}

# تابع ایجاد اسکریپت‌های مدیریت
create_management_scripts() {
    info_message "ایجاد اسکریپت‌های مدیریت..."
    
    # اسکریپت مدیریت DNS
    $SUDO_CMD tee /usr/local/bin/byosh > /dev/null << 'EOF'
#!/bin/bash

# اسکریپت مدیریت DNS ByoSH
case "${1:-help}" in
    "list")
        if [[ -d ~/.byosh/profiles ]]; then
            echo "پروفایل‌های موجود:"
            ls ~/.byosh/profiles/ 2>/dev/null || echo "هیچ پروفایلی یافت نشد"
        else
            echo "پوشه پروفایل‌ها یافت نشد"
        fi
        ;;
    "start")
        PROFILE="${2:-default}"
        if [[ -f ~/.byosh/profiles/$PROFILE ]]; then
            source ~/.byosh/profiles/$PROFILE
            echo "شروع کانتینر $CONTAINER_NAME..."
            docker run -d --name "$CONTAINER_NAME" -p "$DNS_PORT:53/udp" --restart unless-stopped byosh/byosh || {
                echo "کانتینر در حال اجرا است یا خطا رخ داده"
            }
        else
            echo "پروفایل $PROFILE یافت نشد"
        fi
        ;;
    "stop")
        PROFILE="${2:-default}"
        if [[ -f ~/.byosh/profiles/$PROFILE ]]; then
            source ~/.byosh/profiles/$PROFILE
            echo "متوقف کردن کانتینر $CONTAINER_NAME..."
            docker stop "$CONTAINER_NAME" 2>/dev/null || echo "کانتینر متوقف است"
        else
            echo "پروفایل $PROFILE یافت نشد"
        fi
        ;;
    "status")
        echo "وضعیت کانتینرهای DNS:"
        docker ps -a --filter "name=byosh-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    "logs")
        PROFILE="${2:-default}"
        if [[ -f ~/.byosh/profiles/$PROFILE ]]; then
            source ~/.byosh/profiles/$PROFILE
            docker logs "$CONTAINER_NAME" 2>/dev/null || echo "کانتینر یافت نشد"
        else
            echo "پروفایل $PROFILE یافت نشد"
        fi
        ;;
    "clean")
        echo "پاکسازی کانتینرهای متوقف..."
        docker container prune -f
        ;;
    "help"|*)
        echo "راهنمای استفاده از ByoSH:"
        echo "  byosh list                # لیست پروفایل‌ها"
        echo "  byosh start [profile]     # شروع پروفایل"
        echo "  byosh stop [profile]     # متوقف کردن پروفایل"
        echo "  byosh status             # وضعیت کانتینرها"
        echo "  byosh logs [profile]     # نمایش لاگ‌ها"
        echo "  byosh clean              # پاکسازی"
        ;;
esac
EOF

    # اسکریپت مدیریت Tunnel
    $SUDO_CMD tee /usr/local/bin/tunnel > /dev/null << 'EOF'
#!/bin/bash

# اسکریپت مدیریت تانل
case "${1:-help}" in
    "start")
        echo "شروع تانل..."
        if [[ -f /etc/tunnel/config.conf ]]; then
            source /etc/tunnel/config.conf
            if [[ "$SERVER_TYPE" == "iran" ]]; then
                /opt/tunnel/tunnel_client.sh start
            else
                /opt/tunnel/tunnel_server.sh start
            fi
        else
            echo "فایل کانفیگ یافت نشد - ابتدا setup را اجرا کنید"
        fi
        ;;
    "stop")
        echo "متوقف کردن تانل..."
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
        echo "وضعیت تانل..."
        if [[ -f /etc/tunnel/config.conf ]]; then
            source /etc/tunnel/config.conf
            echo "نوع سرور: $SERVER_TYPE"
            echo "IP خارجی: $FOREIGN_IP"
            echo "پورت خارجی: $FOREIGN_PORT"
            echo "پورت محلی: $LOCAL_PORT"
        else
            echo "فایل کانفیگ یافت نشد"
        fi
        ;;
    "monitor")
        echo "مانیتورینگ زنده..."
        /opt/tunnel/tunnel_manager.sh monitor
        ;;
    "optimize")
        echo "بهینه‌سازی تانل..."
        /opt/tunnel/optimize_tunnel.sh all
        ;;
    "restart")
        tunnel stop
        sleep 2
        tunnel start
        ;;
    "help"|*)
        echo "راهنمای استفاده از تانل:"
        echo "  tunnel start      # شروع تانل"
        echo "  tunnel stop       # متوقف کردن تانل"
        echo "  tunnel restart    # راه‌اندازی مجدد"
        echo "  tunnel status     # وضعیت تانل"
        echo "  tunnel monitor    # مانیتورینگ زنده"
        echo "  tunnel optimize   # بهینه‌سازی"
        ;;
esac
EOF
    
    $SUDO_CMD chmod +x /usr/local/bin/byosh
    $SUDO_CMD chmod +x /usr/local/bin/tunnel
    
    log_message "اسکریپت‌های مدیریت ایجاد شدند"
}

# تابع پاکسازی
cleanup() {
    info_message "پاکسازی فایل‌های موقت..."
    rm -rf "$TEMP_DIR"
    log_message "پاکسازی انجام شد"
}

# تابع نمایش خلاصه نصب
show_install_summary() {
    echo -e "${GREEN}=== نصب کاملاً خودکار با موفقیت انجام شد ===${NC}"
    echo ""
    echo -e "${BLUE}✅ پروژه‌های نصب شده:${NC}"
    echo "  - DNS Project: $DNS_INSTALL_DIR"
    echo "  - Tunnel Project: $TUNNEL_INSTALL_DIR"
    echo "  - اسکریپت مدیریت DNS: /usr/local/bin/byosh"
    echo "  - اسکریپت مدیریت Tunnel: /usr/local/bin/tunnel"
    echo ""
    echo -e "${BLUE}🌐 Server Type:${NC}"
    if [[ "$SERVER_TYPE" == "iran" ]]; then
        echo "  - Iran Server (Client) - Connect to foreign server"
        echo "  - Foreign server IP: $FOREIGN_IP"
        echo "  - SSH port: $FOREIGN_PORT"
        echo "  - Username: $FOREIGN_USER"
    else
        echo "  - Foreign Server (Server) - Receive connection from Iran server"
        echo "  - SSH port: $FOREIGN_PORT"
        echo "  - Tunnel port: $TUNNEL_PORT"
    fi
    echo ""
    echo -e "${BLUE}🚀 دستورات آماده برای استفاده:${NC}"
    echo ""
    echo -e "${YELLOW}DNS Commands:${NC}"
    echo "  byosh list                # لیست پروفایل‌ها"
    echo "  byosh start               # شروع DNS"
    echo "  byosh status              # وضعیت DNS"
    echo "  byosh logs                # نمایش لاگ‌ها"
    echo ""
    echo -e "${YELLOW}Tunnel Commands:${NC}"
    echo "  tunnel start              # شروع تانل"
    echo "  tunnel stop               # متوقف کردن تانل"
    echo "  tunnel status             # وضعیت تانل"
    echo "  tunnel monitor            # مانیتورینگ زنده"
    echo "  tunnel optimize            # بهینه‌سازی"
    echo ""
    echo -e "${GREEN}🎉 همه چیز آماده است!${NC}"
    echo -e "${BLUE}💡 می‌توانید فوراً از دستورات بالا استفاده کنید${NC}"
    echo ""
    echo -e "${YELLOW}📝 نکته: برای تنظیمات پیشرفته، فایل‌های کانفیگ را ویرایش کنید${NC}"
    echo "  - DNS: ~/.byosh/profiles/"
    echo "  - Tunnel: /etc/tunnel/config.conf"
}

# تابع اصلی
main() {
    show_banner
    
    # بررسی دسترسی root و تنظیم متغیرها
    if [[ $EUID -eq 0 ]]; then
        warning_message "اجرای اسکریپت با دسترسی root - تنظیم متغیرها..."
        USER="root"
        USER_HOME="/root"
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi
    
    # مراحل نصب
    check_dependencies
    download_project
    install_system_dependencies
    install_dns_project
    install_tunnel_project
    create_management_scripts
    
    # تنظیم خودکار پروژه‌ها
    info_message "شروع تنظیم خودکار پروژه‌ها..."
    
    # تنظیم خودکار DNS
    setup_dns_automatically
    log_message "✅ DNS Project آماده است"
    
    # تنظیم خودکار Tunnel
    setup_tunnel_automatically
    log_message "✅ Tunnel Project آماده است"
    
    cleanup
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
