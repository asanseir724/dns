#!/bin/bash

# اسکریپت تانل کلاینت برای سرور ایران
# این اسکریپت روی سرور ایران اجرا می‌شود

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
CONFIG_FILE="/etc/tunnel/config.conf"
LOG_FILE="/var/log/tunnel.log"
PID_FILE="/var/run/tunnel.pid"
SERVICE_NAME="iran-tunnel"

# تابع نمایش پیام
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error_message() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning_message() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# تابع بررسی وجود فایل کانفیگ
check_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error_message "فایل کانفیگ یافت نشد: $CONFIG_FILE"
        echo "لطفاً ابتدا اسکریپت setup_tunnel.sh را اجرا کنید"
        exit 1
    fi
    
    # بارگذاری تنظیمات
    source "$CONFIG_FILE"
    
    # بررسی پارامترهای ضروری
    if [[ -z "$REMOTE_SERVER" || -z "$REMOTE_PORT" || -z "$LOCAL_PORT" || -z "$TUNNEL_PORT" ]]; then
        error_message "تنظیمات ناقص در فایل کانفیگ"
        exit 1
    fi
}

# تابع نصب وابستگی‌ها
install_dependencies() {
    log_message "نصب وابستگی‌های مورد نیاز..."
    
    # به‌روزرسانی پکیج‌ها
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y autossh openssh-client netcat-openbsd curl
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y autossh openssh-clients nc curl
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf install -y autossh openssh-clients nc curl
    else
        error_message "سیستم عامل پشتیبانی نمی‌شود"
        exit 1
    fi
    
    log_message "وابستگی‌ها با موفقیت نصب شدند"
}

# تابع ایجاد کلید SSH
setup_ssh_key() {
    log_message "تنظیم کلید SSH..."
    
    SSH_DIR="$HOME/.ssh"
    KEY_FILE="$SSH_DIR/tunnel_key"
    
    if [[ ! -f "$KEY_FILE" ]]; then
        ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N "" -C "tunnel-$(hostname)"
        log_message "کلید SSH جدید ایجاد شد: $KEY_FILE"
    fi
    
    # تنظیم مجوزهای صحیح
    chmod 700 "$SSH_DIR"
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    
    log_message "کلید عمومی SSH:"
    cat "$KEY_FILE.pub"
    echo ""
    warning_message "این کلید عمومی را روی سرور خارج کپی کنید"
}

# تابع تست اتصال
test_connection() {
    log_message "تست اتصال به سرور خارج..."
    
    if nc -z "$REMOTE_SERVER" "$REMOTE_PORT" 2>/dev/null; then
        log_message "اتصال به سرور خارج برقرار است"
        return 0
    else
        error_message "اتصال به سرور خارج برقرار نیست"
        return 1
    fi
}

# تابع شروع تانل
start_tunnel() {
    log_message "شروع تانل..."
    
    # بررسی وجود تانل قبلی
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        warning_message "تانل قبلاً در حال اجرا است"
        return 1
    fi
    
    # ایجاد دایرکتوری لاگ
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    sudo touch "$LOG_FILE"
    sudo chown "$USER:$USER" "$LOG_FILE"
    
    # شروع تانل با autossh
    autossh -M 0 -f -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
        -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" \
        -i "$HOME/.ssh/tunnel_key" \
        -L "$LOCAL_PORT:localhost:$TUNNEL_PORT" \
        -p "$REMOTE_PORT" \
        "$REMOTE_USER@$REMOTE_SERVER" \
        -D "$TUNNEL_PORT" &
    
    echo $! > "$PID_FILE"
    
    # انتظار برای برقراری اتصال
    sleep 3
    
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log_message "تانل با موفقیت شروع شد (PID: $(cat "$PID_FILE"))"
        return 0
    else
        error_message "شروع تانل ناموفق بود"
        return 1
    fi
}

# تابع متوقف کردن تانل
stop_tunnel() {
    log_message "متوقف کردن تانل..."
    
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            sleep 2
            
            # بررسی توقف کامل
            if kill -0 "$PID" 2>/dev/null; then
                kill -9 "$PID"
            fi
            
            log_message "تانل متوقف شد"
        else
            warning_message "فرآیند تانل یافت نشد"
        fi
        
        rm -f "$PID_FILE"
    else
        warning_message "فایل PID یافت نشد"
    fi
}

# تابع نمایش وضعیت
show_status() {
    echo -e "${BLUE}=== وضعیت تانل ===${NC}"
    
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${GREEN}وضعیت:${NC} در حال اجرا"
        echo -e "${GREEN}PID:${NC} $(cat "$PID_FILE")"
        echo -e "${GREEN}پورت محلی:${NC} $LOCAL_PORT"
        echo -e "${GREEN}سرور خارج:${NC} $REMOTE_SERVER:$REMOTE_PORT"
        
        # تست اتصال محلی
        if nc -z localhost "$LOCAL_PORT" 2>/dev/null; then
            echo -e "${GREEN}اتصال محلی:${NC} برقرار"
        else
            echo -e "${RED}اتصال محلی:${NC} قطع"
        fi
    else
        echo -e "${RED}وضعیت:${NC} متوقف"
    fi
    
    echo -e "${BLUE}=== آخرین لاگ‌ها ===${NC}"
    tail -n 10 "$LOG_FILE" 2>/dev/null || echo "لاگ یافت نشد"
}

# تابع نمایش لاگ‌ها
show_logs() {
    echo -e "${BLUE}=== لاگ‌های تانل ===${NC}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -f "$LOG_FILE"
    else
        echo "فایل لاگ یافت نشد"
    fi
}

# تابع نمایش راهنما
show_help() {
    echo -e "${BLUE}راهنمای استفاده از اسکریپت تانل کلاینت${NC}"
    echo ""
    echo "استفاده: $0 [گزینه]"
    echo ""
    echo "گزینه‌ها:"
    echo "  install     نصب وابستگی‌ها و تنظیم اولیه"
    echo "  setup       ایجاد کلید SSH و تنظیمات"
    echo "  start       شروع تانل"
    echo "  stop        متوقف کردن تانل"
    echo "  restart     راه‌اندازی مجدد تانل"
    echo "  status      نمایش وضعیت تانل"
    echo "  logs        نمایش لاگ‌های زنده"
    echo "  test        تست اتصال به سرور خارج"
    echo "  help        نمایش این راهنما"
    echo ""
    echo "مثال‌ها:"
    echo "  $0 install    # نصب اولیه"
    echo "  $0 setup      # تنظیم کلید SSH"
    echo "  $0 start      # شروع تانل"
    echo "  $0 status     # بررسی وضعیت"
}

# تابع اصلی
main() {
    case "${1:-help}" in
        "install")
            install_dependencies
            ;;
        "setup")
            check_config
            setup_ssh_key
            ;;
        "start")
            check_config
            if test_connection; then
                start_tunnel
            else
                error_message "نمی‌توان تانل را شروع کرد - اتصال برقرار نیست"
                exit 1
            fi
            ;;
        "stop")
            stop_tunnel
            ;;
        "restart")
            stop_tunnel
            sleep 2
            check_config
            if test_connection; then
                start_tunnel
            else
                error_message "نمی‌توان تانل را راه‌اندازی مجدد کرد - اتصال برقرار نیست"
                exit 1
            fi
            ;;
        "status")
            check_config
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "test")
            check_config
            test_connection
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# اجرای تابع اصلی
main "$@"
