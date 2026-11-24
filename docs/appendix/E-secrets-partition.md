# Appendix E: Change request "secrets partition"

| | |
|---|---|
| Title | Appendix E to the Validation Report: Change request "secrets partition" |
| Version | 0.2 (draft) |
| Date | 2026-11-24 (date of test: 2026-11-24) |
| Author | Northern.tech |
| Customer | Chemify.io |
| SoW reference | Workstream A: Board Integration (change request; regression evidence for AC.1) |
| Device | Raspberry Pi 4 Model B Rev 1.5 (4 GB), 16 GB SD card, serial console 115200 8N1 |
| Software | Image `chemify-rpi4-0.2.0`; Artifacts `chemify-rpi4-0.2.1` (signed, unsigned, signed with a different key) and `chemify-rpi4-0.2.2-broken` (validly signed, but its root filesystem has no `/boot/Image`, so it cannot boot) |

Part 1 is the complete test session on a freshly written SD card: partition layout, the raw secrets
partition, the Mender integration checklist (U-Boot variant), the Artifact tests, and a power cycle.
A random pattern is written to `/dev/mmcblk0p6` once, its SHA-256 checksum is stored on the data
partition (`/data/secrets.sha256`), and it is verified after every reboot, update, rollback and the
power cycle (`sha256sum -c /data/secrets.sha256` → `/dev/mmcblk0p6: OK`).

Part 2 is the first boot of the delivered image `chemify-rpi4-0.2.0`, written to the SD card with the
build's block map.

Notes on the format: the excerpt is a transcript of the serial console. Each command is shown after a
`root@raspberrypi4-64:~#` prompt. Boot output is trimmed to the relevant U-Boot and kernel lines, the
board's MAC address and serial number are redacted, and lines starting with `#` are section markers
added for readability. The device has no real-time clock and no network, so timestamps inside
Mender log lines show 1970. `lsblk` and `blockdev` are not part of `core-image-minimal`; `fdisk`,
`/proc/partitions` and `/sys/class/block` are used instead.

## Part 1: Test session

