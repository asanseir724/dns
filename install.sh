#!/bin/bash

# اسکریپت نصب خودکار از گیت‌هاب
# این اسکریپت پروژه‌های DNS و Tunnel را از گیت‌هاب دانلود و نصب می‌کند

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
    echo "║                    نصب خودکار از گیت‌هاب                     ║"
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
    
    # ایجاد لینک‌های نمادین
    $SUDO_CMD ln -sf "$DNS_INSTALL_DIR/install_byosh.sh" /usr/local/bin/byosh-install
    $SUDO_CMD ln -sf "$DNS_INSTALL_DIR/manage_byosh.sh" /usr/local/bin/byosh-manage
    
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
    
    # ایجاد لینک‌های نمادین
    $SUDO_CMD ln -sf "$TUNNEL_INSTALL_DIR/install_tunnel.sh" /usr/local/bin/tunnel-install
    $SUDO_CMD ln -sf "$TUNNEL_INSTALL_DIR/setup_tunnel.sh" /usr/local/bin/tunnel-setup
    $SUDO_CMD ln -sf "$TUNNEL_INSTALL_DIR/tunnel_client.sh" /usr/local/bin/tunnel-client
    $SUDO_CMD ln -sf "$TUNNEL_INSTALL_DIR/tunnel_server.sh" /usr/local/bin/tunnel-server
    $SUDO_CMD ln -sf "$TUNNEL_INSTALL_DIR/tunnel_manager.sh" /usr/local/bin/tunnel-manager
    $SUDO_CMD ln -sf "$TUNNEL_INSTALL_DIR/optimize_tunnel.sh" /usr/local/bin/tunnel-optimize
    
    log_message "Tunnel Project نصب شد"
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

# تابع ایجاد اسکریپت‌های مدیریت
create_management_scripts() {
    info_message "ایجاد اسکریپت‌های مدیریت..."
    
    # اسکریپت مدیریت DNS
    $SUDO_CMD tee /usr/local/bin/byosh > /dev/null << 'EOF'
#!/bin/bash

# اسکریپت مدیریت DNS ByoSH
# این اسکریپت برای مدیریت آسان DNS طراحی شده است

case "${1:-help}" in
    "install")
        echo "نصب ByoSH..."
        /usr/local/bin/byosh-install
        ;;
    "manage")
        echo "مدیریت پروفایل‌ها..."
        /usr/local/bin/byosh-manage "${@:2}"
        ;;
    "help"|*)
        echo "راهنمای استفاده از ByoSH:"
        echo "  byosh install                    # نصب ByoSH"
        echo "  byosh manage list                # لیست پروفایل‌ها"
        echo "  byosh manage start profile_name  # شروع پروفایل"
        echo "  byosh manage stop profile_name   # متوقف کردن پروفایل"
        echo "  byosh manage status              # وضعیت کانتینرها"
        echo "  byosh manage logs profile_name   # نمایش لاگ‌ها"
        echo "  byosh manage clean                # پاکسازی"
        ;;
esac
EOF

    # اسکریپت مدیریت Tunnel
    $SUDO_CMD tee /usr/local/bin/tunnel > /dev/null << 'EOF'
#!/bin/bash

# اسکریپت مدیریت تانل
# این اسکریپت برای مدیریت آسان تانل طراحی شده است

case "${1:-help}" in
    "install")
        echo "نصب وابستگی‌ها..."
        /usr/local/bin/tunnel-install
        ;;
    "setup")
        echo "تنظیم اولیه..."
        /usr/local/bin/tunnel-setup
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
    "optimize")
        echo "بهینه‌سازی تانل..."
        /usr/local/bin/tunnel-optimize all
        ;;
    "update")
        echo "به‌روزرسانی پروژه..."
        curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install.sh | bash
        ;;
    "help"|*)
        echo "راهنمای استفاده از تانل:"
        echo "  tunnel install    # نصب وابستگی‌ها"
        echo "  tunnel setup      # تنظیم اولیه"
        echo "  tunnel start      # شروع تانل"
        echo "  tunnel stop       # متوقف کردن تانل"
        echo "  tunnel status     # وضعیت تانل"
        echo "  tunnel monitor    # مانیتورینگ زنده"
        echo "  tunnel optimize   # بهینه‌سازی"
        echo "  tunnel update     # به‌روزرسانی"
        echo "  tunnel help       # نمایش راهنما"
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
    echo -e "${GREEN}=== نصب با موفقیت انجام شد ===${NC}"
    echo ""
    echo -e "${BLUE}فایل‌های نصب شده:${NC}"
    echo "  - DNS Project: $DNS_INSTALL_DIR"
    echo "  - Tunnel Project: $TUNNEL_INSTALL_DIR"
    echo "  - اسکریپت مدیریت DNS: /usr/local/bin/byosh"
    echo "  - اسکریپت مدیریت Tunnel: /usr/local/bin/tunnel"
    echo ""
    echo -e "${BLUE}دستورات اصلی DNS:${NC}"
    echo "  byosh install                    # نصب ByoSH"
    echo "  byosh manage list                # لیست پروفایل‌ها"
    echo "  byosh manage start profile_name  # شروع پروفایل"
    echo "  byosh manage status              # وضعیت کانتینرها"
    echo ""
    echo -e "${BLUE}دستورات اصلی Tunnel:${NC}"
    echo "  tunnel setup      # تنظیم اولیه"
    echo "  tunnel start      # شروع تانل"
    echo "  tunnel status     # وضعیت تانل"
    echo "  tunnel monitor    # مانیتورینگ زنده"
    echo "  tunnel optimize   # بهینه‌سازی"
    echo "  tunnel update     # به‌روزرسانی"
    echo ""
    echo -e "${YELLOW}مراحل بعدی:${NC}"
    echo "1. برای DNS: اجرای 'byosh install'"
    echo "2. برای Tunnel: اجرای 'tunnel setup'"
    echo "3. انتخاب نوع سرور و وارد کردن اطلاعات"
    echo "4. شروع سرویس‌ها"
    echo ""
    echo -e "${GREEN}نصب کامل شد!${NC}"
}

# تابع اصلی
main() {
    show_banner
    
    # بررسی دسترسی root و تنظیم متغیرها
    if [[ $EUID -eq 0 ]]; then
        warning_message "اجرای اسکریپت با دسترسی root - تنظیم متغیرها..."
        # تنظیم متغیرها برای اجرای root
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
    cleanup
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
