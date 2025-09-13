#!/bin/bash

# اسکریپت مدیریت پروفایل‌های ByoSH
# این اسکریپت برای مدیریت آسان پروفایل‌ها طراحی شده است

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# مسیر پوشه تنظیمات
CONFIG_DIR="$HOME/.byosh"
PROFILES_DIR="$CONFIG_DIR/profiles"

# توابع نمایش
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_profile() { echo -e "${PURPLE}[PROFILE]${NC} $1"; }

# تابع نمایش راهنما
show_help() {
    echo "مدیریت پروفایل‌های ByoSH"
    echo "=========================="
    echo ""
    echo "استفاده:"
    echo "  $0 list                    - لیست تمام پروفایل‌ها"
    echo "  $0 show <profile_name>     - نمایش جزئیات پروفایل"
    echo "  $0 start <profile_name>    - شروع کانتینر با پروفایل"
    echo "  $0 stop <profile_name>     - متوقف کردن کانتینر"
    echo "  $0 restart <profile_name>  - راه‌اندازی مجدد کانتینر"
    echo "  $0 logs <profile_name>     - نمایش لاگ کانتینر"
    echo "  $0 status                  - وضعیت تمام کانتینرها"
    echo "  $0 clean                   - پاکسازی کانتینرهای متوقف"
    echo ""
}

# تابع لیست پروفایل‌ها
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
            
            # بررسی وضعیت کانتینر
            local container_status="متوقف"
            if command -v docker &> /dev/null; then
                if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
                    container_status="در حال اجرا"
                elif docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
                    container_status="متوقف شده"
                else
                    container_status="وجود ندارد"
                fi
            else
                container_status="Docker نصب نشده"
            fi
            
            echo "$count) $profile_name"
            echo "   نام نمایشی: $DISPLAY_NAME"
            echo "   IP: $PUB_IP"
            echo "   کانتینر: $CONTAINER_NAME"
            echo "   وضعیت: $container_status"
            echo "   توضیحات: $DESCRIPTION"
            echo ""
            ((count++))
        fi
    done
    return 0
}

# تابع نمایش جزئیات پروفایل
show_profile() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "پروفایل '$profile_name' یافت نشد!"
        return 1
    fi
    
    source "$profile_file"
    
    print_profile "جزئیات پروفایل: $profile_name"
    echo "=================================="
    echo "نام نمایشی: $DISPLAY_NAME"
    echo "IP عمومی: $PUB_IP"
    echo "پورت DNS: $DNS_PORT"
    echo "نام کانتینر: $CONTAINER_NAME"
    echo "توضیحات: $DESCRIPTION"
    echo "تاریخ ایجاد: $CREATED_DATE"
    echo ""
    
    # بررسی وضعیت کانتینر
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_success "کانتینر در حال اجرا است"
            echo "آدرس DNS: $PUB_IP:$DNS_PORT"
        elif docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_warning "کانتینر متوقف شده است"
        else
            print_error "کانتینر وجود ندارد"
        fi
    else
        print_error "Docker نصب نشده است"
    fi
}

# تابع شروع کانتینر
start_container() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "پروفایل '$profile_name' یافت نشد!"
        return 1
    fi
    
    source "$profile_file"
    
    # بررسی وجود Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker نصب نشده است!"
        return 1
    fi
    
    # بررسی وجود کانتینر
    if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_warning "کانتینر '$CONTAINER_NAME' در حال اجرا است!"
        return 0
    fi
    
    print_status "شروع کانتینر '$CONTAINER_NAME'..."
    
    # حذف کانتینر متوقف شده در صورت وجود
    if docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    fi
    
    # اجرای کانتینر
    docker run -d --name "$CONTAINER_NAME" --restart=always \
      --net=host -e PUB_IP="$PUB_IP" \
      byosh:myown
    
    sleep 2
    
    if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_success "کانتینر '$CONTAINER_NAME' با موفقیت شروع شد"
        echo "آدرس DNS: $PUB_IP:$DNS_PORT"
    else
        print_error "خطا در شروع کانتینر!"
        docker logs "$CONTAINER_NAME" 2>/dev/null || true
        return 1
    fi
}

# تابع متوقف کردن کانتینر
stop_container() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "پروفایل '$profile_name' یافت نشد!"
        return 1
    fi
    
    source "$profile_file"
    
    # بررسی وجود Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker نصب نشده است!"
        return 1
    fi
    
    if ! docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_warning "کانتینر '$CONTAINER_NAME' در حال اجرا نیست!"
        return 0
    fi
    
    print_status "متوقف کردن کانتینر '$CONTAINER_NAME'..."
    docker stop "$CONTAINER_NAME"
    
    if ! docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_success "کانتینر '$CONTAINER_NAME' متوقف شد"
    else
        print_error "خطا در متوقف کردن کانتینر!"
        return 1
    fi
}

