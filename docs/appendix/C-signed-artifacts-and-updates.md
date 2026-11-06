# Appendix C: Signed Artifacts, standalone update, commit and manual rollback

| | |
|---|---|
| Title | Appendix C to the Validation Report: Signed Artifacts, standalone update, commit and manual rollback |
| Version | 0.1 (draft) |
| Date | 2026-11-06 (date of test: 2026-11-06) |
| Author | Northern.tech |
| Customer | Chemify.io |
| SoW reference | Workstream A: Board Integration (evidence for AC.1) |
| Device | Raspberry Pi 4 Model B Rev 1.5 (4 GB), serial console 115200 8N1 |
| Software | Image `chemify-rpi4-0.1.0`; update Artifacts `chemify-rpi4-0.1.1` (signed with the development key, unsigned, and signed with a different key) |

Session 1, part 2. The Artifacts were built with `MENDER_ARTIFACT_NAME=chemify-rpi4-0.1.1` and signed with `mender-artifact sign` outside the build, as recommended by Mender. They were placed in `/data/test-artifacts/` on the device. `mender-updated` was stopped after each boot, as required for standalone mode.

Notes on the format: the excerpt is a transcript of the serial console. Each command is shown after a
`root@raspberrypi4-64:~#` prompt. Boot output is trimmed to the relevant U-Boot and kernel lines, the
board's MAC address and serial number are redacted, and lines starting with `#` are section markers
added for readability. The device has no real-time clock and no network, so timestamps inside
Mender log lines show 1970.

## C.1 Build host: key and Artifact verification

```text
$ openssl pkey -pubin -in dev-public.key -noout -text | head -n 1
Public-Key: (3072 bit)
$ sha256sum dev-public.key
b1a4f1cb6e325d56371956004036a1e041d14c13ef7b38e31dc0758433b905b8  dev-public.key

$ mender-artifact --version
mender-artifact version 4.4.2

$ mender-artifact validate chemify-rpi4-0.1.1-signed.mender -k dev-public.key
Artifact file 'chemify-rpi4-0.1.1-signed.mender' validated successfully
(exit code 0)

$ mender-artifact validate chemify-rpi4-0.1.1-unsigned.mender -k dev-public.key
missing signature
(exit code 5)

$ mender-artifact validate chemify-rpi4-0.1.1-wrongkey.mender -k dev-public.key
crypto/rsa: verification error
(exit code 5)

$ mender-artifact validate chemify-rpi4-0.1.2-broken-signed.mender -k dev-public.key
Artifact file 'chemify-rpi4-0.1.2-broken-signed.mender' validated successfully
(exit code 0)

$ mender-artifact read chemify-rpi4-0.1.1-signed.mender
Mender Artifact:
  Name: chemify-rpi4-0.1.1
  Format: mender
  Version: 3
  Signature: signed but no key for verification provided; please use `-k` option for providing verification key
  Compatible types: [raspberrypi4-64]
  Provides group: 
  Depends on one of artifact(s): []
  Depends on one of group(s): []
  State scripts: []

$ sha256sum *.mender
e1479da2425c6e58a545fbf9b1be4d1d464fa7afffb3eb3f3416b238d89120e9  chemify-rpi4-0.1.1-signed.mender
9b613ac9be32fbc6c1e277d8bf56ef489c96643fef048eb186985ea539a43d30  chemify-rpi4-0.1.1-unsigned.mender
64de00880abee90e8e5fc56db1c50062e2da59cb0eaf67dc9550e2568ea1173a  chemify-rpi4-0.1.1-wrongkey.mender
8fed4e9f7014d7fe69e4304d6ba8099be778f65816a8e3515afe4ebf68128169  chemify-rpi4-0.1.2-broken-signed.mender
```

## C.2 Device

