# راهنمای ایجاد ریپازیتوری گیت‌هاب

## مرحله 1: ایجاد ریپازیتوری روی گیت‌هاب

1. به https://github.com/new برو
2. نام ریپازیتوری: `tunnel-project`
3. توضیحات: `سیستم تانل خودکار بین سرور ایران و خارج`
4. Public یا Private انتخاب کن
5. روی "Create repository" کلیک کن

## مرحله 2: اتصال ریپازیتوری محلی به گیت‌هاب

بعد از ایجاد ریپازیتوری، دستورات زیر رو اجرا کن:

```bash
# اتصال به ریپازیتوری گیت‌هاب
git remote add origin https://github.com/USERNAME/tunnel-project.git

# آپلود فایل‌ها
git push -u origin main
```

## مرحله 3: تنظیم لینک نصب

بعد از آپلود، باید لینک‌ها رو در فایل‌ها تغییر بدی:

### در فایل install.sh:
```bash
# خط 15 را تغییر بده:
REPO_URL="https://github.com/USERNAME/tunnel-project.git"
```

### در فایل README.md:
```bash
# خط 8 را تغییر بده:
curl -sSL https://raw.githubusercontent.com/USERNAME/tunnel-project/main/install.sh | bash
```

## مرحله 4: تست نصب

بعد از تنظیم لینک‌ها، می‌تونی تست کنی:

```bash
# نصب با یک دستور
curl -sSL https://raw.githubusercontent.com/USERNAME/tunnel-project/main/install.sh | bash
```

## نکات مهم:

- USERNAME رو با نام کاربری گیت‌هاب‌ت جایگزین کن
- اگر ریپازیتوری Private باشه، باید توکن دسترسی بدی
- بعد از آپلود، لینک نصب آماده میشه
