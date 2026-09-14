@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo   ساخت پکیج علی۲ — سایا
echo ==========================================
echo.

set "BASE=%USERPROFILE%\Desktop\saya-campaign"

if exist "%BASE%" (
    echo پوشه قبلاً وجود دارد — بازنویسی فایل‌ها...
) else (
    mkdir "%BASE%"
)

mkdir "%BASE%\.github" 2>nul
mkdir "%BASE%\.github\workflows" 2>nul
mkdir "%BASE%\scripts" 2>nul

echo [1/4] ساخت .github\workflows\ali2-daily.yml ...

> "%BASE%\.github\workflows\ali2-daily.yml" (
echo name: Ali2 Daily Marketing
echo on:
echo   schedule:
echo     - cron: '30 5 * * *'
echo   workflow_dispatch:
echo permissions:
echo   contents: write
echo jobs:
echo   ali2:
echo     runs-on: ubuntu-latest
echo     steps:
echo       - uses: actions/checkout@v4
echo       - uses: actions/setup-python@v5
echo         with:
echo           python-version: '3.11'
echo       - run: pip install requests
echo       - run: python scripts/ali2_run.py
echo         env:
echo           TG_TOKEN:  ${{ secrets.TG_TOKEN }}
echo           TG_CHAT:   ${{ secrets.TG_CHAT }}
echo           SITE_URL:  ${{ secrets.SITE_URL }}
echo           SMTP_HOST: ${{ secrets.SMTP_HOST }}
echo           SMTP_USER: ${{ secrets.SMTP_USER }}
echo           SMTP_PASS: ${{ secrets.SMTP_PASS }}
echo           MAX_DAILY: ${{ secrets.MAX_DAILY }}
echo       - name: Save State
echo         run: ^|
echo           git config user.name "Ali2 Bot"
echo           git config user.email "ali2@bot.local"
echo           git add campaign.csv
echo           git diff --quiet ^&^& git diff --staged --quiet ^|^| git commit -m "Ali2 daily $(date +%%F)"
echo           git push
)

echo [2/4] ساخت scripts\ali2_run.py ...

> "%BASE%\scripts\ali2_run.py" (
echo # -*- coding: utf-8 -*-
echo import os, csv, datetime, smtplib, requests
echo from email.mime.text import MIMEText
echo from email.header import Header
echo from urllib.parse import quote
echo.
echo TG_TOKEN = os.environ["TG_TOKEN"]
echo TG_CHAT  = os.environ["TG_CHAT"]
echo SITE     = (os.environ.get("SITE_URL") or "").rstrip("/")
echo MAX_DAILY = int(os.environ.get("MAX_DAILY") or "15")
echo TODAY = datetime.date.today().isoformat()
echo.
echo def link(params):
echo     return f"{SITE}?{params}" if SITE else params
echo.
echo def tg_send(text):
echo     for i in range(0, len(text), 3900):
echo         requests.post(f"https://api.telegram.org/bot{TG_TOKEN}/sendMessage",
echo                       json={"chat_id": TG_CHAT, "text": text[i:i+3900]}, timeout=30).raise_for_status()
echo.
echo def email_send(to, subject, body):
echo     msg = MIMEText(body, "plain", "utf-8")
echo     msg["From"], msg["To"], msg["Subject"] = os.environ["SMTP_USER"], to, Header(subject, "utf-8")
echo     with smtplib.SMTP_SSL(os.environ["SMTP_HOST"], 465, timeout=60) as s:
echo         s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASS"])
echo         s.send_message(msg)
echo.
echo def days_since(d):
echo     try:
echo         return (datetime.date.today() - datetime.date.fromisoformat(d.strip())).days
echo     except Exception:
echo         return 999
echo.
echo def main():
echo     with open("campaign.csv", encoding="utf-8-sig", newline="") as f:
echo         reader = csv.DictReader(f)
echo         fields, rows = reader.fieldnames, list(reader)
echo.
echo     log, wa_batch, sent = [], [], 0
echo.
echo     for r in rows:
echo         if (r.get("replied") or "").strip():
echo             continue
echo         stage  = (r.get("stage") or "new").strip()
echo         ch     = (r.get("channel") or "").strip().lower()
echo         contact = (r.get("contact") or "").strip()
echo.
echo         if stage == "new" and (r.get("msg1") or "").strip():
echo             body = r["msg1"].replace("{LINK}", link(r.get("url_params", "")))
echo             action, next_stage, dt_field = "پیام اول", "sent1", "dt1"
echo         elif stage == "sent1" and days_since(r.get("dt1", "")) >= 3 and (r.get("msg3") or "").strip():
echo             body = r["msg3"]
echo             action, next_stage, dt_field = "پیگیری روز۳", "sent3", "dt3"
echo         elif stage == "sent3" and days_since(r.get("dt3", "")) >= 4 and (r.get("msg7") or "").strip():
echo             body = r["msg7"]
echo             action, next_stage, dt_field = "بستن در", "sent7", "dt7"
echo         else:
echo             continue
echo         if sent >= MAX_DAILY:
echo             break
echo.
echo         ok = False
echo         if ch == "email" and contact:
echo             try:
echo                 email_send(contact, f"پیشنهاد اختصاصی سایا برای {r['name']}", body)
echo                 ok = True
echo             except Exception as e:
echo                 log.append(f"❌ ایمیل خطا ({r['name']}): {e}")
echo         elif ch == "telegram" and contact:
echo             try:
echo                 requests.post(f"https://api.telegram.org/bot{TG_TOKEN}/sendMessage",
echo                               json={"chat_id": contact, "text": body[:4000]}, timeout=30).raise_for_status()
echo                 ok = True
echo             except Exception as e:
echo                 log.append(f"❌ تلگرام خطا ({r['name']}): {e}")
echo         elif ch == "whatsapp" and contact:
echo             wa_batch.append(
echo                 f"👤 {r['name']} — {action}\n{body}\n\n🔗 ارسال یک‌کلیکی:\nhttps://wa.me/{contact}?text={quote(body[:1500])}"
echo             )
echo             ok = True
echo.
echo         if ok:
echo             r["stage"], r[dt_field] = next_stage, TODAY
echo             sent += 1
echo             log.append(f"✅ {r['name']} — {action} ({ch})")
echo.
echo     with open("campaign.csv", "w", encoding="utf-8-sig", newline="") as f:
echo         w = csv.DictWriter(f, fieldnames=fields)
echo         w.writeheader()
echo         w.writerows(rows)
echo.
echo     report = f"🤖 گزارش صبح علی۲ — {TODAY}\n\n" + ("\n".join(log) if log else "امروز چیزی در صف نبود.")
echo     if wa_batch:
echo         report += "\n\n📤 بسته واتس‌اپ امروز:\n\n" + "\n──────────────\n\n".join(wa_batch)
echo     tg_send(report)
echo     print(f"OK — {sent} sent")
echo.
echo if __name__ == "__main__":
echo     main()
)

