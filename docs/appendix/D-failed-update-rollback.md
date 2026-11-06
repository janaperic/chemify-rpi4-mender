# Appendix D: Failed update with automatic rollback

| | |
|---|---|
| Title | Appendix D to the Validation Report: Failed update with automatic rollback |
| Version | 0.1 (draft) |
| Date | 2026-11-06 (date of test: 2026-11-06) |
| Author | Northern.tech |
| Customer | Chemify.io |
| SoW reference | Workstream A: Board Integration (evidence for AC.1) |
| Device | Raspberry Pi 4 Model B Rev 1.5 (4 GB), serial console 115200 8N1 |
| Software | Image `chemify-rpi4-0.1.0`; Artifact `chemify-rpi4-0.1.2-broken` (validly signed, but its root filesystem has no `/boot/Image`, so it cannot boot) |

Session 2, on a freshly written SD card. Because of the test setup, this card kept the U-Boot environment of the previous session, so the device started this session on rootfs **B** (`/dev/mmcblk0p3`) and the update was written to rootfs A. This does not change the test: the update goes to the inactive partition, and the device must return to the active one.

Notes on the format: the excerpt is a transcript of the serial console. Each command is shown after a
`root@raspberrypi4-64:~#` prompt. Boot output is trimmed to the relevant U-Boot and kernel lines, the
board's MAC address and serial number are redacted, and lines starting with `#` are section markers
added for readability. The device has no real-time clock and no network, so timestamps inside
Mender log lines show 1970.

```text
# power applied   [2026-11-06 13:55:02]
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


# === SESSION 2: image chemify-rpi4-0.1.0, failed update with automatic rollback (AC.1.2) ===   [2026-11-06 13:55:47]
root@raspberrypi4-64:~# systemctl stop mender-updated; mender-update --version
5.2.0
root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# mender-update show-artifact
record_id=1 severity=info time="1970-Jan-01 00:00:33.937705" name="Global" msg="Installing the bootstrap Artifact" 
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# ls -l /data/test-artifacts/
-rw-rw-r--    1 root     root      36539904 Nov  6  2026 chemify-rpi4-0.1.2-broken-signed.mender
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.1.2-broken-signed.mender 2>&1 | grep -vE "record_id|%"
Installing artifact...
Installed, but not committed.
Use 'commit' to update, or 'rollback' to roll back the update.
At least one payload requested a reboot of the device it updated.
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=1
bootcount=0
root@raspberrypi4-64:~# reboot
[... boot output trimmed to key lines ...]
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... OK
Failed to load '/boot/Image'
resetting ...
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... OK
Warning: Bootlimit (1) exceeded. Using altbootcmd.
Starting kernel ...
[    0.000000] Machine model: Raspberry Pi 4 Model B Rev 1.5
[    0.000000] Kernel command line: ... console=ttyS0,115200 ... root=/dev/mmcblk0p3 ...
[    0.000000] Memory: 3351968K/4050944K available (14528K kernel code, 2246K rwdata, 4712K rodata, 5120K init, 1098K bss, 174688K reserved, 524288K cma-reserved)
Poky (Yocto Project Reference Distro) 5.0.15 raspberrypi4-64 ttyS0
[logged in as root on the serial console]

root@raspberrypi4-64:~# systemctl stop mender-updated
root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=2
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.0

# === client state after automatic rollback ===   [2026-11-06 13:58:19]
root@raspberrypi4-64:~# mender-update commit
record_id=1 severity=info time="1970-Jan-01 00:02:25.186238" name="Global" msg="Update Module output (stderr): Unexpected `upgrade_available=0` in ArtifactCommit." 
record_id=2 severity=info time="1970-Jan-01 00:02:25.186489" name="Global" msg="Update Module output (stderr): Upgrade failed and was reverted: refusing to commit!" 
record_id=3 severity=error time="1970-Jan-01 00:02:25.186803" name="Global" msg="Commit failed: Process returned non-zero exit status: ArtifactCommit: Process exited with status 1" 
record_id=4 severity=error time="1970-Jan-01 00:02:25.434782" name="Global" msg="Process returned non-zero exit status: ArtifactCommit: Process exited with status 1" 
Committing failed.
Rolled back.
Could not fulfill request: Process returned non-zero exit status: ArtifactCommit: Process exited with status 1
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# fw_printenv mender_boot_part upgrade_available
mender_boot_part=3
upgrade_available=0
```
