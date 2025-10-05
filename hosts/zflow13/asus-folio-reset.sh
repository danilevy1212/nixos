#!/usr/bin/env bash
set -euo pipefail

# Simple folio reset with retries and deadline
# - deadline: max total seconds the script may run
# - attempts: max reload attempts

declare -i deadline=30
declare -i attempts=3

start="$(date +%s)"
echo "[$(date -Is)] asus-folio-reset: begin (deadline=${deadline}s, attempts=${attempts})"

try=1
while [ "${try}" -le "${attempts}" ]; do
  elapsed=$(( $(date +%s) - start ))
  if [ "${elapsed}" -ge "${deadline}" ]; then
    echo "[$(date -Is)] asus-folio-reset: deadline reached (${elapsed}s)"
    exit 1
  fi

  echo "[$(date -Is)] attempt ${try}/${attempts}: reload hid_asus"
  # Unload (ignore failure if not loaded)
  if modprobe -r hid_asus 2>/dev/null; then
    echo "[$(date -Is)] hid_asus unloaded"
  else
    echo "[$(date -Is)] note: hid_asus not unloaded (possibly not loaded)"
  fi

  # Load
  if modprobe hid_asus; then
    echo "[$(date -Is)] hid_asus loaded"
    # Restore keyboard backlight if present
    if [ -e /sys/class/leds/asus::kbd_backlight/brightness ]; then
      if echo 3 > /sys/class/leds/asus::kbd_backlight/brightness 2>/dev/null; then
        echo "[$(date -Is)] set keyboard backlight to 3"
      else
        echo "[$(date -Is)] warn: could not set keyboard backlight"
      fi
    else
      echo "[$(date -Is)] note: kbd_backlight sysfs node not found"
    fi
    echo "[$(date -Is)] asus-folio-reset: success"
    exit 0
  else
    echo "[$(date -Is)] warn: modprobe hid_asus failed"
  fi

  # Sleep a bit before next attempt, but don’t exceed deadline
  sleep_for=2
  remaining=$(( deadline - ( $(date +%s) - start ) ))
  if [ "${remaining}" -le 0 ]; then
    echo "[$(date -Is)] asus-folio-reset: deadline reached"
    exit 1
  fi
  if [ "${sleep_for}" -gt "${remaining}" ]; then
    sleep_for="${remaining}"
  fi
  echo "[$(date -Is)] waiting ${sleep_for}s before retry"
  sleep "${sleep_for}"
  try=$(( try + 1 ))
done

echo "[$(date -Is)] asus-folio-reset: failed after ${attempts} attempts within ${deadline}s"
exit 1
