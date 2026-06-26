#!/usr/bin/env python3
"""
Miqat Prayer Tracker Debug Tool
Usage:
  python3 debug_tracker.py insert 2026-06-20              # all 5 prayers as prayedOnTime
  python3 debug_tracker.py insert 2026-06-20 missed       # all as missed
  python3 debug_tracker.py insert 2026-06-20 mixed        # realistic mix
  python3 debug_tracker.py delete 2026-06-20              # delete one day
  python3 debug_tracker.py delete 2026-06-01 2026-06-25   # delete date range
  python3 debug_tracker.py list 2026-06-20                # show records for date
  python3 debug_tracker.py clear                          # delete ALL records
"""

import sqlite3, uuid, sys, os
from datetime import datetime, timedelta, timezone

DB_PATH = os.path.expanduser(
    "~/Library/Containers/com.azhar.miqat/Data/Library/Application Support/default.store"
)
TABLE   = "ZPRAYERRECORDMODEL"
PRAYERS = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
PRAYER_HOURS = {"fajr": 5, "dhuhr": 13, "asr": 16, "maghrib": 19, "isha": 21}
MIXED   = ["prayedOnTime", "prayedOnTime", "prayedWithJamaat", "prayedOnTime", "missed"]

def parse_date(s):
    return datetime.strptime(s, "%Y-%m-%d")

def to_core_data_ts(dt: datetime) -> float:
    # Core Data stores timestamps as seconds since 2001-01-01 UTC
    epoch = datetime(2001, 1, 1, tzinfo=timezone.utc)
    return (dt.replace(tzinfo=timezone.utc) - epoch).total_seconds()

def from_core_data_ts(ts: float) -> datetime:
    return datetime(2001, 1, 1) + timedelta(seconds=ts)

def connect():
    if not os.path.exists(os.path.expanduser(DB_PATH)):
        print(f"❌ DB not found — launch Miqat at least once first.")
        sys.exit(1)
    return sqlite3.connect(os.path.expanduser(DB_PATH))

def insert(date_str, mode="prayedOnTime"):
    date = parse_date(date_str)
    con  = connect()
    cur  = con.cursor()
    now_ts = to_core_data_ts(datetime.now(tz=timezone.utc))
    inserted = 0

    for i, prayer in enumerate(PRAYERS):
        dt     = date.replace(hour=PRAYER_HOURS[prayer], minute=0, second=0)
        status = MIXED[i] if mode == "mixed" else mode
        zid    = uuid.uuid4().bytes  # BLOB

        try:
            cur.execute(
                f'INSERT INTO {TABLE} (Z_ENT, Z_OPT, ZID, ZPRAYERRAW, ZPRAYERTIME, ZSTATUSRAW, ZMARKEDAT) '
                f'VALUES (1, 1, ?, ?, ?, ?, ?)',
                (zid, prayer, to_core_data_ts(dt), status, now_ts)
            )
            inserted += 1
            print(f"  ✅ {prayer:8s} → {status}")
        except sqlite3.IntegrityError:
            print(f"  ⚠️  {prayer:8s} → already exists, skipped")

    con.commit(); con.close()
    print(f"\nInserted {inserted} records for {date_str}")

def delete(from_str, to_str=None):
    from_dt = parse_date(from_str)
    to_dt   = parse_date(to_str) + timedelta(days=1) if to_str else from_dt + timedelta(days=1)

    con = connect(); cur = con.cursor()
    cur.execute(
        f'DELETE FROM {TABLE} WHERE ZPRAYERTIME >= ? AND ZPRAYERTIME < ?',
        (to_core_data_ts(from_dt), to_core_data_ts(to_dt))
    )
    n = cur.rowcount; con.commit(); con.close()
    label = f"{from_str} → {to_str}" if to_str else from_str
    print(f"🗑  Deleted {n} records for {label}")

def clear_all():
    con = connect(); cur = con.cursor()
    cur.execute(f'DELETE FROM {TABLE}')
    n = cur.rowcount; con.commit(); con.close()
    print(f"🗑  Deleted ALL {n} records")

def list_records(date_str):
    date    = parse_date(date_str)
    from_ts = to_core_data_ts(date)
    to_ts   = to_core_data_ts(date + timedelta(days=1))

    con = connect(); cur = con.cursor()
    cur.execute(
        f'SELECT ZPRAYERRAW, ZPRAYERTIME, ZSTATUSRAW FROM {TABLE} '
        f'WHERE ZPRAYERTIME >= ? AND ZPRAYERTIME < ? ORDER BY ZPRAYERTIME',
        (from_ts, to_ts)
    )
    rows = cur.fetchall(); con.close()
    if not rows:
        print(f"No records for {date_str}"); return
    print(f"\nRecords for {date_str}:")
    for prayer, ts, status in rows:
        t = from_core_data_ts(ts).strftime("%H:%M")
        print(f"  {prayer:8s}  {t}  {status}")

if __name__ == "__main__":
    args = sys.argv[1:]
    if not args: print(__doc__); sys.exit(0)
    cmd = args[0]
    if   cmd == "insert" and len(args) >= 2: insert(args[1], args[2] if len(args) > 2 else "prayedOnTime")
    elif cmd == "delete" and len(args) == 2: delete(args[1])
    elif cmd == "delete" and len(args) == 3: delete(args[1], args[2])
    elif cmd == "list"   and len(args) == 2: list_records(args[1])
    elif cmd == "clear":                     clear_all()
    else: print(__doc__)
