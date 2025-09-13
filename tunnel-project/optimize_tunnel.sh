#!/bin/bash

# اسکریپت بهینه‌سازی تانل برای کاهش پینگ
# این اسکریپت روی هر دو سرور اجرا می‌شود

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# تنظیمات پیش‌فرض
LOG_FILE="/var/log/tunnel-optimization.log"

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

# تابع بهینه‌سازی تنظیمات شبکه
optimize_network_settings() {
    info_message "بهینه‌سازی تنظیمات شبکه..."
    
    # تنظیمات TCP برای کاهش تأخیر
    sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'

# بهینه‌سازی TCP برای تانل
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_tso_win_divisor = 3
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_fastopen_key = 00000000-00000000-00000000-00000000
EOF
    
    # اعمال تنظیمات
    sudo sysctl -p
    
    log_message "تنظیمات شبکه بهینه شد"
}

# تابع بهینه‌سازی SSH
optimize_ssh_settings() {
    info_message "بهینه‌سازی تنظیمات SSH..."
    
    # تنظیمات SSH برای کاهش تأخیر
    sudo tee -a /etc/ssh/sshd_config > /dev/null << 'EOF'

# بهینه‌سازی SSH برای تانل
TCPKeepAlive yes
ClientAliveInterval 15
ClientAliveCountMax 3
Compression no
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256,hmac-sha1
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521
HostKeyAlgorithms ssh-ed25519,ssh-rsa
PubkeyAcceptedKeyTypes ssh-ed25519,ssh-rsa
EOF
    
    # راه‌اندازی مجدد SSH
    sudo systemctl restart sshd
    
    log_message "تنظیمات SSH بهینه شد"
}

# تابع بهینه‌سازی autossh
optimize_autossh() {
    info_message "بهینه‌سازی تنظیمات autossh..."
    
    # تنظیمات autossh برای کاهش تأخیر
    sudo tee /etc/tunnel/autossh.conf > /dev/null << 'EOF'
# تنظیمات autossh بهینه شده
AUTOSSH_GATETIME=0
AUTOSSH_POLL=15
AUTOSSH_FIRST_POLL=15
AUTOSSH_LOGLEVEL=1
AUTOSSH_LOGFILE=/var/log/autossh.log
EOF
    
    log_message "تنظیمات autossh بهینه شد"
}

# تابع بهینه‌سازی DNS
optimize_dns() {
    info_message "بهینه‌سازی DNS..."
    
    # تنظیم DNS سریع
    sudo tee /etc/systemd/resolved.conf > /dev/null << 'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
FallbackDNS=9.9.9.9 149.112.112.112
DNSSEC=no
DNSOverTLS=no
Cache=yes
CacheFromLocalhost=no
EOF
    
    # راه‌اندازی مجدد systemd-resolved
    sudo systemctl restart systemd-resolved
    
    log_message "DNS بهینه شد"
}

# تابع بهینه‌سازی I/O
optimize_io() {
    info_message "بهینه‌سازی I/O..."
    
    # تنظیمات I/O برای بهبود عملکرد
    sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'

# بهینه‌سازی I/O
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.vfs_cache_pressure = 50
EOF
    
    # اعمال تنظیمات
    sudo sysctl -p
    
    log_message "تنظیمات I/O بهینه شد"
}

# تابع بهینه‌سازی CPU
optimize_cpu() {
    info_message "بهینه‌سازی CPU..."
    
    # تنظیمات CPU برای بهبود عملکرد
    sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'

# بهینه‌سازی CPU
kernel.sched_rt_runtime_us = -1
kernel.sched_rt_period_us = 1000000
kernel.sched_migration_cost_ns = 5000000
kernel.sched_nr_migrate = 32
kernel.sched_time_avg_ms = 1000
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000
EOF
    
    # اعمال تنظیمات
    sudo sysctl -p
    
    log_message "تنظیمات CPU بهینه شد"
}

# تابع بهینه‌سازی فایروال
optimize_firewall() {
    info_message "بهینه‌سازی فایروال..."
    
    # تنظیمات فایروال برای بهبود عملکرد
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian
        sudo ufw --force enable
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow 22/tcp comment "SSH"
        sudo ufw allow 2222/tcp comment "Tunnel SSH"
        sudo ufw allow 8080/tcp comment "Tunnel Local"
        sudo ufw allow 1080/tcp comment "Tunnel Port"
        sudo ufw reload
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL/Fedora
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
        sudo firewall-cmd --permanent --add-port=22/tcp
        sudo firewall-cmd --permanent --add-port=2222/tcp
        sudo firewall-cmd --permanent --add-port=8080/tcp
        sudo firewall-cmd --permanent --add-port=1080/tcp
        sudo firewall-cmd --reload
    fi
    
    log_message "فایروال بهینه شد"
}

