import os, csv, datetime, smtplib, requests
from email.mime.text import MIMEText
from email.header import Header
from urllib.parse import quote

TG, CHAT = os.environ["TG_TOKEN"], os.environ["TG_CHAT"]
SITE = os.environ.get("SITE_URL", "").rstrip("/")
MAX  = int(os.environ.get("MAX_DAILY", "15"))
TODAY = datetime.date.today()

def link(u): return f"{SITE}?{u}" if SITE else u

def tg_send(chat, text):
    r = requests.post(f"https://api.telegram.org/bot{TG}/sendMessage",
                      json={"chat_id": chat, "text": text[:4000]}, timeout=30)
    r.raise_for_status()

def email_send(to, subj, body):
    m = MIMEText(body, "plain", "utf-8")
    m["From"], m["To"], m["Subject"] = os.environ["SMTP_USER"], to, Header(subj, "utf-8")
    s = smtplib.SMTP_SSL(os.environ["SMTP_HOST"], 465, timeout=60)
    s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASS"])
    s.send_message(m); s.quit()

def days_ago(d):
    try: return (TODAY - datetime.date.fromisoformat(d.strip())).days
    except: return 999

rows = list(csv.DictReader(open("campaign.csv", encoding="utf-8-sig")))
log, wa_batch, sent = [], [], 0

for r in rows:
    if (r.get("replied") or "").strip(): continue
    ch = (r.get("channel") or "").strip().lower()
    # ماشین وضعیت: پیام اول ← پیگیری روز۳ ← بستن در
    if   r["stage"] == "new":
        msg, act, nxt, dtcol = r["msg1"], "پیام اول", "sent1", "dt1"
    elif r["stage"] == "sent1" and days_ago(r["dt1"]) >= 3:
        msg, act, nxt, dtcol = r["msg3"], "پیگیری روز۳", "sent3", "dt3"
    elif r["stage"] == "sent3" and days_ago(r["dt3"]) >= 4:
        msg, act, nxt, dtcol = r["msg7"], "بستن در", "sent7", "dt7"
    else: continue
    if not (msg or "").strip(): continue
    body = msg.replace("{LINK}", link(r["url_params"]))

    if ch == "telegram" and r["contact"]:
        try: tg_send(r["contact"], body)
        except Exception: log.append(f"❌ TG خطا: {r['name']}"); continue
    elif ch == "email" and r["contact"]:
        try: email_send(r["contact"], f"پیشنهاد اختصاصی سایا برای {r['name']}", body)
        except Exception: log.append(f"❌ ایمیل خطا: {r['name']}"); continue
    elif ch == "whatsapp":
        wa_batch.append(f"📲 {r['name']} — {act}\n{body}\n\n🔗 ارسال یک‌کلیکی: https://wa.me/{r['contact']}?text={quote(body)}")
        r["stage"] = nxt if act == "پیام اول" else r["stage"]  # واتس‌اپ: فقط پیام اول صف می‌شود
        if act == "پیام اول": r["dt1"] = TODAY.isoformat()
        continue
    else: continue

    r["stage"], r[dtcol] = nxt, TODAY.isoformat()
    sent += 1; log.append(f"✅ {r['name']} — {act} ({ch})")
    if sent >= MAX: break

with open("campaign.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys()); w.writeheader(); w.writerows(rows)

rep = f"🤖 گزارش صبح علی۲ — {TODAY.isoformat()}\n\n" + ("\n".join(log) or "امروز ارسالی در صف نبود")
if wa_batch:
    rep += "\n\n📤 بسته واتس‌اپ امروز (هر لینک = یک کلیک):\n\n" + "\n─────────\n\n".join(wa_batch)
tg_send(CHAT, rep); print("OK", sent)