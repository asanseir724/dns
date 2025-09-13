#!/bin/bash

# اسکریپت تانل سرور برای سرور خارج از ایران
# این اسکریپت روی سرور خارج اجرا می‌شود

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
CONFIG_FILE="/etc/tunnel/config.conf"
LOG_FILE="/var/log/tunnel-server.log"
PID_FILE="/var/run/tunnel-server.pid"
SERVICE_NAME="foreign-tunnel"
SSH_DIR="/etc/tunnel/ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

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
    if [[ -z "$TUNNEL_PORT" || -z "$SSH_PORT" ]]; then
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
        sudo apt-get install -y openssh-server ufw netcat-openbsd curl
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y openssh-server firewalld nc curl
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf install -y openssh-server firewalld nc curl
    else
        error_message "سیستم عامل پشتیبانی نمی‌شود"
        exit 1
    fi
    
    log_message "وابستگی‌ها با موفقیت نصب شدند"
}

# تابع تنظیم SSH سرور
setup_ssh_server() {
    log_message "تنظیم SSH سرور..."
    
    # ایجاد دایرکتوری SSH مخصوص تانل
    sudo mkdir -p "$SSH_DIR"
    sudo chmod 700 "$SSH_DIR"
    
    # ایجاد کلید سرور اگر وجود ندارد
    if [[ ! -f "$SSH_DIR/ssh_host_rsa_key" ]]; then
        sudo ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/ssh_host_rsa_key" -N ""
        log_message "کلید سرور SSH ایجاد شد"
    fi
    
    # تنظیم مجوزهای صحیح
    sudo chmod 600 "$SSH_DIR/ssh_host_rsa_key"
    sudo chmod 644 "$SSH_DIR/ssh_host_rsa_key.pub"
    
    # ایجاد فایل authorized_keys اگر وجود ندارد
    if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
        sudo touch "$AUTHORIZED_KEYS"
        sudo chmod 600 "$AUTHORIZED_KEYS"
        log_message "فایل authorized_keys ایجاد شد"
    fi
    
    # تنظیم SSH config
    SSH_CONFIG="/etc/ssh/sshd_config.d/tunnel.conf"
    sudo tee "$SSH_CONFIG" > /dev/null << EOF
# تنظیمات SSH برای تانل
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile $AUTHORIZED_KEYS
AllowUsers tunnel
ClientAliveInterval 30
ClientAliveCountMax 3
GatewayPorts yes
TCPKeepAlive yes
EOF
    
    log_message "تنظیمات SSH ذخیره شد"
}

# تابع ایجاد کاربر تانل
create_tunnel_user() {
    log_message "ایجاد کاربر تانل..."
    
    if ! id "tunnel" &>/dev/null; then
        sudo useradd -m -s /bin/bash tunnel
        sudo usermod -aG sudo tunnel
        log_message "کاربر tunnel ایجاد شد"
    else
        log_message "کاربر tunnel قبلاً وجود دارد"
    fi
    
    # تنظیم مجوزهای SSH برای کاربر tunnel
    sudo mkdir -p /home/tunnel/.ssh
    sudo chmod 700 /home/tunnel/.ssh
    sudo chown tunnel:tunnel /home/tunnel/.ssh
    
    # کپی کلیدهای مجاز
    if [[ -f "$AUTHORIZED_KEYS" ]]; then
        sudo cp "$AUTHORIZED_KEYS" /home/tunnel/.ssh/authorized_keys
        sudo chmod 600 /home/tunnel/.ssh/authorized_keys
        sudo chown tunnel:tunnel /home/tunnel/.ssh/authorized_keys
    fi
}

# تابع تنظیم فایروال
setup_firewall() {
    log_message "تنظیم فایروال..."
    
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian
        sudo ufw --force enable
        sudo ufw allow "$SSH_PORT"/tcp comment "SSH Tunnel"
        sudo ufw allow "$TUNNEL_PORT"/tcp comment "Tunnel Port"
        sudo ufw reload
        log_message "فایروال UFW تنظیم شد"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL/Fedora
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
        sudo firewall-cmd --permanent --add-port="$SSH_PORT"/tcp
        sudo firewall-cmd --permanent --add-port="$TUNNEL_PORT"/tcp
        sudo firewall-cmd --reload
        log_message "فایروال firewalld تنظیم شد"
    else
        warning_message "فایروال یافت نشد - لطفاً دستی تنظیم کنید"
    fi
}

# تابع شروع سرویس SSH
start_ssh_service() {
    log_message "شروع سرویس SSH..."
    
    # راه‌اندازی مجدد SSH
    sudo systemctl restart sshd
    sudo systemctl enable sshd
    
    # بررسی وضعیت سرویس
    if sudo systemctl is-active --quiet sshd; then
        log_message "سرویس SSH با موفقیت شروع شد"
    else
        error_message "شروع سرویس SSH ناموفق بود"
        return 1
    fi
}

# تابع متوقف کردن سرویس SSH
stop_ssh_service() {
    log_message "متوقف کردن سرویس SSH..."
    sudo systemctl stop sshd
    log_message "سرویس SSH متوقف شد"
}