```text
# === SESSION: image chemify-rpi4-0.2.0, secrets partition change request ===   [2026-11-24 12:37:56]
root@raspberrypi4-64:~# head -n 3 /etc/os-release; uname -r
ID=poky
NAME="Poky (Yocto Project Reference Distro)"
VERSION="5.0.15 (scarthgap)"
6.6.63-v8
root@raspberrypi4-64:~# mender-update --version; mender-auth --version
5.2.0
5.2.0
root@raspberrypi4-64:~# mender-update show-artifact
record_id=1 severity=info time="1970-Jan-01 00:00:21.629218" name="Global" msg="Installing the bootstrap Artifact" 
chemify-rpi4-0.2.0

# === LAYOUT ===   [2026-11-24 12:37:57]
root@raspberrypi4-64:~# fdisk -l /dev/mmcblk0
Disk /dev/mmcblk0: 14 GB, 15552479232 bytes, 30375936 sectors
237312 cylinders, 4 heads, 32 sectors/track
Units: sectors of 1 * 512 = 512 bytes

Device       Boot StartCHS    EndCHS        StartLBA     EndLBA    Sectors  Size Id Type
/dev/mmcblk0p1 *  384,0,1     1023,3,32        49152     253951     204800  100M  c Win95 FAT32 (LBA)
/dev/mmcblk0p2    1023,3,32   1023,3,32       262144    4456447    4194304 2048M 83 Linux
/dev/mmcblk0p3    1023,3,32   1023,3,32      4456448    8650751    4194304 2048M 83 Linux
/dev/mmcblk0p4    1023,3,32   1023,3,32      8667134   12879871    4212738 2057M  f Win95 Ext'd (LBA)
/dev/mmcblk0p5    1023,3,32   1023,3,32      8667136   12861439    4194304 2048M 83 Linux
/dev/mmcblk0p6    1023,3,32   1023,3,32     12877824   12879871       2048 1024K 83 Linux
root@raspberrypi4-64:~# cat /proc/partitions | grep mmcblk0
 179        0   15187968 mmcblk0
 179        1     102400 mmcblk0p1
 179        2    2097152 mmcblk0p2
 179        3    2097152 mmcblk0p3
 179        4          1 mmcblk0p4
 179        5    2097152 mmcblk0p5
 179        6       1024 mmcblk0p6
root@raspberrypi4-64:~# cat /sys/class/block/mmcblk0p6/start /sys/class/block/mmcblk0p6/size
12877824
2048
root@raspberrypi4-64:~# blkid /dev/mmcblk0p1 /dev/mmcblk0p2 /dev/mmcblk0p3 /dev/mmcblk0p5
/dev/mmcblk0p1: LABEL="boot" UUID="329C-FC6A" TYPE="vfat"
/dev/mmcblk0p2: UUID="c515fc0d-40ea-4c38-867b-be440c830041" TYPE="ext4"
/dev/mmcblk0p3: UUID="c515fc0d-40ea-4c38-867b-be440c830041" TYPE="ext4"
/dev/mmcblk0p5: LABEL="data" UUID="d2551d92-e807-4dd3-965f-d2847593f70f" TYPE="ext4"
root@raspberrypi4-64:~# blkid /dev/mmcblk0p6; echo "blkid output lines: $(blkid /dev/mmcblk0p6 | wc -l)"
blkid output lines: 0
root@raspberrypi4-64:~# grep mmcblk0 /proc/mounts
/dev/mmcblk0p1 /uboot vfat rw,sync,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro 0 0
/dev/mmcblk0p5 /data ext4 rw,relatime 0 0
root@raspberrypi4-64:~# df -h /data
Filesystem                Size      Used Available Use% Mounted on
/dev/mmcblk0p5            1.9G    143.5M      1.6G   8% /data
root@raspberrypi4-64:~# cat /etc/fstab
# stock fstab - you probably want to override this with a machine specific one

/dev/root            /                    auto       defaults              1  1
proc                 /proc                proc       defaults              0  0
devpts               /dev/pts             devpts     mode=0620,ptmxmode=0666,gid=5      0  0
tmpfs                /run                 tmpfs      mode=0755,nodev,nosuid,strictatime 0  0
tmpfs                /var/volatile        tmpfs      defaults              0  0

# uncomment this if your device has a SD/MMC/Transflash slot
#/dev/mmcblk0p1       /media/card          auto       defaults,sync,noauto  0  0

# Where the U-Boot environment resides; for devices with SD card support ONLY!
/dev/mmcblk0p1       /uboot               auto       defaults,sync         0  2
/dev/mmcblk0p5       /data                auto       defaults              0  2
root@raspberrypi4-64:~# ls -la /mnt
drwxr-xr-x    2 root     root          4096 Mar  9  2018 .
drwxr-xr-x   19 root     root          4096 Nov 24  2026 ..
root@raspberrypi4-64:~# cat /var/lib/mender/mender.conf
{
    "RootfsPartA": "/dev/mmcblk0p2",
    "RootfsPartB": "/dev/mmcblk0p3"
root@raspberrypi4-64:~# systemctl cat data.mount | sed -n "1,15p"
# /run/systemd/generator/data.mount
# Automatically generated by systemd-fstab-generator

[Unit]
Documentation=man:fstab(5) man:systemd-fstab-generator(8)
SourcePath=/etc/fstab
Before=local-fs.target
Requires=systemd-fsck@dev-mmcblk0p5.service
After=systemd-fsck@dev-mmcblk0p5.service
After=blockdev@dev-mmcblk0p5.target

[Mount]
What=/dev/mmcblk0p5
Where=/data

# === SERVICES ===   [2026-11-24 12:37:58]
root@raspberrypi4-64:~# while systemctl list-jobs --no-legend | grep -q .; do sleep 5; done; uptime
 00:02:09 up 2 min,  load average: 0.05, 0.05, 0.01
root@raspberrypi4-64:~# systemctl is-system-running; systemctl --failed --no-legend
degraded
* systemd-networkd-wait-online.service loaded failed failed Wait for Network to be Configured
root@raspberrypi4-64:~# systemctl list-unit-files --no-legend | grep -i -E "grow|resize"; systemctl list-units --all --no-legend | grep -i -E "grow|resize" || echo "no grow/resize units loaded"
systemd-growfs-root.service              static          -
systemd-growfs@.service                  static          -
no grow/resize units loaded
root@raspberrypi4-64:~# journalctl -b --no-pager | grep -i -E "mmcblk0p6|resize|growfs" || echo "no journal entries for mmcblk0p6/resize/growfs"
no journal entries for mmcblk0p6/resize/growfs
root@raspberrypi4-64:~# which cryptsetup || echo "cryptsetup not in image"
cryptsetup not in image

# === SECRETS PATTERN ===   [2026-11-24 12:39:45]
root@raspberrypi4-64:~# sha256sum /dev/mmcblk0p6
6058588f1414bf8329dea740de04537aa17365a1605fa545be865451bcc72e99  /dev/mmcblk0p6
root@raspberrypi4-64:~# dd if=/dev/urandom of=/dev/mmcblk0p6 bs=1M count=1; sync
1+0 records in
1+0 records out
root@raspberrypi4-64:~# echo 3 > /proc/sys/vm/drop_caches; sha256sum /dev/mmcblk0p6 | tee /data/secrets.sha256; sync
2f005bdd7e3ba93d941692340c954d40becc1932e518a68d37ea946a15abe449  /dev/mmcblk0p6
root@raspberrypi4-64:~# hexdump -C -n 32 /dev/mmcblk0p6; blkid /dev/mmcblk0p6 || true
00000000  65 80 43 bf e7 38 64 c7  22 f0 29 3f b4 53 ea 77  |e.C..8d.".)?.S.w|
00000010  b5 8b d5 b7 6a 69 62 3c  ea 88 ba c3 43 10 7a 86  |....jib<....C.z.|
00000020

[logged in as root on the serial console]

# === CHECKLIST 1: services ===   [2026-11-24 12:40:03]
root@raspberrypi4-64:~# systemctl is-active mender-authd mender-updated
active
active
root@raspberrypi4-64:~# systemctl is-enabled mender-authd mender-updated
enabled
enabled
root@raspberrypi4-64:~# systemctl --failed --no-legend
* systemd-networkd-wait-online.service loaded failed failed Wait for Network to be Configured

# === CHECKLIST 2: env tools ===   [2026-11-24 12:40:03]
root@raspberrypi4-64:~# which fw_printenv fw_setenv
/usr/bin/fw_printenv
/usr/bin/fw_setenv
root@raspberrypi4-64:~# fw_printenv bootlimit bootcount upgrade_available mender_boot_part mender_boot_part_hex mender_kernel_name altbootcmd
bootlimit=1
bootcount=1
upgrade_available=0
mender_boot_part=2
mender_boot_part_hex=2
mender_kernel_name=Image
altbootcmd=run mender_altbootcmd; run bootcmd
root@raspberrypi4-64:~# fw_setenv; echo "fw_setenv rc=$?"
fw_setenv rc=0
root@raspberrypi4-64:~# cat /etc/fw_env.config
/dev/mmcblk0 0x800000 0x4000
/dev/mmcblk0 0x1000000 0x4000

# === CHECKLIST 3: partitions ===   [2026-11-24 12:40:04]
root@raspberrypi4-64:~# cat /var/lib/mender/mender.conf
{
    "RootfsPartA": "/dev/mmcblk0p2",
    "RootfsPartB": "/dev/mmcblk0p3"
root@raspberrypi4-64:~# mount | grep "on / "
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# stat -c "%n dev=%d" /
/ dev=45826

# === CHECKLIST 4: switch to B ===   [2026-11-24 12:40:04]
root@raspberrypi4-64:~# fw_setenv mender_boot_part 3 && fw_setenv mender_boot_part_hex 3; fw_printenv mender_boot_part mender_boot_part_hex
mender_boot_part=3
mender_boot_part_hex=3
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === CHECKLIST 4: switch back to A ===   [2026-11-24 12:40:47]
root@raspberrypi4-64:~# fw_setenv mender_boot_part 2 && fw_setenv mender_boot_part_hex 2; fw_printenv mender_boot_part mender_boot_part_hex
mender_boot_part=2
mender_boot_part_hex=2
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === CHECKLIST 5a: successful update case ===   [2026-11-24 12:41:30]
root@raspberrypi4-64:~# mount | grep "on / "
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_setenv upgrade_available 1 && fw_setenv bootcount 0 && fw_setenv mender_boot_part 3 && fw_setenv mender_boot_part_hex 3; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=1
bootcount=1
root@raspberrypi4-64:~# fw_setenv upgrade_available 0 && fw_setenv bootcount 0; fw_printenv upgrade_available bootcount
upgrade_available=0
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

# === CHECKLIST 5b: failed update / rollback case ===   [2026-11-24 12:42:37]
root@raspberrypi4-64:~# mount | grep "on / "
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_setenv upgrade_available 1 && fw_setenv bootcount 0 && fw_setenv mender_boot_part 2 && fw_setenv mender_boot_part_hex 2; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=1
bootcount=0
root@raspberrypi4-64:~# mkdir -p /mnt/inactive && mount /dev/mmcblk0p2 /mnt/inactive && mv /mnt/inactive/boot/Image /mnt/inactive/boot/Image.backup && ls -l /mnt/inactive/boot/ | grep Image; umount /mnt/inactive; sync
-rw-r--r--    1 root     root      27400704 Mar  9  2018 Image-6.6.63-v8
lrwxrwxrwx    1 root     root            15 Mar  9  2018 Image.backup -> Image-6.6.63-v8
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=2
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === CHECKLIST 5b: restore kernel (reverse rename) ===   [2026-11-24 12:43:27]
root@raspberrypi4-64:~# mount /dev/mmcblk0p2 /mnt/inactive && mv /mnt/inactive/boot/Image.backup /mnt/inactive/boot/Image && ls -l /mnt/inactive/boot/ | grep Image; umount /mnt/inactive; sync
lrwxrwxrwx    1 root     root            15 Mar  9  2018 Image -> Image-6.6.63-v8
-rw-r--r--    1 root     root      27400704 Mar  9  2018 Image-6.6.63-v8

# === verify restore: boot partition A ===   [2026-11-24 12:43:28]
root@raspberrypi4-64:~# fw_setenv mender_boot_part 2 && fw_setenv mender_boot_part_hex 2 && fw_setenv bootcount 0; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=0
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=0
root@raspberrypi4-64:~# ls -l /boot/Image
lrwxrwxrwx    1 root     root            15 Mar  9  2018 /boot/Image -> Image-6.6.63-v8
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

# === SIGNATURE TESTS (AC.1.3) ===   [2026-11-24 12:43:59]
root@raspberrypi4-64:~# systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.0
root@raspberrypi4-64:~# echo '--- unsigned artifact ---'
--- unsigned artifact ---
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.2.1-unsigned.mender
record_id=1 severity=error time="1970-Jan-01 00:02:43.104255" name="Global" msg="Signature verification Error: expecting signed artifact, but no signature file found" 
Streaming failed.
System not modified.
Could not fulfill request: Signature verification Error: expecting signed artifact, but no signature file found
root@raspberrypi4-64:~# echo '--- artifact signed with a different (wrong) key ---'
--- artifact signed with a different (wrong) key ---
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.2.1-wrongkey.mender
record_id=1 severity=error time="1970-Jan-01 00:02:43.340674" name="Global" msg="Signature verification Error: Wrong manifest signature or wrong key" 
Streaming failed.
System not modified.
Could not fulfill request: Signature verification Error: Wrong manifest signature or wrong key
root@raspberrypi4-64:~# mender-update show-artifact; fw_printenv mender_boot_part upgrade_available bootcount
chemify-rpi4-0.2.0
mender_boot_part=2
upgrade_available=0
bootcount=0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === AC.1.2 manual rollback: install signed artifact, reboot, mender-update rollback ===   [2026-11-24 12:44:09]
root@raspberrypi4-64:~# time mender-update install /data/test-artifacts/chemify-rpi4-0.2.1-signed.mender
Installing artifact...
[progress 0% ... 100%]
record_id=1 severity=info time="1970-Jan-01 00:07:17.546481" name="Global" msg="Update Module output (stdout): ================ STATISTICS ================" 
record_id=2 severity=info time="1970-Jan-01 00:07:17.546761" name="Global" msg="Update Module output (stdout): Blocks written:       1740" 
record_id=3 severity=info time="1970-Jan-01 00:07:17.546831" name="Global" msg="Update Module output (stdout): Blocks omitted:        308" 
record_id=4 severity=info time="1970-Jan-01 00:07:17.546875" name="Global" msg="Update Module output (stdout): Bytes written:  1824522240" 
record_id=5 severity=info time="1970-Jan-01 00:07:17.546917" name="Global" msg="Update Module output (stdout): Total bytes:    2147483648" 
record_id=6 severity=info time="1970-Jan-01 00:07:17.546957" name="Global" msg="Update Module output (stdout): ============================================" 
Installed, but not committed.
Use 'commit' to update, or 'rollback' to roll back the update.
At least one payload requested a reboot of the device it updated.
real	4m 25.82s
user	0m 40.46s
sys	0m 14.97s
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=1
bootcount=0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK
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

root@raspberrypi4-64:~# while ! systemctl is-active -q mender-updated; do sleep 5; done; systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=1
bootcount=1
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK
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

root@raspberrypi4-64:~# while ! systemctl is-active -q mender-updated; do sleep 5; done; systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === AC.1.2 successful update with commit ===   [2026-11-24 12:53:33]
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.2.1-signed.mender 2>&1 | grep -v "^0%" | grep -E "Bytes written|Total bytes|Installed|commit"
record_id=4 severity=info time="1970-Jan-01 00:10:38.476765" name="Global" msg="Update Module output (stdout): Bytes written:    12582912" 
record_id=5 severity=info time="1970-Jan-01 00:10:38.476799" name="Global" msg="Update Module output (stdout): Total bytes:    2147483648" 
Installed, but not committed.
Use 'commit' to update, or 'rollback' to roll back the update.
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

root@raspberrypi4-64:~# while ! systemctl is-active -q mender-updated; do sleep 5; done; systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=1
bootcount=1
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK
root@raspberrypi4-64:~# mender-update commit
Committed.
root@raspberrypi4-64:~# mender-update show-artifact; fw_printenv upgrade_available bootcount
chemify-rpi4-0.2.1
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

# === persistence after reboot ===   [2026-11-24 12:57:09]
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

root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.1
root@raspberrypi4-64:~# while systemctl list-jobs --no-legend | grep -q .; do sleep 5; done; systemctl is-active mender-authd mender-updated
active
active
root@raspberrypi4-64:~# cat /etc/fstab | grep mmcblk0; ls /mnt; grep mmcblk0 /proc/mounts
#/dev/mmcblk0p1       /media/card          auto       defaults,sync,noauto  0  0
/dev/mmcblk0p1       /uboot               auto       defaults,sync         0  2
/dev/mmcblk0p5       /data                auto       defaults              0  2
/dev/mmcblk0p1 /uboot vfat rw,sync,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro 0 0
/dev/mmcblk0p5 /data ext4 rw,relatime 0 0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === AC.1.2 failed update with automatic rollback ===   [2026-11-24 12:59:43]
root@raspberrypi4-64:~# systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.1
root@raspberrypi4-64:~# mender-update install /data/test-artifacts/chemify-rpi4-0.2.2-broken-signed.mender 2>&1 | grep -v "^0%" | grep -E -i "signature|Bytes written|Total bytes|Installed|commit|error"
record_id=4 severity=info time="1970-Jan-01 00:08:18.535730" name="Global" msg="Update Module output (stdout): Bytes written:  1461714944" 
record_id=5 severity=info time="1970-Jan-01 00:08:18.535762" name="Global" msg="Update Module output (stdout): Total bytes:    2147483648" 
Installed, but not committed.
Use 'commit' to update, or 'rollback' to roll back the update.
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=1
bootcount=0
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK
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

root@raspberrypi4-64:~# while ! systemctl is-active -q mender-updated; do sleep 5; done; systemctl stop mender-updated; systemctl is-active mender-updated
inactive
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=2
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.1
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK
root@raspberrypi4-64:~# mender-update commit
record_id=1 severity=info time="1970-Jan-01 00:10:27.939862" name="Global" msg="Update Module output (stderr): Unexpected `upgrade_available=0` in ArtifactCommit." 
record_id=2 severity=info time="1970-Jan-01 00:10:27.940127" name="Global" msg="Update Module output (stderr): Upgrade failed and was reverted: refusing to commit!" 
record_id=3 severity=error time="1970-Jan-01 00:10:27.940522" name="Global" msg="Commit failed: Process returned non-zero exit status: ArtifactCommit: Process exited with status 1" 
record_id=4 severity=error time="1970-Jan-01 00:10:28.202309" name="Global" msg="Process returned non-zero exit status: ArtifactCommit: Process exited with status 1" 
Committing failed.
Rolled back.
Could not fulfill request: Process returned non-zero exit status: ArtifactCommit: Process exited with status 1
root@raspberrypi4-64:~# mender-update show-artifact; fw_printenv mender_boot_part upgrade_available bootcount
chemify-rpi4-0.2.1
mender_boot_part=3
upgrade_available=0
bootcount=2
root@raspberrypi4-64:~# sha256sum -c /data/secrets.sha256
/dev/mmcblk0p6: OK

[logged in as root on the serial console]

# === POWER CYCLE: power removed and reapplied ===   [2026-11-24 13:06:27]
root@raspberrypi4-64:~# sync
# power removed (3 s)

# power applied   [2026-11-24 13:06:32]
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

root@raspberrypi4-64:~# uptime
 00:10:45 up 0 min,  load average: 0.80, 0.19, 0.06
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part upgrade_available bootcount
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
mender_boot_part=3
upgrade_available=0
bootcount=2
root@raspberrypi4-64:~# mender-update show-artifact
chemify-rpi4-0.2.1
root@raspberrypi4-64:~# sha256sum /dev/mmcblk0p6; sha256sum -c /data/secrets.sha256
2f005bdd7e3ba93d941692340c954d40becc1932e518a68d37ea946a15abe449  /dev/mmcblk0p6
/dev/mmcblk0p6: OK
root@raspberrypi4-64:~# blkid /dev/mmcblk0p6 | wc -l; grep -c mmcblk0p6 /proc/mounts
0
0
```

