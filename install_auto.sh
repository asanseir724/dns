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

# تابع نصب خودکار DNS
auto_install_dns() {
    info_message "نصب خودکار DNS Project..."
    
    if [[ -f "$DNS_INSTALL_DIR/install_byosh.sh" ]]; then
        cd "$DNS_INSTALL_DIR"
        
        # ایجاد پروفایل پیش‌فرض
        cat > /tmp/dns_auto_config << 'EOF'
#!/bin/bash
# تنظیمات خودکار DNS

# اطلاعات پیش‌فرض
PROFILE_NAME="default"
DISPLAY_NAME="سرور پیش‌فرض"
PUB_IP="127.0.0.1"
DNS_PORT="53"
CONTAINER_NAME="byosh-default"
DESCRIPTION="سرور DNS پیش‌فرض"

# اجرای نصب
./install_byosh.sh << 'INSTALL_EOF'
1
default
سرور پیش‌فرض
127.0.0.1
53
سرور DNS پیش‌فرض
y
INSTALL_EOF
EOF
        
        chmod +x /tmp/dns_auto_config
        /tmp/dns_auto_config || {
            warning_message "نصب خودکار DNS ناموفق"
            return 1
        }
        
        rm -f /tmp/dns_auto_config
        log_message "DNS Project با موفقیت نصب شد"
        return 0
    else
        warning_message "فایل install_byosh.sh یافت نشد"
        return 1
    fi
}

# تابع تنظیم خودکار Tunnel
auto_setup_tunnel() {
    info_message "تنظیم خودکار Tunnel Project..."
    
    if [[ -f "$TUNNEL_INSTALL_DIR/setup_tunnel.sh" ]]; then
        cd "$TUNNEL_INSTALL_DIR"
        
        # ایجاد تنظیمات پیش‌فرض
        cat > /tmp/tunnel_auto_config << 'EOF'
#!/bin/bash
# تنظیمات خودکار Tunnel

# اجرای تنظیم
./setup_tunnel.sh << 'SETUP_EOF'
1
127.0.0.1
2222
tunnel
8080
1080
y
SETUP_EOF
EOF
        
        chmod +x /tmp/tunnel_auto_config
        /tmp/tunnel_auto_config || {
            warning_message "تنظیم خودکار Tunnel ناموفق"
            return 1
        }
        
        rm -f /tmp/tunnel_auto_config
        log_message "Tunnel Project با موفقیت تنظیم شد"
        return 0
    else
        warning_message "فایل setup_tunnel.sh یافت نشد"
        return 1
    fi
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
        /opt/dns/manage_byosh.sh list
        ;;
    "start")
        /opt/dns/manage_byosh.sh start "${2:-default}"
        ;;
    "stop")
        /opt/dns/manage_byosh.sh stop "${2:-default}"
        ;;
    "status")
        /opt/dns/manage_byosh.sh status
        ;;
    "logs")
        /opt/dns/manage_byosh.sh logs "${2:-default}"
        ;;
    "clean")
        /opt/dns/manage_byosh.sh clean
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
        /opt/tunnel/tunnel_client.sh start
        ;;
    "stop")
        /opt/tunnel/tunnel_client.sh stop
        ;;
    "status")
        /opt/tunnel/tunnel_manager.sh status
        ;;
    "monitor")
        /opt/tunnel/tunnel_manager.sh monitor
        ;;
    "optimize")
        /opt/tunnel/optimize_tunnel.sh all
        ;;
    "restart")
        /opt/tunnel/tunnel_client.sh stop
        sleep 2
        /opt/tunnel/tunnel_client.sh start
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
    
    # نصب خودکار پروژه‌ها
    info_message "شروع نصب خودکار پروژه‌ها..."
    
    # نصب خودکار DNS
    if auto_install_dns; then
        log_message "✅ DNS Project آماده و در حال اجرا"
    else
        warning_message "⚠️ DNS Project نیاز به تنظیم دستی دارد"
    fi
    
    # تنظیم خودکار Tunnel
    if auto_setup_tunnel; then
        log_message "✅ Tunnel Project آماده و در حال اجرا"
    else
        warning_message "⚠️ Tunnel Project نیاز به تنظیم دستی دارد"
    fi
    
    cleanup
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