# تابع نمایش وضعیت
show_status() {
    echo -e "${BLUE}=== وضعیت سرور تانل ===${NC}"
    
    # وضعیت SSH
    if sudo systemctl is-active --quiet sshd; then
        echo -e "${GREEN}SSH سرویس:${NC} در حال اجرا"
    else
        echo -e "${RED}SSH سرویس:${NC} متوقف"
    fi
    
    # وضعیت پورت‌ها
    echo -e "${GREEN}پورت SSH:${NC} $SSH_PORT"
    echo -e "${GREEN}پورت تانل:${NC} $TUNNEL_PORT"
    
    # بررسی اتصالات فعال
    ACTIVE_CONNECTIONS=$(sudo netstat -tn | grep ":$SSH_PORT " | wc -l)
    echo -e "${GREEN}اتصالات فعال:${NC} $ACTIVE_CONNECTIONS"
    
    # وضعیت فایروال
    if command -v ufw &> /dev/null; then
        echo -e "${GREEN}فایروال:${NC} UFW فعال"
    elif command -v firewall-cmd &> /dev/null; then
        echo -e "${GREEN}فایروال:${NC} firewalld فعال"
    else
        echo -e "${YELLOW}فایروال:${NC} تنظیم نشده"
    fi
    
    echo -e "${BLUE}=== آخرین لاگ‌ها ===${NC}"
    tail -n 10 "$LOG_FILE" 2>/dev/null || echo "لاگ یافت نشد"
}

# تابع نمایش لاگ‌ها
show_logs() {
    echo -e "${BLUE}=== لاگ‌های سرور تانل ===${NC}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -f "$LOG_FILE"
    else
        echo "فایل لاگ یافت نشد"
    fi
}

# تابع اضافه کردن کلید عمومی
add_public_key() {
    if [[ -z "$1" ]]; then
        echo "لطفاً کلید عمومی را وارد کنید:"
        read -r PUBLIC_KEY
    else
        PUBLIC_KEY="$1"
    fi
    
    if [[ -n "$PUBLIC_KEY" ]]; then
        echo "$PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS" > /dev/null
        sudo cp "$AUTHORIZED_KEYS" /home/tunnel/.ssh/authorized_keys
        sudo chmod 600 /home/tunnel/.ssh/authorized_keys
        sudo chown tunnel:tunnel /home/tunnel/.ssh/authorized_keys
        
        log_message "کلید عمومی اضافه شد"
    else
        error_message "کلید عمومی خالی است"
    fi
}

# تابع نمایش کلیدهای مجاز
show_authorized_keys() {
    echo -e "${BLUE}=== کلیدهای مجاز ===${NC}"
    if [[ -f "$AUTHORIZED_KEYS" ]]; then
        cat "$AUTHORIZED_KEYS"
    else
        echo "فایل کلیدهای مجاز یافت نشد"
    fi
}

# تابع تست اتصال
test_connection() {
    log_message "تست اتصال محلی..."
    
    if nc -z localhost "$SSH_PORT" 2>/dev/null; then
        log_message "پورت SSH محلی در دسترس است"
        return 0
    else
        error_message "پورت SSH محلی در دسترس نیست"
        return 1
    fi
}

# تابع نمایش راهنما
show_help() {
    echo -e "${BLUE}راهنمای استفاده از اسکریپت تانل سرور${NC}"
    echo ""
    echo "استفاده: $0 [گزینه]"
    echo ""
    echo "گزینه‌ها:"
    echo "  install     نصب وابستگی‌ها و تنظیم اولیه"
    echo "  setup       تنظیم SSH سرور و کاربر"
    echo "  start       شروع سرویس SSH"
    echo "  stop        متوقف کردن سرویس SSH"
    echo "  restart     راه‌اندازی مجدد سرویس SSH"
    echo "  status      نمایش وضعیت سرور"
    echo "  logs        نمایش لاگ‌های زنده"
    echo "  addkey      اضافه کردن کلید عمومی"
    echo "  showkeys    نمایش کلیدهای مجاز"
    echo "  test        تست اتصال محلی"
    echo "  help        نمایش این راهنما"
    echo ""
    echo "مثال‌ها:"
    echo "  $0 install                    # نصب اولیه"
    echo "  $0 setup                       # تنظیم SSH"
    echo "  $0 addkey 'ssh-rsa AAAAB3...'  # اضافه کردن کلید"
    echo "  $0 start                       # شروع سرویس"
    echo "  $0 status                      # بررسی وضعیت"
}

# تابع اصلی
main() {
    case "${1:-help}" in
        "install")
            install_dependencies
            ;;
        "setup")
            check_config
            setup_ssh_server
            create_tunnel_user
            setup_firewall
            ;;
        "start")
            check_config
            start_ssh_service
            ;;
        "stop")
            stop_ssh_service
            ;;
        "restart")
            stop_ssh_service
            sleep 2
            check_config
            start_ssh_service
            ;;
        "status")
            check_config
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "addkey")
            add_public_key "$2"
            ;;
        "showkeys")
            show_authorized_keys
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
