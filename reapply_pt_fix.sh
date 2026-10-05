#!/system/bin/sh
# Reapply AC3/EAC3/DTS passthrough fix after a firmware (OTA) update.
# Usage: adb root && adb push reapply_pt_fix.sh /data/local/tmp/ && adb shell sh /data/local/tmp/reapply_pt_fix.sh
MD5_PATCHED="2e34d0c973472405197dd7c7f20bdb92"
MD5_ORIG="c2b5c57dba4f89228da72a29c71f0c06"

echo "[*] current libmi3:"
md5sum /vendor/lib/libmi3.so

mount -o remount,rw /vendor || { echo "FAIL: remount rw /vendor"; exit 1; }

if [ "$(md5sum < /data/local/tmp/libmi3_patched.so | cut -d' ' -f1)" != "$MD5_PATCHED" ]; then
  echo "FAIL: /data/local/tmp/libmi3_patched.so missing/corrupt - re-push it from PC"; exit 1
fi

cat /data/local/tmp/libmi3_patched.so > /vendor/lib/libmi3.so && sync
CUR=$(md5sum < /vendor/lib/libmi3.so | cut -d' ' -f1)
echo "[*] installed md5: $CUR"
[ "$CUR" = "$MD5_PATCHED" ] || { echo "FAIL: md5 mismatch"; exit 1; }

stop vendor.audio-hal; sleep 1; start vendor.audio-hal
sleep 3
echo "[OK] fix reapplied. HAL: $(getprop init.svc.vendor.audio-hal)"
