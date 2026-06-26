#!/usr/bin/env bash
# Miqat Prayer Tracker Debug Tool

DB="$HOME/Library/Containers/com.azhar.miqat/Data/Library/Application Support/default.store"
TABLE="ZPRAYERRECORDMODEL"

APPLE_EPOCH=978307200  # 2001-01-01 UTC in unix seconds

# ── helpers ────────────────────────────────────────────────────────────────

ts_to_apple() { echo "$1 - $APPLE_EPOCH" | bc; }

normalise_date() {
  # accepts 26/6/20, 26/06/20, 2026/06/20, 26-6-20, 2026-06-20 → YYYY-MM-DD
  local raw="${1//\//-}"  # replace / with -
  local y m d
  IFS='-' read -r p1 p2 p3 <<< "$raw"
  # if year is 2 digits, prefix 20
  [ "${#p1}" -eq 2 ] && p1="20$p1"
  y=$p1; m=$p2; d=$p3
  printf "%04d-%02d-%02d" "$y" "$m" "$d"
}

date_to_unix() {
  # $1 = YYYY-MM-DD
  date -j -f "%Y-%m-%d %H:%M:%S" "$1 00:00:00" "+%s" 2>/dev/null
}

q() { sqlite3 "$DB" "$1"; }

prayer_time_unix() {
  # $1=prayer $2=YYYY-MM-DD
  local h
  case $1 in
    fajr) h=5 ;; dhuhr) h=13 ;; asr) h=16 ;; maghrib) h=19 ;; isha) h=21 ;;
  esac
  date -j -f "%Y-%m-%d %H:%M:%S" "$2 $h:00:00" "+%s" 2>/dev/null
}

pick_status() {
  echo "" >&2
  echo "  Status:  p) prayedOnTime   j) prayedWithJamaat   k) prayedKaza   m) missed" >&2
  printf "  Pick: " >&2
  read -r s </dev/tty
  case $s in
    p) echo "prayedOnTime" ;;
    j) echo "prayedWithJamaat" ;;
    k) echo "prayedKaza" ;;
    m) echo "missed" ;;
    *) echo "prayedOnTime" ;;
  esac
}

random_status() {
  local statuses=("prayedOnTime" "prayedOnTime" "prayedWithJamaat" "prayedOnTime" "missed")
  echo "${statuses[$RANDOM % 5]}"
}

insert_one() {
  # $1=prayer $2=YYYY-MM-DD $3=status
  local unix_ts apple_ts now_apple zid
  unix_ts=$(prayer_time_unix "$1" "$2")
  apple_ts=$(ts_to_apple "$unix_ts")
  now_apple=$(ts_to_apple "$(date +%s)")
  zid=$(uuidgen | tr '[:upper:]' '[:lower:]')

  q "INSERT OR IGNORE INTO $TABLE
     (Z_ENT, Z_OPT, ZID, ZPRAYERRAW, ZPRAYERTIME, ZSTATUSRAW, ZMARKEDAT)
     VALUES (1, 1, '$zid', '$1', $apple_ts, '$3', $now_apple);" \
    && echo "    ✅ $1 → $3" \
    || echo "    ⚠️  $1 → already exists, skipped"
}

# ── date input ─────────────────────────────────────────────────────────────

ask_dates() {
  printf "\n  Enter date or range (e.g. 26/6/20  or  26/6/20 30/6/20): "
  read -r d1 d2
  FROM=$(normalise_date "$d1")
  TO=$(normalise_date "${d2:-$d1}")
}

dates_in_range() {
  # prints each YYYY-MM-DD from $FROM to $TO inclusive
  local cur
  cur=$(date_to_unix "$FROM")
  local end
  end=$(date_to_unix "$TO")
  while [ "$cur" -le "$end" ]; do
    date -j -f "%s" "$cur" "+%Y-%m-%d"
    cur=$((cur + 86400))
  done
}

# ── actions ────────────────────────────────────────────────────────────────

