# Відновлення DD/AC3-пастрування після OTA-оновлення прошивки

Проектор: **Thundeal TD.98 Pro** (C50A, SoC MStar **MT5889**, Android 11, kernel 4.19.116, ODM Ntech).
Аудіоприймач у стендах: Pioneer VSX-817 (оптичний SPDIF).
Призначення цього документа — покрокова процедура повернення Dolby Digital / E-AC3 (і опційно DTS-відкриття) пастрування по оптичному виходу після того, як OTA-оновлення переписало `/vendor`.

> Історія того, як до цього прийшли: `docs/REPORT_PASSTHROUGH_FIX.md` (фаза 0, 2026-08-26),
> `docs/REPORT_SPDIF_audio_path.md` (архітектура аудіо-тракту), `docs/ROLLBACK.md` (журнал змін пристрою).

## Що саме ламається OTA'й і що ми робимо

Коротко, два зложених гейти (знайдені у фазі 0):

1. **`MI_AUDIO_GetCaps` у `/vendor/lib/libmi3.so` повертає 0 бітів можливостей** — Kodi бачить "No passthrough capabilities" і не дає вибрати RAW-вихід. Фікс: 20-байтовий патч, який OR-ить біти caps-слова (біт 5 = AC3, 6 = EAC3, 7 = AAC, 9 = DTS; у пізніших варіантах — ширші маски).
2. **`audiooutput.passthroughdevice` у Kodi не зберігається** — потрібне ручне прописування guisettings.

Патч бібліотеки не зачіпає ні підписи (vendor mount без dm-verity-перевірки цієї бібліотеки), ні сусідні функції; оригінал зберігається і відкат — одна команда.

## Файли в цьому репозиторії

| Файл | md5 | Що це |
|---|---|---|
| `reapply_pt_fix.sh` | — | Скрипт повторного застосування фіксу на пристрої (перевіряє md5, монтує /vendor rw, записує, рестартить HAL) |
| `bin/libmi3_patched.so` | `2e34d0c973472405197dd7c7f20bdb92` | **Патч v1** (OR 0x2E0 = біти AC3/EAC3/AAC/DTS) — саме він зашитий у скрипт |
| `bin/libmi3_patched_v2.so` | `d71a330f098b864cea7d3d1d550779ac` | Патч v2 (OR 0x2E1) — був на пристрої станом на бекап 2026-11-27 |
| `bin/libmi3_dts_v3.so` | `4c199a5c739e61741ba731534fbb3bf4` | Патч v3 (OR 0x070002E1 @ VA 0x6263e) — фінальний варіант епохи Exp-B |
| `bin/libmi3.so.orig-stock` | `c2b5c57dba4f89228da72a29c71f0c06` | **Заводський оригінал** для відкату (md5 = MD5_ORIG у скрипті) |
| `docs/kodi_guisettings.reference.xml` | — | Еталонний guisettings.xml Kodi з правильними passthrough-налаштуваннями |

⚠️ Застереження: знімок з пристрою `runtime_backup/libmi3.so.device` у робочій директорії має md5 `d71a330f…` — це **v2-патч**, не оригінал. Справжній оригінал — `bin/libmi3.so.orig-stock` (його md5 зашитий у скрипт як MD5_ORIG).

## Процедура відновлення (після OTA)

### Крок 0. Передумови

- adb з root на пристрої (`adb root` працює на цьому build — userdebug/test-keys).
- Файл `bin/libmi3_patched.so` заштовханий на пристрій (див. крок 1).
- Для Kodi-частини: Kodi 21.2 (у стендах — net.kodinerds.maven.kodi22 build).

### Крок 1. Завантажити патчену бібліотеку на пристрій

```bash
adb root
adb push bin/libmi3_patched.so /data/local/tmp/libmi3_patched.so
adb push reapply_pt_fix.sh /data/local/tmp/
adb shell chmod +x /data/local/tmp/reapply_pt_fix.sh
```

/data/local/tmp виживає після OTA — тому патчена копія там і живе між оновленнями.

### Крок 2. Застосувати фікс

```bash
adb shell sh /data/local/tmp/reapply_pt_fix.sh
```

