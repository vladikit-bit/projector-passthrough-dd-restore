# Відновлення DD-пастрування — Thundeal TD.98 Pro (MT5889)

Приватний репозиторій з **готовим набором для відновлення Dolby Digital / E-AC3 пасстрування по SPDIF** після OTA-оновлення прошивки проектора.

- **[RESTORE_GUIDE.md](RESTORE_GUIDE.md)** — покроковий процес (головний документ): скрипт, файл, перевірка, відкат, чекліст.
- `reapply_pt_fix.sh` — скрипт повторного застосування фіксу (md5-верифікація, remount /vendor, запис, рестарт HAL).
- `bin/` — чотири варіанти `libmi3.so` (патчі v1/v2/v3 + заводський оригінал) з контрольними md5.
- `docs/` — первинні звіти фази 0 (`REPORT_PASSTHROUGH_FIX.md`, `REPORT_SPDIF_audio_path.md`), еталонний `kodi_guisettings.xml`, журнал змін пристрою (`ROLLBACK.md`), README/md5-маніфест бекапу аудіо-бінарників.

Стосунок до решти: історія дослідження — [projector-research](https://github.com/vladikit-bit/projector-research); усі .md як є — [projector-research-base](https://github.com/vladikit-bit/projector-research-base).