# تابع راه‌اندازی مجدد کانتینر
restart_container() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "پروفایل '$profile_name' یافت نشد!"
        return 1
    fi
    
    source "$profile_file"
    
    # بررسی وجود Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker نصب نشده است!"
        return 1
    fi
    
    print_status "راه‌اندازی مجدد کانتینر '$CONTAINER_NAME'..."
    
    if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        docker restart "$CONTAINER_NAME"
    else
        start_container "$profile_name"
        return $?
    fi
    
    sleep 2
    
    if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_success "کانتینر '$CONTAINER_NAME' با موفقیت راه‌اندازی مجدد شد"
    else
        print_error "خطا در راه‌اندازی مجدد کانتینر!"
        return 1
    fi
}

# تابع نمایش لاگ
show_logs() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "پروفایل '$profile_name' یافت نشد!"
        return 1
    fi
    
    source "$profile_file"
    
    # بررسی وجود Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker نصب نشده است!"
        return 1
    fi
    
    if ! docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_error "کانتینر '$CONTAINER_NAME' وجود ندارد!"
        return 1
    fi
    
    print_status "لاگ کانتینر '$CONTAINER_NAME':"
    echo "=================================="
    docker logs "$CONTAINER_NAME"
}

# تابع نمایش وضعیت
show_status() {
    print_status "وضعیت تمام کانتینرهای ByoSH:"
    echo "=================================="
    
    # بررسی وجود Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker نصب نشده است!"
        return 1
    fi
    
    # کانتینرهای در حال اجرا
    local running_containers=$(docker ps --filter "name=byosh-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
    if [[ -n "$running_containers" ]]; then
        echo "کانتینرهای در حال اجرا:"
        echo "$running_containers"
        echo ""
    fi
    
    # کانتینرهای متوقف شده
    local stopped_containers=$(docker ps -a --filter "name=byosh-" --filter "status=exited" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null)
    if [[ -n "$stopped_containers" ]]; then
        echo "کانتینرهای متوقف شده:"
        echo "$stopped_containers"
        echo ""
    fi
    
    # آمار کلی
    local total_containers=$(docker ps -a --filter "name=byosh-" --format "{{.Names}}" 2>/dev/null | wc -l)
    local running_count=$(docker ps --filter "name=byosh-" --format "{{.Names}}" 2>/dev/null | wc -l)
    local stopped_count=$((total_containers - running_count))
    
    echo "آمار کلی:"
    echo "  کل کانتینرها: $total_containers"
    echo "  در حال اجرا: $running_count"
    echo "  متوقف شده: $stopped_count"
}

# تابع پاکسازی
clean_containers() {
    print_status "پاکسازی کانتینرهای متوقف شده..."
    
    # بررسی وجود Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker نصب نشده است!"
        return 1
    fi
    
    local stopped_containers=$(docker ps -a --filter "name=byosh-" --filter "status=exited" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$stopped_containers" ]]; then
        print_warning "هیچ کانتینر متوقفی یافت نشد"
        return 0
    fi
    
    echo "کانتینرهای متوقف شده:"
    echo "$stopped_containers"
    echo ""
    
    read -p "آیا می‌خواهید این کانتینرها را حذف کنید؟ (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$stopped_containers" | xargs docker rm -f
        print_success "کانتینرهای متوقف شده حذف شدند"
    else
        print_status "عملیات لغو شد"
    fi
}

# بررسی آرگومان‌ها
case "$1" in
    "list")
        list_profiles
        ;;
    "show")
        if [[ -z "$2" ]]; then
            print_error "نام پروفایل را وارد کنید!"
            show_help
            exit 1
        fi
        show_profile "$2"
        ;;
    "start")
        if [[ -z "$2" ]]; then
            print_error "نام پروفایل را وارد کنید!"
            show_help
            exit 1
        fi
        start_container "$2"
        ;;
    "stop")
        if [[ -z "$2" ]]; then
            print_error "نام پروفایل را وارد کنید!"
            show_help
            exit 1
        fi
        stop_container "$2"
        ;;
    "restart")
        if [[ -z "$2" ]]; then
            print_error "نام پروفایل را وارد کنید!"
            show_help
            exit 1
        fi
        restart_container "$2"
        ;;
    "logs")
        if [[ -z "$2" ]]; then
            print_error "نام پروفایل را وارد کنید!"
            show_help
            exit 1
        fi
        show_logs "$2"
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean_containers
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        print_error "دستور نامعتبر: $1"
        show_help
        exit 1
        ;;
esac