```text

# === SIGNATURE TESTS (AC.1.3) ===   [2026-11-06 13:39:17]
root@raspberrypi4-64:~# systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# echo '--- unsigned artifact ---'
--- unsigned artifact ---
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-unsigned.mender
record_id=1 severity=error time="1970-Jan-01 00:02:41.621181" name="Global" msg="Signature verification Error: expecting signed artifact, but no signature file found" 
Streaming failed.
System not modified.
Could not fulfill request: Signature verification Error: expecting signed artifact, but no signature file found
root@raspberrypi4-64:~# echo '--- artifact signed with a different (wrong) key ---'
--- artifact signed with a different (wrong) key ---
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-wrongkey.mender
record_id=1 severity=error time="1970-Jan-01 00:02:41.859269" name="Global" msg="Signature verification Error: Wrong manifest signature or wrong key" 
Streaming failed.
System not modified.
Could not fulfill request: Signature verification Error: Wrong manifest signature or wrong key
root@raspberrypi4-64:~# mender-update show-artifact; fw_printenv mender_boot_part upgrade_available bootcount
chemify-rpi4-0.1.0
mender_boot_part=2
upgrade_available=0
bootcount=0

# === AC.1.2 manual rollback: install signed artifact, reboot, mender-update rollback ===   [2026-11-06 13:39:20]
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-signed.mender
Installing artifact...
[progress 0% ... 100%]
record_id=1 severity=info time="1970-Jan-01 00:04:01.369854" name="Global" msg="Update Module output (stdout): ================ STATISTICS ================" 
record_id=2 severity=info time="1970-Jan-01 00:04:01.370149" name="Global" msg="Update Module output (stdout): Blocks written:        262" 
record_id=3 severity=info time="1970-Jan-01 00:04:01.370221" name="Global" msg="Update Module output (stdout): Blocks omitted:        114" 
record_id=4 severity=info time="1970-Jan-01 00:04:01.370263" name="Global" msg="Update Module output (stdout): Bytes written:   274726912" 
record_id=5 severity=info time="1970-Jan-01 00:04:01.370303" name="Global" msg="Update Module output (stdout): Total bytes:     394264576" 
record_id=6 severity=info time="1970-Jan-01 00:04:01.370344" name="Global" msg="Update Module output (stdout): ============================================" 
Installed, but not committed.
Use 'commit' to update, or 'rollback' to roll back the update.
At least one payload requested a reboot of the device it updated.
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=1
bootcount=0
root@raspberrypi4-64:~# reboot
[... boot output trimmed to key lines ...]
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... OK
Starting kernel ...
[    0.000000] Machine model: Raspberry Pi 4 Model B Rev 1.5
[    0.000000] Kernel command line: ... console=ttyS0,115200 ... root=/dev/mmcblk0p3 ...
[    0.000000] Memory: 3351968K/4050944K available (14528K kernel code, 2246K rwdata, 4712K rodata, 5120K init, 1098K bss, 174688K reserved, 524288K cma-reserved)
Poky (Yocto Project Reference Distro) 5.0.15 raspberrypi4-64 ttyS0
[logged in as root on the serial console]

root@raspberrypi4-64:~# systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# cat /etc/mender/artifact_info
cat: can't open '/etc/mender/artifact_info': No such file or directory
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# fw_printenv mender_boot_part upgrade_available bootcount
mender_boot_part=3
upgrade_available=1
bootcount=1
root@raspberrypi4-64:~# mender-update rollback
Rolled back.
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# reboot
[... boot output trimmed to key lines ...]
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... OK
Starting kernel ...
[    0.000000] Machine model: Raspberry Pi 4 Model B Rev 1.5
[    0.000000] Kernel command line: ... console=ttyS0,115200 ... root=/dev/mmcblk0p2 ...
[    0.000000] Memory: 3351968K/4050944K available (14528K kernel code, 2246K rwdata, 4712K rodata, 5120K init, 1098K bss, 174688K reserved, 524288K cma-reserved)
Poky (Yocto Project Reference Distro) 5.0.15 raspberrypi4-64 ttyS0
[logged in as root on the serial console]

root@raspberrypi4-64:~# systemctl stop mender-updated
root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# fw_printenv mender_boot_part upgrade_available bootcount
mender_boot_part=2
upgrade_available=0
bootcount=1

# === AC.1.2 successful update: install, reboot, commit ===   [2026-11-06 13:42:22]
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-signed.mender 2>&1 | grep -vE "record_id|%"
Installing artifact...
Installed, but not committed.
Use 'commit' to update, or 'rollback' to roll back the update.
At least one payload requested a reboot of the device it updated.
root@raspberrypi4-64:~# fw_printenv mender_boot_part upgrade_available bootcount
mender_boot_part=3
upgrade_available=1
bootcount=0
root@raspberrypi4-64:~# reboot
[... boot output trimmed to key lines ...]
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... OK
Starting kernel ...
[    0.000000] Machine model: Raspberry Pi 4 Model B Rev 1.5
[    0.000000] Kernel command line: ... console=ttyS0,115200 ... root=/dev/mmcblk0p3 ...
[    0.000000] Memory: 3351968K/4050944K available (14528K kernel code, 2246K rwdata, 4712K rodata, 5120K init, 1098K bss, 174688K reserved, 524288K cma-reserved)
Poky (Yocto Project Reference Distro) 5.0.15 raspberrypi4-64 ttyS0
[logged in as root on the serial console]

root@raspberrypi4-64:~# systemctl stop mender-updated
root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_printenv mender_boot_part upgrade_available bootcount
mender_boot_part=3
upgrade_available=1
bootcount=1
root@raspberrypi4-64:~# mender-update commit
Committed.
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.1
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=1

# === reboot after commit: must stay on the new version ===   [2026-11-06 13:43:40]
root@raspberrypi4-64:~# reboot
[... boot output trimmed to key lines ...]
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... OK
Starting kernel ...
[    0.000000] Machine model: Raspberry Pi 4 Model B Rev 1.5
[    0.000000] Kernel command line: ... console=ttyS0,115200 ... root=/dev/mmcblk0p3 ...
[    0.000000] Memory: 3351968K/4050944K available (14528K kernel code, 2246K rwdata, 4712K rodata, 5120K init, 1098K bss, 174688K reserved, 524288K cma-reserved)
Poky (Yocto Project Reference Distro) 5.0.15 raspberrypi4-64 ttyS0
[logged in as root on the serial console]

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.1
root@raspberrypi4-64:~# fw_printenv mender_boot_part upgrade_available bootcount
mender_boot_part=3
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# while systemctl list-jobs --no-legend | grep -q .; do sleep 5; done; systemctl is-active mender-authd mender-updated
active
active
```