echo [3/4] ساخت campaign.csv (قالب خالی — شما پر می‌کنید) ...

> "%BASE%\campaign.csv" (
echo id,name,pack,city,channel,contact,url_params,msg1,msg3,msg7,stage,dt1,dt3,dt7,replied,notes
)

echo [4/4] ساخت README.md ...

> "%BASE%\README.md" (
echo # علی۲ — بازاریاب خودکار سایا
echo.
echo ## ساختار:
echo - `.github/workflows/ali2-daily.yml` — ساعت‌کار خودکار هر روز ۹ صبح
echo - `scripts/ali2_run.py` — موتور ارسال و پیگیری
echo - `campaign.csv` — لیدها و پیام‌ها (خودت پر می‌کنی)
echo.
echo ## راه‌اندازی:
echo ۱. بات تلگرام بساز (@BotFather)
echo ۲. Chat ID بگیر (@userinfobot)
echo ۳. رمز اپ جیمیل بساز (myaccount.google.com/apppasswords)
echo ۴. ۶ Secret در Settings ← Secrets ← Actions اضافه کن:
echo    TG_TOKEN, TG_CHAT, SITE_URL, SMTP_HOST, SMTP_USER, SMTP_PASS
echo ۵. Actions ← Ali2 Daily Marketing ← Run workflow
echo.
echo ## کار روزانه:
echo - گزارش صبح به تلگرام می‌آید
echo - بسته واتس‌اپ با لینک‌های یک‌کلیکی
echo - هر جواب: در campaign.csv ستون replied بنویس «بله» و Commit کن
)

echo.
echo ==========================================
echo   ✅ تکمیل شد!
echo ==========================================
echo.
echo   مسیر: %BASE%
echo.
echo   ساختار ساخته‌شده:
echo   📁 .github\workflows\ali2-daily.yml
echo   📁 scripts\ali2_run.py
echo   📄 campaign.csv (خالی — خودت پر کن)
echo   📄 README.md
echo.
echo   قدم بعدی:
echo   ۱. فایل campaign.csv را با Notepad باز کن و لیدها را بگذار
echo   ۲. کل پوشه را در گیت‌هاب آپلود کن (Add file → Upload files)
echo   ۳. Secrets را بگذار و Actions را اجرا کن
echo.
pause