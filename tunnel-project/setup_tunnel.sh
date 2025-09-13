#!/bin/bash

# اسکریپت تنظیم اولیه تانل
# این اسکریپت روی هر دو سرور اجرا می‌شود

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
CONFIG_DIR="/etc/tunnel"
CONFIG_FILE="$CONFIG_DIR/config.conf"

# تابع نمایش پیام
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error_message() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning_message() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# تابع دریافت ورودی از کاربر
get_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

# تابع تشخیص نوع سرور
detect_server_type() {
    echo -e "${BLUE}=== تشخیص نوع سرور ===${NC}"
    echo "1) سرور ایران (کلاینت)"
    echo "2) سرور خارج از ایران (سرور)"
    echo ""
    
    while true; do
        read -p "نوع سرور را انتخاب کنید [1-2]: " choice
        case $choice in
            1)
                echo "iran"
                return
                ;;
            2)
                echo "foreign"
                return
                ;;
            *)
                echo "لطفاً 1 یا 2 را انتخاب کنید"
                ;;
        esac
    done
}

# تابع تنظیم سرور ایران
setup_iran_server() {
    log_message "تنظیم سرور ایران (کلاینت)..."
    
    # دریافت اطلاعات سرور خارج
    echo -e "${BLUE}=== اطلاعات سرور خارج ===${NC}"
    REMOTE_SERVER=$(get_input "آدرس IP سرور خارج")
    REMOTE_PORT=$(get_input "پورت SSH سرور خارج" "22")
    REMOTE_USER=$(get_input "نام کاربری سرور خارج" "tunnel")
    LOCAL_PORT=$(get_input "پورت محلی برای تانل" "8080")
    TUNNEL_PORT=$(get_input "پورت تانل روی سرور خارج" "1080")
    
    # ایجاد فایل کانفیگ
    sudo mkdir -p "$CONFIG_DIR"
    sudo tee "$CONFIG_FILE" > /dev/null << EOF
# تنظیمات تانل کلاینت (سرور ایران)
SERVER_TYPE="iran"
REMOTE_SERVER="$REMOTE_SERVER"
REMOTE_PORT="$REMOTE_PORT"
REMOTE_USER="$REMOTE_USER"
LOCAL_PORT="$LOCAL_PORT"
TUNNEL_PORT="$TUNNEL_PORT"
EOF
    
    log_message "فایل کانفیگ ایجاد شد: $CONFIG_FILE"
    
    # کپی اسکریپت کلاینت
    sudo cp tunnel_client.sh /usr/local/bin/tunnel_client.sh
    sudo chmod +x /usr/local/bin/tunnel_client.sh
    
    # ایجاد لینک نمادین
    sudo ln -sf /usr/local/bin/tunnel_client.sh /usr/local/bin/tunnel
    
    log_message "اسکریپت کلاینت نصب شد"
}

# تابع تنظیم سرور خارج
setup_foreign_server() {
    log_message "تنظیم سرور خارج (سرور)..."
    
    # دریافت اطلاعات سرور
    echo -e "${BLUE}=== اطلاعات سرور خارج ===${NC}"
    SSH_PORT=$(get_input "پورت SSH برای تانل" "2222")
    TUNNEL_PORT=$(get_input "پورت تانل" "1080")
    
    # ایجاد فایل کانفیگ
    sudo mkdir -p "$CONFIG_DIR"
    sudo tee "$CONFIG_FILE" > /dev/null << EOF
# تنظیمات تانل سرور (سرور خارج)
SERVER_TYPE="foreign"
SSH_PORT="$SSH_PORT"
TUNNEL_PORT="$TUNNEL_PORT"
EOF
    
    log_message "فایل کانفیگ ایجاد شد: $CONFIG_FILE"
    
    # کپی اسکریپت سرور
    sudo cp tunnel_server.sh /usr/local/bin/tunnel_server.sh
    sudo chmod +x /usr/local/bin/tunnel_server.sh
    
    # ایجاد لینک نمادین
    sudo ln -sf /usr/local/bin/tunnel_server.sh /usr/local/bin/tunnel
    
    log_message "اسکریپت سرور نصب شد"
}

