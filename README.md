# 🌐 سیستم مدیریت DNS و تانل خودکار

<div align="center">

![DNS Tunnel](https://img.shields.io/badge/DNS-Tunnel-blue?style=for-the-badge&logo=cloudflare)
![Security](https://img.shields.io/badge/Security-High-green?style=for-the-badge&logo=shield)
![Auto Install](https://img.shields.io/badge/Install-Auto-orange?style=for-the-badge&logo=terminal)

**مجموعه‌ای کامل از اسکریپت‌های خودکار برای مدیریت DNS و ایجاد تانل امن بین سرورهای ایران و خارج**

[![GitHub](https://img.shields.io/github/stars/asanseir724/dns?style=social)](https://github.com/asanseir724/dns)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

---

## 🎯 معرفی پروژه

این مخزن شامل دو پروژه اصلی است:

### 🔧 **DNS Project** - مدیریت پروفایل‌های ByoSH
سیستم مدیریت چندین پروفایل DNS با استفاده از ByoSH برای سرورهای مختلف

### 🌉 **Tunnel Project** - تانل خودکار بین سرورها  
سیستم ایجاد تانل امن بین سرور ایران و سرور خارج از ایران

---

## 🚀 نصب سریع

### 🎯 **نصب کاملاً خودکار (توصیه می‌شود):**
```bash
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install_auto.sh | bash
```
**✨ این دستور همه چیز را با یک بار اجرا نصب می‌کند!**

### 🔧 **نصب مرحله‌ای:**

#### نصب DNS Project:
```bash
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/dns-project/install_byosh.sh | bash
```

#### نصب Tunnel Project:
```bash
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/tunnel-project/install_tunnel.sh | bash
```

#### نصب کامل (هر دو پروژه):
```bash
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install.sh | bash
```

---

## 📁 ساختار پروژه

```
dns/
├── 📁 dns-project/           # پروژه مدیریت DNS
│   ├── install_byosh.sh      # نصب خودکار ByoSH
│   ├── manage_byosh.sh       # مدیریت پروفایل‌ها
│   ├── test_profile.conf     # فایل تست پروفایل
│   └── README.md            # راهنمای DNS
│
├── 📁 tunnel-project/        # پروژه تانل
│   ├── install_tunnel.sh     # نصب خودکار تانل
│   ├── setup_tunnel.sh       # تنظیم اولیه
│   ├── tunnel_client.sh      # کلاینت (سرور ایران)
│   ├── tunnel_server.sh      # سرور (سرور خارج)
│   ├── tunnel_manager.sh     # مدیریت و مانیتورینگ
│   ├── optimize_tunnel.sh    # بهینه‌سازی پینگ
│   └── TUNNEL_README.md     # راهنمای تانل
│
├── install.sh               # نصب کامل هر دو پروژه
├── tunnel_manager.sh        # مدیریت تانل اصلی
├── GITHUB_SETUP.md         # راهنمای تنظیم GitHub
└── README.md               # این فایل
```

---

## ✨ ویژگی‌های کلیدی

### 🔧 **DNS Project Features**
- 🎯 **مدیریت چندین پروفایل** - ایجاد و مدیریت پروفایل‌های مختلف DNS
- 🎨 **رابط کاربری دوستانه** - منوی رنگی و تعاملی
- 🐳 **مدیریت کانتینرها** - شروع، متوقف کردن و راه‌اندازی مجدد
- 💾 **پشتیبان‌گیری خودکار** - ذخیره و بازگردانی تنظیمات DNS

### 🌉 **Tunnel Project Features**
- 🚀 **نصب خودکار** - نصب وابستگی‌ها و تنظیم فایروال
- 🔒 **امنیت بالا** - استفاده از کلیدهای SSH و غیرفعال کردن رمز عبور
- 📊 **مانیتورینگ پیشرفته** - نمایش وضعیت زنده و تست سرعت
- 🔧 **مدیریت آسان** - دستورات ساده و رابط کاربری رنگی

### 🛡️ **امنیت مشترک**
- 🔐 **کلیدهای قوی SSH** - حداقل 4096 بیت RSA یا ED25519
- 🛡️ **فایروال هوشمند** - باز کردن فقط پورت‌های ضروری
- 📝 **لاگ‌گیری جامع** - نظارت بر تمام فعالیت‌ها
- 🔄 **به‌روزرسانی خودکار** - نگهداری سیستم‌ها به‌روز

---

## ⚡ نصب کاملاً خودکار

### 🎯 **یک دستور، همه چیز!**

```bash
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/install_auto.sh | bash
```

### ✨ **چه کاری انجام می‌دهد:**
- ✅ نصب تمام وابستگی‌های سیستم
- ✅ دانلود و نصب DNS Project
- ✅ دانلود و نصب Tunnel Project  
- ✅ تنظیم خودکار پروفایل‌ها
- ✅ ایجاد اسکریپت‌های مدیریت
- ✅ راه‌اندازی خودکار سرویس‌ها
- ✅ **بدون خطا و کاملاً خودکار**

### 🚀 **بعد از نصب:**
```bash
# بررسی وضعیت DNS
byosh status

# شروع DNS
byosh start

# بررسی وضعیت Tunnel
tunnel status

# شروع Tunnel
tunnel start
```

---

## 🛠️ راهنمای استفاده

### 🔧 **DNS Project - مدیریت ByoSH**

#### نصب و راه‌اندازی:
```bash
# نصب خودکار
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/dns-project/install_byosh.sh | bash

# یا دانلود و نصب محلی
wget -O install_byosh.sh https://raw.githubusercontent.com/asanseir724/dns/main/dns-project/install_byosh.sh
chmod +x install_byosh.sh
./install_byosh.sh
```

#### مدیریت پروفایل‌ها:
```bash
# لیست تمام پروفایل‌ها
./manage_byosh.sh list

# ایجاد پروفایل جدید
./install_byosh.sh

# شروع کانتینر با پروفایل
./manage_byosh.sh start profile_name

# متوقف کردن کانتینر
./manage_byosh.sh stop profile_name

# نمایش وضعیت
./manage_byosh.sh status

# نمایش لاگ‌ها
./manage_byosh.sh logs profile_name
```

### 🌉 **Tunnel Project - تانل خودکار**

#### نصب و راه‌اندازی:
```bash
# نصب خودکار
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/tunnel-project/install_tunnel.sh | bash

# یا دانلود و نصب محلی
wget -O install_tunnel.sh https://raw.githubusercontent.com/asanseir724/dns/main/tunnel-project/install_tunnel.sh
chmod +x install_tunnel.sh
./install_tunnel.sh
```

#### تنظیم اولیه:
```bash
# تنظیم اولیه (روی هر دو سرور)
tunnel setup

# انتخاب نوع سرور:
# 1) سرور ایران (کلاینت)
# 2) سرور خارج (سرور)
```

#### مدیریت تانل:
```bash
# شروع تانل
tunnel start

# متوقف کردن تانل
tunnel stop

# بررسی وضعیت
tunnel status

# مانیتورینگ زنده
tunnel monitor

# بهینه‌سازی پینگ
tunnel optimize

# به‌روزرسانی
tunnel update
```

---

## ⚙️ تنظیمات سرورها

### 🌉 **Tunnel Project - تنظیمات**

#### سرور ایران (کلاینت):
```bash
# اطلاعات مورد نیاز:
# - آدرس IP سرور خارج: 1.2.3.4
# - پورت SSH سرور خارج: 2222
# - نام کاربری سرور خارج: tunnel
# - پورت محلی برای تانل: 8080
# - پورت تانل روی سرور خارج: 1080
```

#### سرور خارج (سرور):
```bash
# اطلاعات مورد نیاز:
# - پورت SSH برای تانل: 2222
# - پورت تانل: 1080
# - کلید عمومی SSH از سرور ایران
```

### 🔧 **DNS Project - تنظیمات**

#### پروفایل ByoSH:
```bash
# ساختار پروفایل در ~/.byosh/profiles/
PROFILE_NAME="main_server"
DISPLAY_NAME="سرور اصلی"
PUB_IP="192.168.1.100"
DNS_PORT="53"
CONTAINER_NAME="byosh-main_server"
DESCRIPTION="سرور DNS اصلی برای شبکه داخلی"
```

---

## 📊 مثال‌های کاربردی

### 🌉 **Tunnel Project - راه‌اندازی کامل**

#### مرحله 1: تنظیم سرور خارج
```bash
# روی سرور خارج
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/tunnel-project/install_tunnel.sh | bash
tunnel setup
# انتخاب گزینه 2 (سرور خارج)
# پورت SSH: 2222
# پورت تانل: 1080

# اضافه کردن کلید عمومی از سرور ایران
tunnel addkey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."

# شروع سرویس SSH
tunnel start
```

#### مرحله 2: تنظیم سرور ایران
```bash
# روی سرور ایران
curl -sSL https://raw.githubusercontent.com/asanseir724/dns/main/tunnel-project/install_tunnel.sh | bash
tunnel setup
# انتخاب گزینه 1 (سرور ایران)
# آدرس سرور خارج: 1.2.3.4
# پورت SSH: 2222
# نام کاربری: tunnel
# پورت محلی: 8080

# تنظیم کلید SSH
tunnel setup

# شروع تانل
tunnel start
```

### 🔧 **DNS Project - مدیریت چندین سرور**

#### ایجاد پروفایل‌های مختلف:
```bash
# سرور اصلی
./install_byosh.sh
# انتخاب گزینه 1 (ایجاد پروفایل جدید)
# نام: main_server
# IP: 192.168.1.100

# سرور پشتیبان
./install_byosh.sh
# انتخاب گزینه 1 (ایجاد پروفایل جدید)
# نام: backup_server
# IP: 192.168.1.101

# سرور تست
./install_byosh.sh
# انتخاب گزینه 1 (ایجاد پروفایل جدید)
# نام: test_server
# IP: 192.168.1.102
```

#### تغییر بین پروفایل‌ها:
```bash
# متوقف کردن سرور فعلی
./manage_byosh.sh stop main_server

# شروع سرور پشتیبان
./manage_byosh.sh start backup_server

# بررسی وضعیت تمام کانتینرها
./manage_byosh.sh status
```

---

## 🔧 دستورات مدیریت

### 🌉 **Tunnel Project Commands**
```bash
# مدیریت اصلی تانل
tunnel start      # شروع تانل
tunnel stop       # متوقف کردن تانل
tunnel status     # وضعیت تانل
tunnel monitor    # مانیتورینگ زنده
tunnel optimize   # بهینه‌سازی پینگ
tunnel update     # به‌روزرسانی

# مدیریت پیشرفته
tunnel-manager speed    # تست سرعت
tunnel-manager logs     # نمایش لاگ‌ها
tunnel-manager backup   # پشتیبان‌گیری
tunnel restart          # راه‌اندازی مجدد
```

### 🔧 **DNS Project Commands**
```bash
# مدیریت پروفایل‌ها
./manage_byosh.sh list              # لیست پروفایل‌ها
./manage_byosh.sh show profile_name # نمایش جزئیات
./manage_byosh.sh start profile_name # شروع کانتینر
./manage_byosh.sh stop profile_name  # متوقف کردن کانتینر
./manage_byosh.sh restart profile_name # راه‌اندازی مجدد

# مانیتورینگ
./manage_byosh.sh status            # وضعیت تمام کانتینرها
./manage_byosh.sh logs profile_name # نمایش لاگ‌ها
./manage_byosh.sh clean             # پاکسازی کانتینرهای متوقف
```

---

## 🛡️ امنیت

### 🔐 **نکات امنیتی مشترک**

1. **استفاده از کلیدهای قوی**
   - حداقل 4096 بیت برای کلید RSA
   - استفاده از کلیدهای ED25519 (توصیه می‌شود)
   - عدم استفاده از رمز عبور برای SSH

2. **تنظیم فایروال**
   - باز کردن فقط پورت‌های ضروری
   - محدود کردن دسترسی به IP های خاص
   - استفاده از fail2ban برای محافظت از حملات

3. **مانیتورینگ و لاگ‌گیری**
   - بررسی منظم لاگ‌ها
   - نظارت بر اتصالات غیرعادی
   - تنظیم هشدار برای فعالیت‌های مشکوک

4. **به‌روزرسانی منظم**
   - به‌روزرسانی سیستم عامل
   - به‌روزرسانی کلیدهای SSH
   - به‌روزرسانی اسکریپت‌ها

### 🔒 **امنیت Tunnel Project**
- غیرفعال کردن ورود با رمز عبور SSH
- استفاده از پورت‌های غیراستاندارد
- رمزگذاری تمام ترافیک تانل

### 🛡️ **امنیت DNS Project**
- محدود کردن دسترسی به کانتینرها
- پشتیبان‌گیری منظم تنظیمات DNS
- نظارت بر تغییرات پیکربندی

---

## 📈 بهینه‌سازی

### 🌉 **Tunnel Project - بهینه‌سازی پینگ**
```bash
# بهینه‌سازی کامل
tunnel optimize

# یا مرحله به مرحله
tunnel-optimize network    # بهینه‌سازی شبکه
tunnel-optimize ssh        # بهینه‌سازی SSH
tunnel-optimize dns        # بهینه‌سازی DNS
tunnel-optimize test       # تست عملکرد
```

### 🔧 **DNS Project - بهینه‌سازی عملکرد**
```bash
# پاکسازی کانتینرهای متوقف
./manage_byosh.sh clean

# بررسی وضعیت منابع سیستم
./manage_byosh.sh status

# بهینه‌سازی حافظه Docker
docker system prune -f
```

---

## 🆘 عیب‌یابی

### 🌉 **Tunnel Project - مشکلات رایج**

#### 1. اتصال برقرار نمی‌شود
```bash
# بررسی پورت‌ها
netstat -tulnp | grep :2222

# تست اتصال
nc -z server_ip 2222

# بررسی فایروال
sudo ufw status
```

#### 2. خطای دسترسی SSH
```bash
# بررسی مجوزهای کلید
chmod 600 ~/.ssh/tunnel_key
chmod 700 ~/.ssh

# تست اتصال SSH
ssh -i ~/.ssh/tunnel_key tunnel@server_ip -p 2222

# بررسی لاگ‌های SSH
sudo tail -f /var/log/auth.log | grep ssh
```

#### 3. تانل قطع می‌شود
```bash
# بررسی لاگ‌ها
tail -f /var/log/tunnel.log

# راه‌اندازی مجدد
tunnel restart

# بررسی وضعیت سرویس
systemctl status iran-tunnel
```

### 🔧 **DNS Project - مشکلات رایج**

#### 1. خطای دسترسی Docker
```bash
# اضافه کردن کاربر به گروه docker
sudo usermod -aG docker $USER
# logout و login مجدد
```

#### 2. پورت 53 در حال استفاده
```bash
# بررسی فرآیندهای استفاده‌کننده
sudo netstat -tulnp | grep ":53 "

# متوقف کردن systemd-resolved
sudo systemctl stop systemd-resolved
```

#### 3. کانتینر اجرا نمی‌شود
```bash
# بررسی لاگ کانتینر
docker logs container_name

# بررسی وضعیت کانتینر
docker ps -a

# راه‌اندازی مجدد کانتینر
./manage_byosh.sh restart profile_name
```

## 📞 پشتیبانی

برای گزارش مشکلات یا پیشنهادات:

1. نسخه سیستم عامل
2. نسخه اسکریپت‌ها
3. لاگ‌های خطا
4. تنظیمات کانفیگ

---

**نکته**: این اسکریپت‌ها برای استفاده در محیط‌های تولید طراحی شده‌اند و شامل تمام بررسی‌های امنیتی و مدیریت خطاهای لازم هستند.
