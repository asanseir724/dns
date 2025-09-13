#!/bin/bash
set -e

# رنگ‌ها برای خروجی بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# مسیر پوشه تنظیمات
CONFIG_DIR="$HOME/.byosh"
PROFILES_DIR="$CONFIG_DIR/profiles"

# تابع برای نمایش پیام‌های رنگی
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_profile() {
    echo -e "${PURPLE}[PROFILE]${NC} $1"
}

print_config() {
    echo -e "${CYAN}[CONFIG]${NC} $1"
}

# تابع برای بررسی وجود دستور
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "دستور $1 یافت نشد!"
        exit 1
    fi
}

# تابع برای ایجاد پوشه‌های تنظیمات
init_config_dirs() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PROFILES_DIR"
    print_config "پوشه‌های تنظیمات ایجاد شدند"
}

# تابع برای ایجاد پروفایل جدید
create_profile() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ -f "$profile_file" ]]; then
        print_warning "پروفایل '$profile_name' قبلاً وجود دارد!"
        read -p "آیا بازنویسی شود؟ (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    print_profile "ایجاد پروفایل جدید: $profile_name"
    
    # دریافت تنظیمات از کاربر
    echo ""
    print_config "تنظیمات پروفایل '$profile_name':"
    
    read -p "نام نمایشی پروفایل: " display_name
    read -p "IP عمومی سرور: " pub_ip
    read -p "پورت DNS (پیش‌فرض: 53): " dns_port
    read -p "نام کانتینر (پیش‌فرض: byosh-$profile_name): " container_name
    read -p "توضیحات: " description
    
    # تنظیم مقادیر پیش‌فرض
    dns_port=${dns_port:-53}
    container_name=${container_name:-"byosh-$profile_name"}
    
    # ذخیره پروفایل
    cat > "$profile_file" << EOF
# پروفایل ByoSH - $profile_name
# ایجاد شده در: $(date)

PROFILE_NAME="$profile_name"
DISPLAY_NAME="$display_name"
PUB_IP="$pub_ip"
DNS_PORT="$dns_port"
CONTAINER_NAME="$container_name"
DESCRIPTION="$description"
CREATED_DATE="$(date)"
EOF
    
    print_success "پروفایل '$profile_name' ایجاد شد"
    return 0
}