do_insert() {
  ask_dates
  local days
  days=$(dates_in_range)
  local day_count
  day_count=$(echo "$days" | wc -l | tr -d ' ')

  echo ""
  echo "  Prayers: f=Fajr  d=Dhuhr  a=Asr  m=Maghrib  i=Isha  (default: all)"
  printf "  Which prayers? [f d a m i / press Enter for all]: "
  read -r prayer_input

  local prayers
  if [ -z "$prayer_input" ]; then
    prayers=("fajr" "dhuhr" "asr" "maghrib" "isha")
  else
    prayers=()
    for ch in $prayer_input; do
      case $ch in
        f) prayers+=("fajr") ;;
        d) prayers+=("dhuhr") ;;
        a) prayers+=("asr") ;;
        m) prayers+=("maghrib") ;;
        i) prayers+=("isha") ;;
      esac
    done
  fi

  echo ""
  echo "  Status mode:  s) Same for all   d) Different per prayer   r) Random"
  printf "  Pick: "
  read -r mode

  local same_status=""
  if [ "$mode" = "s" ]; then
    same_status=$(pick_status)
  fi

  echo ""
  echo "  Inserting for $day_count day(s): $FROM → $TO"

  while IFS= read -r day; do
    echo "  📅 $day"
    for prayer in "${prayers[@]}"; do
      local status
      if   [ "$mode" = "s" ]; then status=$same_status
      elif [ "$mode" = "r" ]; then status=$(random_status)
      else                         status=$(pick_status)
      fi
      insert_one "$prayer" "$day" "$status"
    done
  done <<< "$days"

  echo ""
  echo "  Done. ⚠️  Relaunch Miqat to see changes (SwiftData caches in memory)."
}

do_delete() {
  ask_dates
  local from_unix end_unix from_apple end_apple
  from_unix=$(date_to_unix "$FROM")
  end_unix=$(( $(date_to_unix "$TO") + 86400 ))
  from_apple=$(ts_to_apple "$from_unix")
  end_apple=$(ts_to_apple "$end_unix")

  local count
  count=$(q "SELECT COUNT(*) FROM $TABLE WHERE ZPRAYERTIME >= $from_apple AND ZPRAYERTIME < $end_apple;")
  echo ""
  echo "  Found $count records for $FROM → $TO"
  printf "  Confirm delete? [y/n]: "
  read -r confirm
  if [ "$confirm" = "y" ]; then
    q "DELETE FROM $TABLE WHERE ZPRAYERTIME >= $from_apple AND ZPRAYERTIME < $end_apple;"
    echo "  🗑  Deleted $count records."
  else
    echo "  Cancelled."
  fi
}

do_list() {
  printf "\n  Enter date (e.g. 26/6/20): "
  read -r day
  day=$(normalise_date "$day")
  local from_unix end_unix from_apple end_apple
  from_unix=$(date_to_unix "$day")
  end_unix=$(( from_unix + 86400 ))
  from_apple=$(ts_to_apple "$from_unix")
  end_apple=$(ts_to_apple "$end_unix")

  echo ""
  echo "  📅 $day"
  echo "  ─────────────────────────────"
  q "SELECT printf('  %-8s  %s', ZPRAYERRAW, ZSTATUSRAW)
     FROM $TABLE
     WHERE ZPRAYERTIME >= $from_apple AND ZPRAYERTIME < $end_apple
     ORDER BY ZPRAYERTIME;"

  local count
  count=$(q "SELECT COUNT(*) FROM $TABLE WHERE ZPRAYERTIME >= $from_apple AND ZPRAYERTIME < $end_apple;")
  echo "  ─────────────────────────────"
  echo "  $count records"
}

do_clear() {
  local count
  count=$(q "SELECT COUNT(*) FROM $TABLE;")
  echo ""
  echo "  ⚠️  This will delete ALL $count records."
  printf "  Type YES to confirm: "
  read -r confirm
  if [ "$confirm" = "YES" ]; then
    q "DELETE FROM $TABLE;"
    echo "  🗑  Cleared all records."
  else
    echo "  Cancelled."
  fi
}

# ── main loop ───────────────────────────────────────────────────────────────

if [ ! -f "$DB" ]; then
  echo "❌ DB not found — launch Miqat at least once first."
  exit 1
fi

echo ""
echo "  ╔══════════════════════════════╗"
echo "  ║   Miqat Tracker Debug Tool  ║"
echo "  ╚══════════════════════════════╝"

while true; do
  echo ""
  echo "  i) Insert    d) Delete    l) List    c) Clear all    q) Quit"
  printf "  > "
  read -r cmd
  case $cmd in
    i) do_insert ;;
    d) do_delete ;;
    l) do_list ;;
    c) do_clear ;;
    q) echo "  Bye!"; exit 0 ;;
    *) echo "  Unknown — pick i / d / l / c / q" ;;
  esac
done
