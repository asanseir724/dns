#!/bin/bash

# اسکریپت مدیریت و مانیتورینگ تانل
# این اسکریپت برای مدیریت کلی تانل بین دو سرور طراحی شده است

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
LOG_FILE="/var/log/tunnel-manager.log"
STATUS_FILE="/tmp/tunnel-status.json"

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

info_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# تابع بررسی وضعیت سرورها
check_server_status() {
    local server_type="$1"
    local server_ip="$2"
    local server_port="$3"
    
    if nc -z "$server_ip" "$server_port" 2>/dev/null; then
        echo "online"
    else
        echo "offline"
    fi
}

# تابع نمایش وضعیت کلی تانل
show_tunnel_status() {
    echo -e "${BLUE}=== وضعیت کلی تانل ===${NC}"
    
    # خواندن تنظیمات از فایل‌های کانفیگ
    IRAN_CONFIG="/etc/tunnel/config.conf"
    FOREIGN_CONFIG="/etc/tunnel/config.conf"
    
    if [[ -f "$IRAN_CONFIG" ]]; then
        source "$IRAN_CONFIG"
        if [[ "$SERVER_TYPE" == "iran" ]]; then
            IRAN_SERVER="localhost"
            IRAN_PORT="$LOCAL_PORT"
            FOREIGN_SERVER="$REMOTE_SERVER"
            FOREIGN_PORT="$REMOTE_PORT"
        fi
    fi
    
    # بررسی وضعیت سرور ایران
    if [[ -n "$IRAN_SERVER" && -n "$IRAN_PORT" ]]; then
        IRAN_STATUS=$(check_server_status "iran" "$IRAN_SERVER" "$IRAN_PORT")
        if [[ "$IRAN_STATUS" == "online" ]]; then
            echo -e "${GREEN}سرور ایران:${NC} آنلاین"
        else
            echo -e "${RED}سرور ایران:${NC} آفلاین"
        fi
    fi
    
    # بررسی وضعیت سرور خارج
    if [[ -n "$FOREIGN_SERVER" && -n "$FOREIGN_PORT" ]]; then
        FOREIGN_STATUS=$(check_server_status "foreign" "$FOREIGN_SERVER" "$FOREIGN_PORT")
        if [[ "$FOREIGN_STATUS" == "online" ]]; then
            echo -e "${GREEN}سرور خارج:${NC} آنلاین"
        else
            echo -e "${RED}سرور خارج:${NC} آفلاین"
        fi
    fi
    
    # نمایش اتصالات فعال
    echo -e "${BLUE}=== اتصالات فعال ===${NC}"
    ACTIVE_CONNECTIONS=$(netstat -tn 2>/dev/null | grep -E ":(22|2222|8080|1080) " | wc -l)
    echo -e "${GREEN}تعداد اتصالات:${NC} $ACTIVE_CONNECTIONS"
    
    # نمایش استفاده از پهنای باند
    show_bandwidth_usage
}

# تابع نمایش استفاده از پهنای باند
show_bandwidth_usage() {
    echo -e "${BLUE}=== استفاده از پهنای باند ===${NC}"
    
    # دریافت آمار شبکه
    if command -v iftop &> /dev/null; then
        echo "استفاده از iftop برای نمایش ترافیک زنده:"
        echo "دستور: sudo iftop -i eth0"
    elif command -v nethogs &> /dev/null; then
        echo "استفاده از nethogs برای نمایش ترافیک بر اساس فرآیند:"
        echo "دستور: sudo nethogs"
    else
        echo "برای نمایش ترافیک، iftop یا nethogs را نصب کنید:"
        echo "sudo apt-get install iftop nethogs"
    fi
    
    # نمایش آمار کلی
    if [[ -f "/proc/net/dev" ]]; then
        echo -e "${GREEN}آمار کلی شبکه:${NC}"
        cat /proc/net/dev | grep -E "(eth0|ens|enp)" | head -1
    fi
}