# تابع بهینه‌سازی تانل
optimize_tunnel() {
    info_message "بهینه‌سازی تنظیمات تانل..."
    
    # تنظیمات تانل بهینه شده
    sudo tee /etc/tunnel/optimized.conf > /dev/null << 'EOF'
# تنظیمات تانل بهینه شده
TUNNEL_OPTIMIZATION="enabled"
TCP_KEEPALIVE="15"
TCP_KEEPALIVE_COUNT="3"
TCP_KEEPALIVE_INTERVAL="60"
COMPRESSION="no"
CIPHER="chacha20-poly1305@openssh.com"
MAC="hmac-sha2-256-etm@openssh.com"
KEX="curve25519-sha256@libssh.org"
EOF
    
    log_message "تنظیمات تانل بهینه شد"
}

# تابع تست عملکرد
test_performance() {
    info_message "تست عملکرد..."
    
    # تست پینگ
    echo -e "${BLUE}=== تست پینگ ===${NC}"
    ping -c 5 8.8.8.8 | tail -1
    
    # تست سرعت
    echo -e "${BLUE}=== تست سرعت ===${NC}"
    if command -v curl &> /dev/null; then
        curl -o /dev/null -s -w "سرعت دانلود: %{speed_download} bytes/sec\n" http://speedtest.tele2.net/10MB.zip
    fi
    
    # تست تأخیر
    echo -e "${BLUE}=== تست تأخیر ===${NC}"
    if command -v tcpping &> /dev/null; then
        tcpping -c 5 8.8.8.8 53
    else
        echo "برای تست تأخیر دقیق، tcpping را نصب کنید: sudo apt-get install tcpping"
    fi
}

# تابع نصب ابزارهای بهینه‌سازی
install_optimization_tools() {
    info_message "نصب ابزارهای بهینه‌سازی..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y htop iotop nethogs iftop tcpping
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y htop iotop nethogs iftop tcpping
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf install -y htop iotop nethogs iftop tcpping
    fi
    
    log_message "ابزارهای بهینه‌سازی نصب شدند"
}

# تابع نمایش راهنما
show_help() {
    echo -e "${BLUE}راهنمای استفاده از اسکریپت بهینه‌سازی تانل${NC}"
    echo ""
    echo "استفاده: $0 [گزینه]"
    echo ""
    echo "گزینه‌ها:"
    echo "  all         بهینه‌سازی کامل (پیشنهادی)"
    echo "  network     بهینه‌سازی شبکه"
    echo "  ssh         بهینه‌سازی SSH"
    echo "  dns         بهینه‌سازی DNS"
    echo "  io          بهینه‌سازی I/O"
    echo "  cpu         بهینه‌سازی CPU"
    echo "  firewall    بهینه‌سازی فایروال"
    echo "  tunnel      بهینه‌سازی تانل"
    echo "  test        تست عملکرد"
    echo "  tools       نصب ابزارهای بهینه‌سازی"
    echo "  help        نمایش این راهنما"
    echo ""
    echo "مثال‌ها:"
    echo "  $0 all              # بهینه‌سازی کامل"
    echo "  $0 network          # فقط شبکه"
    echo "  $0 test             # تست عملکرد"
    echo "  $0 tools            # نصب ابزارها"
}

# تابع اصلی
main() {
    case "${1:-help}" in
        "all")
            install_optimization_tools
            optimize_network_settings
            optimize_ssh_settings
            optimize_autossh
            optimize_dns
            optimize_io
            optimize_cpu
            optimize_firewall
            optimize_tunnel
            test_performance
            log_message "بهینه‌سازی کامل انجام شد"
            ;;
        "network")
            optimize_network_settings
            ;;
        "ssh")
            optimize_ssh_settings
            ;;
        "dns")
            optimize_dns
            ;;
        "io")
            optimize_io
            ;;
        "cpu")
            optimize_cpu
            ;;
        "firewall")
            optimize_firewall
            ;;
        "tunnel")
            optimize_tunnel
            ;;
        "test")
            test_performance
            ;;
        "tools")
            install_optimization_tools
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# اجرای تابع اصلی
main "$@"
