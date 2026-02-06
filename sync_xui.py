import os
import time
import requests
import schedule
from datetime import datetime

# Config
XUI_URL = os.getenv("XUI_URL")
XUI_TOKEN = os.getenv("XUI_TOKEN")
TG_TOKEN = os.getenv("TG_TOKEN")
TG_CHAT_ID = os.getenv("TG_CHAT_ID")

HEADERS = {
    "Authorization": f"Bearer {XUI_TOKEN}",
    "Content-Type": "application/json"
}

def notify(msg):
    if not TG_TOKEN or not TG_CHAT_ID:
        return
    url = f"https://api.telegram.org/bot{TG_TOKEN}/sendMessage"
    requests.post(url, json={"chat_id": TG_CHAT_ID, "text": msg}, timeout=10)

def sync_users():
    try:
        r = requests.get(f"{XUI_URL}/panel/api/inbounds/list", headers=HEADERS, timeout=15)
        r.raise_for_status()
        inbounds = r.json()["obj"]

        for inbound in inbounds:
            for client in inbound.get("clientStats", []):
                total = client.get("total", 0)
                up = client.get("up", 0)
                down = client.get("down", 0)
                expiry = client.get("expiryTime", 0)

                # FIX: total traffic = up + down
                used = up + down

                payload = {
                    "id": inbound["id"],
                    "settings": inbound["settings"],
                    "streamSettings": inbound["streamSettings"],
                    "sniffing": inbound["sniffing"],
                    "total": total,
                    "up": up,
                    "down": down,
                    "expiryTime": expiry
                }

                requests.post(
                    f"{XUI_URL}/panel/api/inbounds/update/{inbound['id']}",
                    headers=HEADERS,
                    json=payload,
                    timeout=15
                )

        notify("✅ 3X-UI Sync completed successfully")
    except Exception as e:
        notify(f"❌ Sync error: {e}")

schedule.every(5).minutes.do(sync_users)

notify("🚀 3X-UI Sync service started")

while True:
    schedule.run_pending()
    time.sleep(1)
