# سیستم تانل خودکار بین سرور ایران و خارج

این مجموعه اسکریپت‌ها برای ایجاد تانل امن بین سرور ایران و سرور خارج از ایران طراحی شده است.

## فایل‌های موجود

- `install_tunnel.sh` - اسکریپت نصب خودکار روی هر دو سرور
- `setup_tunnel.sh` - اسکریپت تنظیم اولیه و کانفیگ
- `tunnel_client.sh` - اسکریپت کلاینت برای سرور ایران
- `tunnel_server.sh` - اسکریپت سرور برای سرور خارج
- `tunnel_manager.sh` - اسکریپت مدیریت و مانیتورینگ
- `README.md` - این فایل راهنما

## ویژگی‌ها

### 🚀 **نصب خودکار**
- نصب وابستگی‌های مورد نیاز
- تنظیم فایروال و SSH
- ایجاد سرویس‌های systemd
- مدیریت خودکار سرویس‌ها

### 🔒 **امنیت بالا**
- استفاده از کلیدهای SSH
- غیرفعال کردن ورود با رمز عبور
- تنظیم فایروال مناسب
- لاگ‌گیری کامل

### 📊 **مانیتورینگ پیشرفته**
- نمایش وضعیت زنده تانل
- تست سرعت و تأخیر
- نمایش آمار سیستم
- لاگ‌گیری جامع

### 🔧 **مدیریت آسان**
- دستورات ساده و قابل فهم
- رابط کاربری رنگی
- مدیریت خطاهای خودکار
- پشتیبان‌گیری و بازگردانی

## نحوه استفاده

### نصب اولیه

```bash
# کپی فایل‌ها روی هر دو سرور
scp *.sh user@server:/path/to/directory/

# اجرای نصب خودکار
./install_tunnel.sh
```

### تنظیم اولیه

```bash
# تنظیم اولیه (روی هر دو سرور)
tunnel setup

# انتخاب نوع سرور:
# 1) سرور ایران (کلاینت)
# 2) سرور خارج (سرور)
```

### مدیریت تانل

```bash
# شروع تانل
tunnel start

# متوقف کردن تانل
tunnel stop

# بررسی وضعیت
tunnel status

# مانیتورینگ زنده
tunnel monitor
```

## تنظیمات سرورها

### سرور ایران (کلاینت)

```bash
# اطلاعات مورد نیاز:
# - آدرس IP سرور خارج
# - پورت SSH سرور خارج
# - نام کاربری سرور خارج
# - پورت محلی برای تانل
# - پورت تانل روی سرور خارج
```

### سرور خارج (سرور)

```bash
# اطلاعات مورد نیاز:
# - پورت SSH برای تانل
# - پورت تانل
# - کلید عمومی SSH از سرور ایران
```

## مثال‌های کاربردی

### تنظیم سرور خارج

```bash
# روی سرور خارج
./install_tunnel.sh
tunnel setup
# انتخاب گزینه 2 (سرور خارج)
# پورت SSH: 2222
# پورت تانل: 1080

# اضافه کردن کلید عمومی از سرور ایران
tunnel addkey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."

# شروع سرویس SSH
tunnel start
```

### تنظیم سرور ایران

```bash
# روی سرور ایران
./install_tunnel.sh
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

### مانیتورینگ

```bash
# بررسی وضعیت کلی
tunnel status

# مانیتورینگ زنده
tunnel monitor

# تست سرعت
tunnel-manager speed

# نمایش لاگ‌ها
tunnel-manager logs
```

## ساختار فایل‌ها

```
/etc/tunnel/
├── config.conf          # تنظیمات اصلی
├── default.conf         # الگوی تنظیمات
└── ssh/
    └── authorized_keys  # کلیدهای مجاز

/opt/tunnel/
├── tunnel_client.sh    # اسکریپت کلاینت
├── tunnel_server.sh    # اسکریپت سرور
├── tunnel_manager.sh   # اسکریپت مدیریت
└── setup_tunnel.sh     # اسکریپت تنظیم

/var/log/tunnel/
├── tunnel.log          # لاگ کلاینت
├── tunnel-server.log   # لاگ سرور
└── tunnel-manager.log  # لاگ مدیریت
```

## سرویس‌های systemd

- `iran-tunnel.service` - سرویس کلاینت
- `foreign-tunnel.service` - سرویس سرور

## دستورات مفید

### مدیریت سرویس‌ها

```bash
# فعال‌سازی سرویس
sudo systemctl enable iran-tunnel
sudo systemctl enable foreign-tunnel

# شروع سرویس
sudo systemctl start iran-tunnel
sudo systemctl start foreign-tunnel

# بررسی وضعیت
sudo systemctl status iran-tunnel
sudo systemctl status foreign-tunnel
```

### مدیریت فایروال

```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 2222/tcp

# CentOS/RHEL/Fedora
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=2222/tcp
```

### مدیریت SSH

```bash
# بررسی وضعیت SSH
sudo systemctl status ssh

# راه‌اندازی مجدد SSH
sudo systemctl restart ssh

# نمایش لاگ‌های SSH
sudo tail -f /var/log/auth.log | grep ssh
```

## عیب‌یابی

### مشکلات رایج

1. **اتصال برقرار نمی‌شود**
   ```bash
   # بررسی پورت‌ها
   netstat -tulnp | grep :2222
   
   # تست اتصال
   nc -z server_ip 2222
   ```

2. **خطای دسترسی SSH**
   ```bash
   # بررسی مجوزهای کلید
   chmod 600 ~/.ssh/tunnel_key
   chmod 700 ~/.ssh
   
   # تست اتصال SSH
   ssh -i ~/.ssh/tunnel_key tunnel@server_ip -p 2222
   ```

3. **تانل قطع می‌شود**
   ```bash
   # بررسی لاگ‌ها
   tail -f /var/log/tunnel.log
   
   # راه‌اندازی مجدد
   tunnel restart
   ```

### لاگ‌ها و فایل‌های مهم

- لاگ کلاینت: `/var/log/tunnel.log`
- لاگ سرور: `/var/log/tunnel-server.log`
- لاگ SSH: `/var/log/auth.log`
- تنظیمات: `/etc/tunnel/config.conf`

## امنیت

### نکات امنیتی

1. **استفاده از کلیدهای قوی**
   - حداقل 4096 بیت برای کلید RSA
   - استفاده از کلیدهای ED25519

2. **تنظیم فایروال**
   - باز کردن فقط پورت‌های ضروری
   - محدود کردن دسترسی به IP های خاص

3. **مانیتورینگ**
   - بررسی منظم لاگ‌ها
   - نظارت بر اتصالات غیرعادی

4. **به‌روزرسانی**
   - به‌روزرسانی منظم سیستم
   - به‌روزرسانی کلیدهای SSH

## پشتیبانی

برای گزارش مشکلات یا پیشنهادات:

1. نسخه سیستم عامل
2. نسخه اسکریپت‌ها
3. لاگ‌های خطا
4. تنظیمات کانفیگ

---

**نکته**: این اسکریپت‌ها برای استفاده در محیط‌های تولید طراحی شده‌اند و شامل تمام بررسی‌های امنیتی و مدیریت خطاهای لازم هستند.