# تابع ایجاد سرویس systemd
create_systemd_service() {
    local server_type="$1"
    
    log_message "ایجاد سرویس systemd..."
    
    if [[ "$server_type" == "iran" ]]; then
        SERVICE_NAME="iran-tunnel"
        SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
        
        sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Iran Tunnel Client
After=network.target

[Service]
Type=forking
User=$USER
ExecStart=/usr/local/bin/tunnel_client.sh start
ExecStop=/usr/local/bin/tunnel_client.sh stop
ExecReload=/usr/local/bin/tunnel_client.sh restart
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    else
        SERVICE_NAME="foreign-tunnel"
        SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
        
        sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Foreign Tunnel Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/tunnel_server.sh start
ExecStop=/usr/local/bin/tunnel_server.sh stop
ExecReload=/usr/local/bin/tunnel_server.sh restart
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    
    log_message "سرویس systemd ایجاد شد: $SERVICE_NAME"
}

# تابع نمایش خلاصه تنظیمات
show_summary() {
    local server_type="$1"
    
    echo -e "${BLUE}=== خلاصه تنظیمات ===${NC}"
    
    if [[ "$server_type" == "iran" ]]; then
        echo -e "${GREEN}نوع سرور:${NC} ایران (کلاینت)"
        echo -e "${GREEN}فایل کانفیگ:${NC} $CONFIG_FILE"
        echo -e "${GREEN}اسکریپت:${NC} /usr/local/bin/tunnel_client.sh"
        echo -e "${GREEN}دستورات:${NC}"
        echo "  tunnel install    # نصب وابستگی‌ها"
        echo "  tunnel setup      # تنظیم کلید SSH"
        echo "  tunnel start      # شروع تانل"
        echo "  tunnel status     # بررسی وضعیت"
    else
        echo -e "${GREEN}نوع سرور:${NC} خارج (سرور)"
        echo -e "${GREEN}فایل کانفیگ:${NC} $CONFIG_FILE"
        echo -e "${GREEN}اسکریپت:${NC} /usr/local/bin/tunnel_server.sh"
        echo -e "${GREEN}دستورات:${NC}"
        echo "  tunnel install    # نصب وابستگی‌ها"
        echo "  tunnel setup       # تنظیم SSH سرور"
        echo "  tunnel addkey      # اضافه کردن کلید عمومی"
        echo "  tunnel start       # شروع سرویس SSH"
        echo "  tunnel status      # بررسی وضعیت"
    fi
    
    echo ""
    echo -e "${YELLOW}مراحل بعدی:${NC}"
    echo "1. اجرای دستور 'tunnel install' برای نصب وابستگی‌ها"
    echo "2. اجرای دستور 'tunnel setup' برای تنظیم اولیه"
    echo "3. برای سرور خارج: اضافه کردن کلید عمومی با 'tunnel addkey'"
    echo "4. برای سرور ایران: تنظیم کلید SSH با 'tunnel setup'"
    echo "5. شروع تانل با 'tunnel start'"
}

# تابع اصلی
main() {
    echo -e "${BLUE}=== اسکریپت تنظیم تانل ===${NC}"
    echo "این اسکریپت برای تنظیم اولیه تانل بین سرور ایران و خارج طراحی شده است"
    echo ""
    
    # بررسی دسترسی root
    if [[ $EUID -eq 0 ]]; then
        error_message "این اسکریپت نباید با دسترسی root اجرا شود"
        exit 1
    fi
    
    # بررسی وجود فایل‌های اسکریپت
    if [[ ! -f "tunnel_client.sh" || ! -f "tunnel_server.sh" ]]; then
        error_message "فایل‌های اسکریپت یافت نشدند"
        echo "لطفاً مطمئن شوید که فایل‌های زیر در دایرکتوری فعلی موجود هستند:"
        echo "  - tunnel_client.sh"
        echo "  - tunnel_server.sh"
        exit 1
    fi
    
    # تشخیص نوع سرور
    SERVER_TYPE=$(detect_server_type)
    
    # تنظیم بر اساس نوع سرور
    if [[ "$SERVER_TYPE" == "iran" ]]; then
        setup_iran_server
    else
        setup_foreign_server
    fi
    
    # ایجاد سرویس systemd
    create_systemd_service "$SERVER_TYPE"
    
    # نمایش خلاصه
    show_summary "$SERVER_TYPE"
    
    log_message "تنظیم اولیه با موفقیت انجام شد"
}

# اجرای تابع اصلی
main "$@"