# تابع مانیتورینگ زنده
live_monitoring() {
    echo -e "${BLUE}=== مانیتورینگ زنده تانل ===${NC}"
    echo "برای خروج از مانیتورینگ، Ctrl+C را فشار دهید"
    echo ""
    
    while true; do
        clear
        show_tunnel_status
        echo ""
        echo -e "${YELLOW}آخرین به‌روزرسانی: $(date '+%H:%M:%S')${NC}"
        sleep 5
    done
}

# تابع تست سرعت تانل
test_tunnel_speed() {
    echo -e "${BLUE}=== تست سرعت تانل ===${NC}"
    
    # بررسی وجود ابزارهای تست
    if ! command -v curl &> /dev/null; then
        error_message "curl نصب نیست - لطفاً نصب کنید"
        return 1
    fi
    
    # تست سرعت دانلود
    echo "تست سرعت دانلود..."
    DOWNLOAD_SPEED=$(curl -o /dev/null -s -w "%{speed_download}" http://speedtest.tele2.net/10MB.zip)
    DOWNLOAD_MBPS=$(echo "scale=2; $DOWNLOAD_SPEED / 1024 / 1024" | bc -l 2>/dev/null || echo "نامشخص")
    echo -e "${GREEN}سرعت دانلود:${NC} ${DOWNLOAD_MBPS} MB/s"
    
    # تست تأخیر
    echo "تست تأخیر..."
    PING_TIME=$(ping -c 3 8.8.8.8 2>/dev/null | tail -1 | awk -F'/' '{print $5}' || echo "نامشخص")
    echo -e "${GREEN}تأخیر:${NC} ${PING_TIME} ms"
}

# تابع نمایش لاگ‌های سیستم
show_system_logs() {
    echo -e "${BLUE}=== لاگ‌های سیستم ===${NC}"
    
    # لاگ‌های SSH
    echo -e "${GREEN}لاگ‌های SSH:${NC}"
    sudo tail -n 10 /var/log/auth.log 2>/dev/null | grep ssh || echo "لاگ SSH یافت نشد"
    
    echo ""
    
    # لاگ‌های تانل
    if [[ -f "/var/log/tunnel.log" ]]; then
        echo -e "${GREEN}لاگ‌های تانل:${NC}"
        tail -n 10 /var/log/tunnel.log
    fi
    
    if [[ -f "/var/log/tunnel-server.log" ]]; then
        echo -e "${GREEN}لاگ‌های سرور تانل:${NC}"
        tail -n 10 /var/log/tunnel-server.log
    fi
}

# تابع پشتیبان‌گیری تنظیمات
backup_config() {
    local backup_dir="/tmp/tunnel-backup-$(date +%Y%m%d-%H%M%S)"
    
    log_message "ایجاد پشتیبان از تنظیمات..."
    
    mkdir -p "$backup_dir"
    
    # کپی فایل‌های کانفیگ
    if [[ -f "/etc/tunnel/config.conf" ]]; then
        cp /etc/tunnel/config.conf "$backup_dir/"
    fi
    
    # کپی کلیدهای SSH
    if [[ -d "$HOME/.ssh" ]]; then
        cp -r "$HOME/.ssh" "$backup_dir/"
    fi
    
    # کپی فایل‌های سرویس
    if [[ -f "/etc/systemd/system/iran-tunnel.service" ]]; then
        cp /etc/systemd/system/iran-tunnel.service "$backup_dir/"
    fi
    
    if [[ -f "/etc/systemd/system/foreign-tunnel.service" ]]; then
        cp /etc/systemd/system/foreign-tunnel.service "$backup_dir/"
    fi
    
    # فشرده‌سازی
    tar -czf "$backup_dir.tar.gz" -C /tmp "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log_message "پشتیبان ایجاد شد: $backup_dir.tar.gz"
}

# تابع بازگردانی تنظیمات
restore_config() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        echo "فایل‌های پشتیبان موجود:"
        ls -la /tmp/tunnel-backup-*.tar.gz 2>/dev/null || echo "فایل پشتیبان یافت نشد"
        echo ""
        read -p "نام فایل پشتیبان را وارد کنید: " backup_file
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error_message "فایل پشتیبان یافت نشد: $backup_file"
        return 1
    fi
    
    log_message "بازگردانی تنظیمات از: $backup_file"
    
    # استخراج فایل پشتیبان
    tar -xzf "$backup_file" -C /tmp
    
    # بازگردانی فایل‌ها
    BACKUP_DIR="/tmp/$(basename "$backup_file" .tar.gz)"
    
    if [[ -f "$BACKUP_DIR/config.conf" ]]; then
        sudo cp "$BACKUP_DIR/config.conf" /etc/tunnel/
    fi
    
    if [[ -d "$BACKUP_DIR/.ssh" ]]; then
        cp -r "$BACKUP_DIR/.ssh" "$HOME/"
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/*"
    fi
    
    if [[ -f "$BACKUP_DIR/iran-tunnel.service" ]]; then
        sudo cp "$BACKUP_DIR/iran-tunnel.service" /etc/systemd/system/
        sudo systemctl daemon-reload
    fi
    
    if [[ -f "$BACKUP_DIR/foreign-tunnel.service" ]]; then
        sudo cp "$BACKUP_DIR/foreign-tunnel.service" /etc/systemd/system/
        sudo systemctl daemon-reload
    fi
    
    # پاکسازی
    rm -rf "$BACKUP_DIR"
    
    log_message "تنظیمات با موفقیت بازگردانده شد"
}

# تابع نمایش آمار سیستم
show_system_stats() {
    echo -e "${BLUE}=== آمار سیستم ===${NC}"
    
    # استفاده از CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "${GREEN}استفاده از CPU:${NC} ${CPU_USAGE}%"
    
    # استفاده از حافظه
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    echo -e "${GREEN}استفاده از حافظه:${NC} ${MEMORY_USAGE}%"
    
    # استفاده از دیسک
    DISK_USAGE=$(df -h / | awk 'NR==2{printf "%s", $5}')
    echo -e "${GREEN}استفاده از دیسک:${NC} ${DISK_USAGE}"
    
    # بار سیستم
    LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${GREEN}بار سیستم:${NC}${LOAD_AVERAGE}"
    
    # زمان فعالیت
    UPTIME=$(uptime -p)
    echo -e "${GREEN}زمان فعالیت:${NC} ${UPTIME}"
}

# تابع نمایش راهنما
show_help() {
    echo -e "${BLUE}راهنمای استفاده از اسکریپت مدیریت تانل${NC}"
    echo ""
    echo "استفاده: $0 [گزینه]"
    echo ""
    echo "گزینه‌ها:"
    echo "  status      نمایش وضعیت کلی تانل"
    echo "  monitor     مانیتورینگ زنده تانل"
    echo "  speed       تست سرعت تانل"
    echo "  logs        نمایش لاگ‌های سیستم"
    echo "  backup      پشتیبان‌گیری تنظیمات"
    echo "  restore     بازگردانی تنظیمات"
    echo "  stats       نمایش آمار سیستم"
    echo "  help        نمایش این راهنما"
    echo ""
    echo "مثال‌ها:"
    echo "  $0 status           # بررسی وضعیت"
    echo "  $0 monitor          # مانیتورینگ زنده"
    echo "  $0 speed            # تست سرعت"
    echo "  $0 backup           # پشتیبان‌گیری"
    echo "  $0 restore backup.tar.gz  # بازگردانی"
}

# تابع اصلی
main() {
    case "${1:-help}" in
        "status")
            show_tunnel_status
            ;;
        "monitor")
            live_monitoring
            ;;
        "speed")
            test_tunnel_speed
            ;;
        "logs")
            show_system_logs
            ;;
        "backup")
            backup_config
            ;;
        "restore")
            restore_config "$2"
            ;;
        "stats")
            show_system_stats
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# اجرای تابع اصلی
main "$@"
