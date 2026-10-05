BACKUP 2026-09-14 07:17 (user-approved, before ALT-image patching)
Device state: DEC=ALT aucode_adec_r2.bin (N-12 patched, md5 51392f23) ACTIVE;
  MS12V22 = N15_X marker build (2a279c8b) inactive-but-patched
SND: MS12V22 = N-11 (b2a7e246); asnd_r2.bin = STOCK (42c1cb79)
DEPLOY PROBLEM FOUND: R2 logs print from ALT image (aucode_adec_r2.bin), NOT MS12V22!
  - X-marker on MS12V22 'decType change' string did NOT appear in log => ALT executes.
  - loader field 0x4d0: ==4 should select MS12V22, but device 0x4d0 must differ.
STOCK md5s for rollback:
  DEC MS12V22 stock: 4b7e9509b4358fd3a130bd4d3b9cbe0a (local r57_npcm/artifacts/aucode_adec_r2_MS12V22_STOCK.bin)
  ALT adec stock: e26ce887c6d3573d6fd5c243881cb448 (local VERIFY_adec_r2_alt.bin)
  SND MS12V22 stock: eb879cdc07f510722f19db6d18d77d3c
Restore commands:
  adb root; adb remount
  adb push DEVICE_<file> /vendor/lib/utopia/audio_bin/<file>
  (or push the stock files from aeon_validate paths for full rollback)