Скрипт сам:
1. покаже md5 поточної `/vendor/lib/libmi3.so`;
2. перемонтує `/vendor` у rw (якщо не вийде — STOP, далі без сенсу);
3. звірить md5 джерела з `2e34d0c9…` (захист від битого файла);
4. запише патчену бібліотеку `cat … > /vendor/lib/libmi3.so` + `sync`;
5. перевірить md5 на місці;
6. рестартить `vendor.audio-hal` (`stop` → `start`) і покаже його стан.

Очікуваний вивід закінчується `[OK] fix reapplied. HAL: running`.

### Крок 3. Kodi-частина (якщо Kodi скинув налаштування)

У Kodi: **Налаштування → Система → Аудіо**:
- `Вихід для пасстрування (passthroughdevice)` = **`AUDIOTRACK:AudioTrack (RAW)`** (рядок з "(RAW)" — обов'язково сам він);
- `Dolby Digital (AC3) пасстрування` = увімкнено;
- `E-AC3 пасстрування` = увімкнено;
- `DTS пасстрування` — за смаком: на-stock будуть тиші (див. нижче), з v3-бібліотекою + рештою патчів епохи DTS-лінії — відкривається, але лочиться не завжди; робочий запасний варіант — `ac3transcode=true` (DTS→AC3 транскод, AVR показує DD).

Еталонні значення: `docs/kodi_guisettings.reference.xml` (ключі `audiooutput.passthroughdevice`, `audiooutput.ac3passthrough`, `audiooutput.eac3passthrough`, `audiooutput.dtspassthrough`, `audiooutput.ac3transcode`). На пристрої файл лежить у профілі Kodi (`guisettings.xml`, бекап робився як `/data/local/tmp/guisettings.xml.bak`).

### Крок 4. Перевірка

1. Програти тест-файл AC3 5.1 (у робочій директорії були `testmedia/` — ac3/eac3/dts).
2. На AVR (Pioneer VSX-817) має загорітись індикація **DD (Dolby Digital)**.
3. Лог-перевірка, якщо треба:
   ```bash
   adb shell "dumpsys media.audio_flinger | grep -i -E 'format|offload'"
   adb logcat -d | grep -i -E "AudioHAL codec type|MI_AUDIO"
   ```
   Очікується: формат AC3 (0x0b000000-family offload RAW), `AudioHAL codec type` не NONE.

### Відкат (повернення до заводської бібліотеки)

```bash
adb root
adb push bin/libmi3.so.orig-stock /data/local/tmp/libmi3_orig.so
adb shell "mount -o remount,rw /vendor && cat /data/local/tmp/libmi3_orig.so > /vendor/lib/libmi3.so && sync && stop vendor.audio-hal; sleep 1; start vendor.audio-hal"
# перевірка: md5 має бути c2b5c57dba4f89228da72a29c71f0c06
adb shell md5sum /vendor/lib/libmi3.so
```

## Що ще може знадобитись після OTA

- **Аудіо-бінарники DEC/SND (якщо експериментували ними)**: `docs/AUDIO_BINS_BACKUP_README.txt` + `docs/md5_manifest.txt` — md5 та adb-команди відновлення `aucode_adec_r2`, `asnd_r2`, `MS12V22` (бекап 2026-09-14; повні .bin лежать локально у `C:\firmware_temp\BACKUP_20260914_0717\` — у репозиторій не входять, ~57 МБ).
- **DTS-лінія (окремо)**: AC3-фікс відкриває *можливість* DTS, але нативне DTS-пастрування блоковане глибше — у DEC-DSP (два runtime-слова), ARM-сторонні патчі (utpa2k Exp-B, mik R5, libmi3 v3) закривали всі поверхневі гейти. Стан і повна історія: репозиторій `projector-research` (лінія DTS), `docs/ROLLBACK.md` для поточного стану пристрою.
- **audio_policy_configuration.xml** — у стенді модифікований 2026-08-29 (додані DTS/DTS_HD профілі до offload-міксу); якщо OTA повернув заводський — AC3-пастру все одно працює, DTS-профілі потрібні лише для DTS-спроб.

## Швидкий чекліст

```
[ ] adb root працює
[ ] libmi3_patched.so на /data/local/tmp (md5 2e34d0c9…)
[ ] sh /data/local/tmp/reapply_pt_fix.sh → [OK]
[ ] md5 /vendor/lib/libmi3.so = 2e34d0c9…
[ ] Kodi: passthroughdevice = AUDIOTRACK:AudioTrack (RAW)
[ ] AC3-файл → AVR індикація DD
```
