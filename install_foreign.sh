#!/bin/bash

# اسکریپت نصب برای سرور خارج (سرور)
# این اسکریپت فقط برای سرور خارج طراحی شده است

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
    echo "║                    نصب سرور خارج v1.0                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# تابع دریافت تنظیمات سرور خارج
get_server_settings() {
    echo -e "${BLUE}=== تنظیمات سرور خارج ===${NC}"
    echo ""
    echo -e "${YELLOW}لطفاً تنظیمات سرور خارج را وارد کنید:${NC}"
    echo ""
    
    echo -n -e "${BLUE}پورت SSH سرور [2222]: ${NC}"
    read -r SSH_PORT
    SSH_PORT=${SSH_PORT:-2222}
    
    echo -n -e "${BLUE}پورت تانل [1080]: ${NC}"
    read -r TUNNEL_PORT
    TUNNEL_PORT=${TUNNEL_PORT:-1080}
    
    echo ""
    echo -e "${GREEN}✅ تنظیمات سرور خارج ذخیره شد${NC}"
}

# تابع بررسی وابستگی‌ها
check_dependencies() {
    info_message "بررسی وابستگی‌ها..."
    
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
    
    log_message "وابستگی‌ها بررسی شد"
}

# تابع دانلود پروژه
download_project() {
    info_message "دانلود پروژه از GitHub..."
    
    # پاکسازی دایرکتوری موقت
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # کلون کردن پروژه
    if git clone "$REPO_URL" "$TEMP_DIR"; then
        log_message "پروژه با موفقیت دانلود شد"
    else
        error_message "خطا در دانلود پروژه از GitHub"
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
    
    log_message "وابستگی‌های سیستم نصب شد"
}