# تابع برای لیست پروفایل‌ها
list_profiles() {
    print_profile "پروفایل‌های موجود:"
    echo ""
    
    if [[ ! -d "$PROFILES_DIR" ]] || [[ -z "$(ls -A "$PROFILES_DIR" 2>/dev/null)" ]]; then
        print_warning "هیچ پروفایلی یافت نشد"
        return 1
    fi
    
    local count=1
    for profile_file in "$PROFILES_DIR"/*.conf; do
        if [[ -f "$profile_file" ]]; then
            local profile_name=$(basename "$profile_file" .conf)
            source "$profile_file"
            echo "$count) $profile_name"
            echo "   نام نمایشی: $DISPLAY_NAME"
            echo "   IP: $PUB_IP"
            echo "   کانتینر: $CONTAINER_NAME"
            echo "   توضیحات: $DESCRIPTION"
            echo ""
            ((count++))
        fi
    done
    return 0
}

# تابع برای انتخاب پروفایل
select_profile() {
    list_profiles
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo ""
    read -p "شماره پروفایل مورد نظر را وارد کنید: " profile_choice
    
    local count=1
    for profile_file in "$PROFILES_DIR"/*.conf; do
        if [[ -f "$profile_file" ]]; then
            if [[ "$count" == "$profile_choice" ]]; then
                local profile_name=$(basename "$profile_file" .conf)
                source "$profile_file"
                print_success "پروفایل '$profile_name' انتخاب شد"
                return 0
            fi
            ((count++))
        fi
    done
    
    print_error "پروفایل انتخاب شده یافت نشد!"
    return 1
}

# تابع برای حذف پروفایل
delete_profile() {
    list_profiles
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo ""
    read -p "شماره پروفایل برای حذف: " profile_choice
    
    local count=1
    for profile_file in "$PROFILES_DIR"/*.conf; do
        if [[ -f "$profile_file" ]]; then
            if [[ "$count" == "$profile_choice" ]]; then
                local profile_name=$(basename "$profile_file" .conf)
                read -p "آیا مطمئن هستید که می‌خواهید '$profile_name' را حذف کنید؟ (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f "$profile_file"
                    print_success "پروفایل '$profile_name' حذف شد"
                else
                    print_status "عملیات لغو شد"
                fi
                return 0
            fi
            ((count++))
        fi
    done
    
    print_error "پروفایل انتخاب شده یافت نشد!"
    return 1
}

# تابع برای نمایش منوی اصلی
show_main_menu() {
    echo ""
    echo "=================================="
    print_profile "مدیریت پروفایل‌های ByoSH"
    echo "=================================="
    echo "1) ایجاد پروفایل جدید"
    echo "2) لیست پروفایل‌ها"
    echo "3) انتخاب و اجرای پروفایل"
    echo "4) حذف پروفایل"
    echo "5) اجرای سریع (بدون پروفایل)"
    echo "6) خروج"
    echo ""
    read -p "گزینه مورد نظر را انتخاب کنید (1-6): " menu_choice
}

# تابع برای دریافت IP عمومی
get_public_ip() {
    local ip=""
    # تلاش برای دریافت IP از چندین سرویس
    for service in "ifconfig.me" "ipinfo.io/ip" "icanhazip.com" "checkip.amazonaws.com"; do
        ip=$(curl -s --connect-timeout 5 $service 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
        if [[ -n "$ip" ]]; then
            break
        fi
    done
    
    if [[ -z "$ip" ]]; then
        print_warning "نمی‌توان IP عمومی را دریافت کرد. لطفاً دستی وارد کنید:"
        read -p "IP عمومی سرور: " ip
    fi
    
    echo "$ip"
}

# تابع اصلی نصب ByoSH
install_byosh() {
    local profile_mode="$1"
    
    if [[ "$profile_mode" == "profile" ]]; then
        print_profile "اجرای نصب با پروفایل: $DISPLAY_NAME"
        print_config "IP: $PUB_IP | کانتینر: $CONTAINER_NAME"
    else
        print_status "اجرای نصب سریع (بدون پروفایل)"
        # تنظیم مقادیر پیش‌فرض برای حالت سریع
        DISPLAY_NAME="نصب سریع"
        PUBIP=$(get_public_ip)
        CONTAINER_NAME="byosh-quick"
        DNS_PORT="53"
    fi
    
    echo ""
    echo "🚀 شروع نصب ByoSH از سورس ..."
    echo "=================================="

    # بررسی دسترسی root
    if [[ $EUID -eq 0 ]]; then
        print_warning "این اسکریپت نباید با دسترسی root اجرا شود!"
        print_status "لطفاً بدون sudo اجرا کنید"
        exit 1
    fi

    # بررسی سیستم عامل
    if ! grep -q "Ubuntu\|Debian" /etc/os-release 2>/dev/null; then
        print_warning "این اسکریپت برای Ubuntu/Debian طراحی شده است"
        read -p "آیا ادامه دهید؟ (y/N): " continue_install
        if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # [1/7] به‌روزرسانی پکیج‌ها
    print_status "[1/7] به‌روزرسانی پکیج‌ها..."
    sudo apt update -y
    sudo apt upgrade -y
    print_success "پکیج‌ها به‌روزرسانی شدند"

    # [2/7] نصب وابستگی‌ها
    print_status "[2/7] نصب وابستگی‌ها (Python3, pip, Docker, Git, Curl, net-tools)..."
    sudo apt install -y python3 python3-pip curl git docker.io net-tools

    # بررسی نصب موفق وابستگی‌ها
    check_command python3
    check_command pip3
    check_command git
    check_command curl
    
    # بررسی Docker (اختیاری در macOS)
    if ! command -v docker &> /dev/null; then
        print_warning "Docker یافت نشد! لطفاً Docker را نصب کنید"
        print_status "در macOS: brew install docker"
        print_status "در Ubuntu/Debian: sudo apt install docker.io"
        exit 1
    fi
    
    # بررسی netstat (اختیاری در macOS)
    if ! command -v netstat &> /dev/null; then
        print_warning "netstat یافت نشد! نصب net-tools..."
        if command -v brew &> /dev/null; then
            brew install net-tools 2>/dev/null || print_warning "نصب net-tools ناموفق بود"
        fi
    fi

    # فعال‌سازی و شروع داکر
    print_status "فعال‌سازی و شروع سرویس Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # بررسی وضعیت Docker
    if ! sudo systemctl is-active --quiet docker; then
        print_error "Docker شروع نشد!"
        exit 1
    fi
    print_success "Docker فعال و در حال اجرا است"

    # اضافه کردن کاربر به گروه docker
    sudo usermod -aG docker $USER
    print_success "کاربر به گروه docker اضافه شد"

    # [3/7] دریافت سورس ByoSH
    print_status "[3/7] دریافت سورس ByoSH..."
    if [ ! -d "byosh" ]; then
        git clone https://github.com/mosajjal/byosh
        print_success "سورس ByoSH دریافت شد"
    else
        print_status "پوشه byosh موجود است. به‌روزرسانی..."
        cd byosh
        git pull
        cd ..
    fi

    cd byosh

    # بررسی وجود فایل‌های ضروری
    if [[ ! -f "Dockerfile" ]]; then
        print_error "فایل Dockerfile یافت نشد!"
        exit 1
    fi

    # [4/7] غیرفعال کردن systemd-resolved
    print_status "[4/7] غیرفعال کردن systemd-resolved برای آزاد کردن پورت 53..."

    # پشتیبان‌گیری از تنظیمات DNS
    backup_dns_config

    # بررسی وضعیت systemd-resolved
    if systemctl is-active --quiet systemd-resolved; then
        print_status "متوقف کردن systemd-resolved..."
        sudo systemctl stop systemd-resolved || true
        sudo systemctl disable systemd-resolved || true
        print_success "systemd-resolved غیرفعال شد"
    fi

    # تنظیم DNS موقت
    print_status "تنظیم DNS موقت..."
    sudo rm -f /etc/resolv.conf
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
    echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
    print_success "DNS موقت تنظیم شد"

    # بررسی آزاد بودن پورت 53
    if ! check_port_53; then
        print_warning "پورت 53 هنوز در حال استفاده است"
        print_status "تلاش برای شناسایی فرآیند استفاده‌کننده..."
        sudo netstat -tulnp | grep ":53 " || true
    fi

    # [5/7] اصلاح Dockerfile برای نصب dnslib
    print_status "[5/7] اصلاح Dockerfile..."
    if grep -q "pip3 install --no-cache-dir dnslib" Dockerfile; then
        sed -i 's|pip3 install --no-cache-dir dnslib|pip3 install --no-cache-dir --break-system-packages dnslib|' Dockerfile
        print_success "Dockerfile اصلاح شد"
    else
        print_warning "خط نصب dnslib در Dockerfile یافت نشد"
    fi

    # [6/7] ساخت ایمیج
    print_status "[6/7] ساخت ایمیج سفارشی ByoSH..."
    sudo docker build . -t byosh:myown
    print_success "ایمیج ByoSH ساخته شد"

    # [7/7] اجرای کانتینر
    print_status "[7/7] اجرای کانتینر ByoSH..."
    
    if [[ "$profile_mode" == "profile" ]]; then
        PUBIP="$PUB_IP"
    fi
    
    if [[ -z "$PUBIP" ]]; then
        print_error "IP عمومی دریافت نشد!"
        exit 1
    fi

    print_success "IP عمومی: $PUBIP"

    # حذف کانتینر قبلی در صورت وجود
    print_status "حذف کانتینر قبلی (در صورت وجود)..."
    sudo docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

    # اجرای کانتینر
    print_status "اجرای کانتینر ByoSH..."
    sudo docker run -d --name "$CONTAINER_NAME" --restart=always \
      --net=host -e PUB_IP="$PUBIP" \
      byosh:myown

    # بررسی وضعیت کانتینر
    sleep 3
    if sudo docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_success "کانتینر ByoSH با موفقیت اجرا شد"
    else
        print_error "کانتینر اجرا نشد!"
        print_status "لاگ کانتینر:"
        sudo docker logs "$CONTAINER_NAME" 2>/dev/null || true
        exit 1
    fi

    # نمایش وضعیت نهایی
    echo ""
    echo "=================================="
    print_success "✅ نصب و اجرای ByoSH کامل شد!"
    echo "=================================="
    echo "📌 DNS Server روی پورت $DNS_PORT اجرا شده است"
    echo "📌 آدرس سرور: $PUBIP"
    echo "📌 نام کانتینر: $CONTAINER_NAME"
    echo "📌 پروفایل: $DISPLAY_NAME"
    echo ""

    print_status "وضعیت کانتینر:"
    sudo docker ps --filter "name=$CONTAINER_NAME"

    echo ""
    print_status "دستورات مفید:"
    echo "• مشاهده لاگ: sudo docker logs $CONTAINER_NAME"
    echo "• متوقف کردن: sudo docker stop $CONTAINER_NAME"
    echo "• شروع مجدد: sudo docker start $CONTAINER_NAME"
    echo "• حذف کانتینر: sudo docker rm -f $CONTAINER_NAME"
    echo "• مشاهده وضعیت: sudo docker ps"

    echo ""
    print_warning "نکته: برای استفاده از Docker بدون sudo، لطفاً از سیستم خارج شده و مجدداً وارد شوید"
}

# تابع برای بررسی پورت 53
check_port_53() {
    if netstat -tuln | grep -q ":53 "; then
        print_warning "پورت 53 در حال استفاده است!"
        print_status "تلاش برای آزاد کردن پورت..."
        return 1
    fi
    return 0
}

# تابع برای پشتیبان‌گیری از تنظیمات DNS
backup_dns_config() {
    if [[ -f /etc/resolv.conf ]]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        print_success "پشتیبان از /etc/resolv.conf ایجاد شد"
    fi
}

# تابع برای بازگردانی تنظیمات DNS در صورت خطا
restore_dns_config() {
    local backup_file=$(ls -t /etc/resolv.conf.backup.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]]; then
        sudo cp "$backup_file" /etc/resolv.conf
        print_success "تنظیمات DNS بازگردانده شد"
    fi
}

# تابع cleanup در صورت خطا
cleanup_on_error() {
    print_error "خطا در نصب! انجام عملیات پاکسازی..."
    
    # متوقف کردن کانتینر در صورت وجود
    if docker ps -a --format "table {{.Names}}" | grep -q "test-dns"; then
        sudo docker rm -f test-dns 2>/dev/null || true
    fi
    
    # بازگردانی تنظیمات DNS
    restore_dns_config
    
    print_error "نصب ناموفق بود. لطفاً خطاها را بررسی کنید."
    exit 1
}

# تنظیم trap برای مدیریت خطاها
trap cleanup_on_error ERR

# بررسی آرگومان‌های خط فرمان
if [[ "$1" == "--quick" ]]; then
    # اجرای سریع بدون منو
    init_config_dirs
    install_byosh "quick"
    exit 0
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "استفاده از اسکریپت نصب ByoSH:"
    echo ""
    echo "  ./install_byosh.sh           - اجرای منوی اصلی"
    echo "  ./install_byosh.sh --quick   - اجرای سریع بدون پروفایل"
    echo "  ./install_byosh.sh --help    - نمایش این راهنما"
    echo ""
    echo "ویژگی‌ها:"
    echo "  • مدیریت چندین پروفایل DNS"
    echo "  • ذخیره تنظیمات برای استفاده مجدد"
    echo "  • رابط کاربری رنگی و دوستانه"
    echo "  • مدیریت خودکار خطاها"
    exit 0
fi

# اجرای منوی اصلی
init_config_dirs

while true; do
    show_main_menu
    
    case $menu_choice in
        1)
            echo ""
            read -p "نام پروفایل جدید: " new_profile_name
            if [[ -n "$new_profile_name" ]]; then
                create_profile "$new_profile_name"
                if [[ $? -eq 0 ]]; then
                    read -p "آیا می‌خواهید این پروفایل را اجرا کنید؟ (y/N): " run_now
                    if [[ "$run_now" =~ ^[Yy]$ ]]; then
                        install_byosh "profile"
                        break
                    fi
                fi
            else
                print_error "نام پروفایل نمی‌تواند خالی باشد!"
            fi
            ;;
        2)
            list_profiles
            ;;
        3)
            if select_profile; then
                install_byosh "profile"
                break
            fi
            ;;
        4)
            delete_profile
            ;;
        5)
            install_byosh "quick"
            break
            ;;
        6)
            print_status "خروج از برنامه..."
            exit 0
            ;;
        *)
            print_error "گزینه نامعتبر! لطفاً عددی بین 1 تا 6 وارد کنید."
            ;;
    esac
    
    echo ""
    read -p "برای ادامه Enter را فشار دهید..."
done