## Part 2: First boot of the delivered image

```text
# power applied   [2026-11-24 13:08:26]
[... boot output trimmed to key lines ...]
U-Boot 2024.01 (Jan 08 2024 - 15:37:48 +0000)
DRAM:  948 MiB (effective 3.9 GiB)
RPI 4 Model B (0xc03115)
Loading Environment from MMC... *** Warning - bad CRC, using default environment
Starting kernel ...
[    0.000000] Machine model: Raspberry Pi 4 Model B Rev 1.5
[    0.000000] Kernel command line: ... console=ttyS0,115200 ... root=/dev/mmcblk0p2 ...
[    0.000000] Memory: 3351968K/4050944K available (14528K kernel code, 2246K rwdata, 4712K rodata, 5120K init, 1098K bss, 174688K reserved, 524288K cma-reserved)
Poky (Yocto Project Reference Distro) 5.0.15 raspberrypi4-64 ttyS0
[logged in as root on the serial console]

root@raspberrypi4-64:~# mender-update show-artifact
record_id=1 severity=info time="1970-Jan-01 00:00:21.250401" name="Global" msg="Installing the bootstrap Artifact" 
chemify-rpi4-0.2.0
root@raspberrypi4-64:~# mount | grep "on / "; fw_printenv mender_boot_part upgrade_available bootcount
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
mender_boot_part=2
upgrade_available=0
bootcount=1
root@raspberrypi4-64:~# fdisk -l /dev/mmcblk0 | tail -n 7
Device       Boot StartCHS    EndCHS        StartLBA     EndLBA    Sectors  Size Id Type
/dev/mmcblk0p1 *  384,0,1     1023,3,32        49152     253951     204800  100M  c Win95 FAT32 (LBA)
/dev/mmcblk0p2    1023,3,32   1023,3,32       262144    4456447    4194304 2048M 83 Linux
/dev/mmcblk0p3    1023,3,32   1023,3,32      4456448    8650751    4194304 2048M 83 Linux
/dev/mmcblk0p4    1023,3,32   1023,3,32      8667134   12879871    4212738 2057M  f Win95 Ext'd (LBA)
/dev/mmcblk0p5    1023,3,32   1023,3,32      8667136   12861439    4194304 2048M 83 Linux
/dev/mmcblk0p6    1023,3,32   1023,3,32     12877824   12879871       2048 1024K 83 Linux
root@raspberrypi4-64:~# grep mmcblk0 /proc/mounts; grep mmcblk0 /etc/fstab; ls -A /mnt
/dev/mmcblk0p1 /uboot vfat rw,sync,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro 0 0
/dev/mmcblk0p5 /data ext4 rw,relatime 0 0
#/dev/mmcblk0p1       /media/card          auto       defaults,sync,noauto  0  0
/dev/mmcblk0p1       /uboot               auto       defaults,sync         0  2
/dev/mmcblk0p5       /data                auto       defaults              0  2
root@raspberrypi4-64:~# blkid /dev/mmcblk0p6 | wc -l
0
root@raspberrypi4-64:~# while systemctl list-jobs --no-legend | grep -q .; do sleep 5; done; systemctl --failed --no-legend; systemctl is-active mender-authd mender-updated
* systemd-networkd-wait-online.service loaded failed failed Wait for Network to be Configured
active
active
```
