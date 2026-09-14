# -*- coding: utf-8 -*-
import os, csv, datetime, smtplib, requests
from email.mime.text import MIMEText
from email.header import Header
from urllib.parse import quote

TG_TOKEN = os.environ["TG_TOKEN"]
TG_CHAT  = os.environ["TG_CHAT"]
SITE     = (os.environ.get("SITE_URL") or "").rstrip("/")
MAX_DAILY = int(os.environ.get("MAX_DAILY") or "15")
TODAY = datetime.date.today().isoformat()

def link(params):
    return (SITE + "?" + params) if SITE else params

def tg_send(text):
    requests.post("https://api.telegram.org/bot" + TG_TOKEN + "/sendMessage",
                  json={"chat_id": TG_CHAT, "text": text[:4000]}, timeout=30).raise_for_status()

def email_send(to, subject, body):
    msg = MIMEText(body, "plain", "utf-8")
    msg["From"] = os.environ["SMTP_USER"]; msg["To"] = to; msg["Subject"] = Header(subject, "utf-8")
    s = smtplib.SMTP_SSL(os.environ["SMTP_HOST"], 465, timeout=60)
    s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASS"])
    s.send_message(msg); s.quit()

def days_since(d):
    try:
        return (datetime.date.today() - datetime.date.fromisoformat(d.strip())).days
    except Exception:
        return 999

def main():
    with open("campaign.csv", encoding="utf-8-sig", newline="") as f:
        rd = csv.DictReader(f)
        fields, rows = rd.fieldnames, list(rd)

    log, wa, sent = [], [], 0

    for r in rows:
        if (r.get("replied") or "").strip():
            continue
        stage = (r.get("stage") or "new").strip()
        ch = (r.get("channel") or "").strip().lower()
        contact = (r.get("contact") or "").strip()

        if stage == "new" and (r.get("msg1") or "").strip():
            body = r["msg1"].replace("{LINK}", link(r.get("url_params", "")))
            action, nxt, dt = "پیام اول", "sent1", "dt1"
        elif stage == "sent1" and days_since(r.get("dt1","")) >= 3 and (r.get("msg3") or "").strip():
            body = r["msg3"]; action, nxt, dt = "پیگیری روز۳", "sent3", "dt3"
        elif stage == "sent3" and days_since(r.get("dt3","")) >= 4 and (r.get("msg7") or "").strip():
            body = r["msg7"]; action, nxt, dt = "بستن در", "sent7", "dt7"
        else:
            continue
        if sent >= MAX_DAILY:
            break

        ok = False
        if ch == "email" and contact:
            try:
                email_send(contact, "پیشنهاد سایا برای " + r["name"], body); ok = True
            except Exception as e:
                log.append("ERR email " + r["name"] + ": " + str(e))
        elif ch == "telegram" and contact:
            try:
                requests.post("https://api.telegram.org/bot" + TG_TOKEN + "/sendMessage",
                              json={"chat_id": contact, "text": body[:4000]}, timeout=30).raise_for_status()
                ok = True
            except Exception as e:
                log.append("ERR tg " + r["name"] + ": " + str(e))
        elif ch == "whatsapp" and contact:
            wa.append("👤 " + r["name"] + " — " + action + "\n" + body +
                      "\n\n🔗 ارسال یک‌کلیکی:\nhttps://wa.me/" + contact + "?text=" + quote(body[:1500]))
            ok = True

        if ok:
            r["stage"] = nxt; r[dt] = TODAY
            sent += 1
            log.append("OK " + r["name"] + " — " + action + " (" + ch + ")")

    with open("campaign.csv", "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader(); w.writerows(rows)

    rep = "🤖 گزارش صبح علی۲ — " + TODAY + "\n\n" + ("\n".join(log) if log else "امروز چیزی در صف نبود.")
    if wa:
        rep += "\n\n📤 بسته واتس‌اپ امروز (هر لینک = یک کلیک):\n\n" + "\n──────────\n\n".join(wa)
    tg_send(rep)
    print("OK -", sent, "sent")

main()