# تابع نصب DNS Project
install_dns_project() {
    info_message "نصب DNS Project..."
    
    # ایجاد دایرکتوری نصب
    $SUDO_CMD mkdir -p "$DNS_INSTALL_DIR"
    
    # کپی فایل‌های dns-project
    if [[ -d "$TEMP_DIR/dns-project" ]]; then
        $SUDO_CMD cp -r "$TEMP_DIR/dns-project"/* "$DNS_INSTALL_DIR/"
        log_message "فایل‌های dns-project کپی شد"
    else
        warning_message "پوشه dns-project یافت نشد - رد می‌شود..."
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
        log_message "فایل‌های tunnel-project کپی شد"
    else
        warning_message "پوشه tunnel-project یافت نشد - رد می‌شود..."
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

    log_message "پروفایل پیش‌فرض DNS ایجاد شد"
}

# تابع تنظیم خودکار Tunnel
setup_tunnel_automatically() {
    info_message "تنظیم خودکار Tunnel Project..."
    
    # تنظیم نوع سرور
    SERVER_TYPE="foreign"
    FOREIGN_IP="0.0.0.0"
    FOREIGN_PORT="$SSH_PORT"
    FOREIGN_USER="tunnel"
    LOCAL_PORT="8080"
    
    # ایجاد پوشه تنظیمات
    $SUDO_CMD mkdir -p /etc/tunnel
    
    # ایجاد فایل کانفیگ
    $SUDO_CMD tee /etc/tunnel/config.conf > /dev/null << EOF
# Tunnel Configuration - Foreign Server (Server)
# Created: $(date)
SERVER_TYPE="$SERVER_TYPE"
FOREIGN_IP="$FOREIGN_IP"
FOREIGN_PORT="$FOREIGN_PORT"
FOREIGN_USER="$FOREIGN_USER"
LOCAL_PORT="$LOCAL_PORT"
TUNNEL_PORT="$TUNNEL_PORT"
EOF

    log_message "تنظیمات تانل برای سرور خارج ایجاد شد"
}

# تابع ایجاد اسکریپت‌های مدیریت
create_management_scripts() {
    info_message "ایجاد اسکریپت‌های مدیریت..."
    
    # اسکریپت مدیریت DNS
    $SUDO_CMD tee /usr/local/bin/byosh > /dev/null << 'EOF'
#!/bin/bash

# DNS ByoSH Management Script
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
            echo "توقف کانتینر $CONTAINER_NAME..."
            docker stop "$CONTAINER_NAME" 2>/dev/null || echo "کانتینر قبلاً متوقف شده"
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
        echo "پاکسازی کانتینرهای متوقف شده..."
        docker container prune -f
        ;;
    "help"|*)
        echo "استفاده از ByoSH:"
        echo "  byosh list                # لیست پروفایل‌ها"
        echo "  byosh start [profile]     # شروع پروفایل"
        echo "  byosh stop [profile]     # توقف پروفایل"
        echo "  byosh status             # وضعیت کانتینرها"
        echo "  byosh logs [profile]     # نمایش لاگ‌ها"
        echo "  byosh clean              # پاکسازی"
        ;;
esac
EOF

    # اسکریپت مدیریت Tunnel
    $SUDO_CMD tee /usr/local/bin/tunnel > /dev/null << 'EOF'
#!/bin/bash

# Tunnel Management Script - Foreign Server (Server)
case "${1:-help}" in
    "start")
        echo "شروع تانل سرور..."
        if [[ -f /etc/tunnel/config.conf ]]; then
            /opt/tunnel/tunnel_server.sh start
        else
            echo "فایل کانفیگ یافت نشد - ابتدا setup را اجرا کنید"
        fi
        ;;
    "stop")
        echo "توقف تانل سرور..."
        if [[ -f /etc/tunnel/config.conf ]]; then
            /opt/tunnel/tunnel_server.sh stop
        fi
        ;;
    "status")
        echo "وضعیت تانل سرور:"
        if [[ -f /etc/tunnel/config.conf ]]; then
            source /etc/tunnel/config.conf
            echo "نوع سرور: $SERVER_TYPE (سرور)"
            echo "پورت SSH: $FOREIGN_PORT"
            echo "پورت تانل: $TUNNEL_PORT"
        else
            echo "فایل کانفیگ یافت نشد"
        fi
        ;;
    "monitor")
        echo "مانیتورینگ زنده تانل سرور..."
        /opt/tunnel/tunnel_manager.sh monitor
        ;;
    "optimize")
        echo "بهینه‌سازی تانل سرور..."
        /opt/tunnel/optimize_tunnel.sh all
        ;;
    "restart")
        tunnel stop
        sleep 2
        tunnel start
        ;;
    "help"|*)
        echo "استفاده از Tunnel (سرور خارج):"
        echo "  tunnel start      # شروع تانل سرور"
        echo "  tunnel stop       # توقف تانل سرور"
        echo "  tunnel restart    # راه‌اندازی مجدد تانل"
        echo "  tunnel status     # وضعیت تانل سرور"
        echo "  tunnel monitor    # مانیتورینگ زنده"
        echo "  tunnel optimize   # بهینه‌سازی"
        ;;
esac
EOF
    
    $SUDO_CMD chmod +x /usr/local/bin/byosh
    $SUDO_CMD chmod +x /usr/local/bin/tunnel
    
    log_message "اسکریپت‌های مدیریت ایجاد شد"
}

# تابع پاکسازی
cleanup() {
    info_message "پاکسازی فایل‌های موقت..."
    rm -rf "$TEMP_DIR"
    log_message "پاکسازی تکمیل شد"
}

# تابع نمایش خلاصه نصب
show_install_summary() {
    echo -e "${GREEN}=== نصب سرور خارج با موفقیت تکمیل شد ===${NC}"
    echo ""
    echo -e "${BLUE}✅ پروژه‌های نصب شده:${NC}"
    echo "  - DNS Project: $DNS_INSTALL_DIR"
    echo "  - Tunnel Project: $TUNNEL_INSTALL_DIR"
    echo "  - اسکریپت مدیریت DNS: /usr/local/bin/byosh"
    echo "  - اسکریپت مدیریت تانل: /usr/local/bin/tunnel"
    echo ""
    echo -e "${BLUE}🌐 تنظیمات سرور خارج:${NC}"
    echo "  - نوع سرور: سرور (خارج)"
    echo "  - پورت SSH: $SSH_PORT"
    echo "  - پورت تانل: $TUNNEL_PORT"
    echo ""
    echo -e "${BLUE}🚀 دستورات آماده استفاده:${NC}"
    echo ""
    echo -e "${YELLOW}دستورات DNS:${NC}"
    echo "  byosh list                # لیست پروفایل‌ها"
    echo "  byosh start               # شروع DNS"
    echo "  byosh status              # وضعیت DNS"
    echo "  byosh logs                # نمایش لاگ‌ها"
    echo ""
    echo -e "${YELLOW}دستورات تانل سرور:${NC}"
    echo "  tunnel start              # شروع تانل سرور"
    echo "  tunnel stop               # توقف تانل سرور"
    echo "  tunnel status             # وضعیت تانل سرور"
    echo "  tunnel monitor            # مانیتورینگ زنده"
    echo "  tunnel optimize            # بهینه‌سازی"
    echo ""
    echo -e "${GREEN}🎉 سرور خارج آماده است!${NC}"
    echo -e "${BLUE}💡 می‌توانید فوراً از دستورات بالا استفاده کنید${NC}"
    echo ""
    echo -e "${YELLOW}📝 نکته: برای تنظیمات پیشرفته، فایل‌های کانفیگ را ویرایش کنید${NC}"
    echo "  - DNS: ~/.byosh/profiles/"
    echo "  - تانل: /etc/tunnel/config.conf"
}

# تابع اصلی
main() {
    show_banner
    
    # بررسی دسترسی root و تنظیم متغیرها
    if [[ $EUID -eq 0 ]]; then
        warning_message "اسکریپت با دسترسی root اجرا می‌شود - تنظیم متغیرها..."
        USER="root"
        USER_HOME="/root"
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi
    
    # دریافت تنظیمات سرور خارج
    get_server_settings
    
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
    log_message "✅ DNS Project آماده"
    
    # تنظیم خودکار Tunnel
    setup_tunnel_automatically
    log_message "✅ Tunnel Project آماده"
    
    cleanup
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
