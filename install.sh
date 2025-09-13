#!/bin/bash

# اسکریپت نصب خودکار از گیت‌هاب
# این اسکریپت پروژه تانل را از گیت‌هاب دانلود و نصب می‌کند

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
REPO_URL="https://github.com/USERNAME/tunnel-project.git"
INSTALL_DIR="/opt/tunnel"
TEMP_DIR="/tmp/tunnel-install"

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
    echo "║              نصب خودکار از گیت‌هاب                         ║"
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
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum update -y && sudo yum install -y git
        elif command -v dnf &> /dev/null; then
            sudo dnf update -y && sudo dnf install -y git
        else
            error_message "نمی‌توان git را نصب کرد"
        fi
    fi
    
    # بررسی curl
    if ! command -v curl &> /dev/null; then
        warning_message "curl نصب نیست - در حال نصب..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y curl
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

# تابع نصب پروژه
install_project() {
    info_message "نصب پروژه..."
    
    # ایجاد دایرکتوری نصب
    sudo mkdir -p "$INSTALL_DIR"
    
    # کپی فایل‌ها
    sudo cp -r "$TEMP_DIR"/* "$INSTALL_DIR/"
    
    # تنظیم مجوزها
    sudo chown -R "$USER:$USER" "$INSTALL_DIR"
    sudo chmod +x "$INSTALL_DIR"/*.sh
    
    # ایجاد لینک‌های نمادین
    sudo ln -sf "$INSTALL_DIR/install_tunnel.sh" /usr/local/bin/tunnel-install
    sudo ln -sf "$INSTALL_DIR/setup_tunnel.sh" /usr/local/bin/tunnel-setup
    sudo ln -sf "$INSTALL_DIR/tunnel_client.sh" /usr/local/bin/tunnel-client
    sudo ln -sf "$INSTALL_DIR/tunnel_server.sh" /usr/local/bin/tunnel-server
    sudo ln -sf "$INSTALL_DIR/tunnel_manager.sh" /usr/local/bin/tunnel-manager
    sudo ln -sf "$INSTALL_DIR/optimize_tunnel.sh" /usr/local/bin/tunnel-optimize
    
    log_message "پروژه نصب شد"
}

# تابع نصب وابستگی‌های سیستم
install_system_dependencies() {
    info_message "نصب وابستگی‌های سیستم..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y openssh-client openssh-server autossh ufw netcat-openbsd bc
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y openssh-clients openssh-server autossh firewalld nc bc
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf install -y openssh-clients openssh-server autossh firewalld nc bc
    fi
    
    log_message "وابستگی‌های سیستم نصب شدند"
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
        curl -sSL https://raw.githubusercontent.com/USERNAME/tunnel-project/main/install.sh | bash
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
    
    sudo chmod +x /usr/local/bin/tunnel
    
    log_message "اسکریپت مدیریت ایجاد شد"
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
    echo "  - دایرکتوری نصب: $INSTALL_DIR"
    echo "  - اسکریپت مدیریت: /usr/local/bin/tunnel"
    echo ""
    echo -e "${BLUE}دستورات اصلی:${NC}"
    echo "  tunnel setup      # تنظیم اولیه"
    echo "  tunnel start      # شروع تانل"
    echo "  tunnel status     # وضعیت تانل"
    echo "  tunnel monitor    # مانیتورینگ زنده"
    echo "  tunnel optimize   # بهینه‌سازی"
    echo "  tunnel update     # به‌روزرسانی"
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
    
    # مراحل نصب
    check_dependencies
    download_project
    install_system_dependencies
    install_project
    create_management_script
    cleanup
    
    # نمایش خلاصه
    show_install_summary
}

# اجرای تابع اصلی
main "$@"
