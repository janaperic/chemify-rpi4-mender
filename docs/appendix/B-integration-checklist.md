# Appendix B: Mender integration checklist (U-Boot)

| | |
|---|---|
| Title | Appendix B to the Validation Report: Mender integration checklist (U-Boot) |
| Version | 0.1 (draft) |
| Date | 2026-11-06 (date of test: 2026-11-06) |
| Author | Northern.tech |
| Customer | Chemify.io |
| SoW reference | Workstream A: Board Integration (evidence for AC.1) |
| Device | Raspberry Pi 4 Model B Rev 1.5 (4 GB), serial console 115200 8N1 |
| Software | Image `chemify-rpi4-0.1.0` (Mender Client 6.1 LTS) |

Session 1, part 1: all steps of the [Mender integration checklist](https://docs.mender.io/client-installation/integration-checklist), U-Boot variant, in the order of the checklist. See section 3 of the validation report for the step-by-step evaluation.

Notes on the format: the excerpt is a transcript of the serial console. Each command is shown after a
`root@raspberrypi4-64:~#` prompt. Boot output is trimmed to the relevant U-Boot and kernel lines, the
board's MAC address and serial number are redacted, and lines starting with `#` are section markers
added for readability. The device has no real-time clock and no network, so timestamps inside
Mender log lines show 1970.

```text
# power applied   [2026-11-06 13:32:09]
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


# === SESSION 1: image chemify-rpi4-0.1.0 (Mender Client 6.1 LTS) ===   [2026-11-06 13:32:52]
root@raspberrypi4-64:~# head -n 3 /etc/os-release; uname -r
ID=poky
NAME="Poky (Yocto Project Reference Distro)"
VERSION="5.0.15 (scarthgap)"
6.6.63-v8
root@raspberrypi4-64:~# mender-update --version; mender-auth --version
5.2.0
5.2.0
root@raspberrypi4-64:~# mender-update show-artifact
record_id=1 severity=info time="1970-Jan-01 00:01:07.061229" name="Global" msg="Installing the bootstrap Artifact" 
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# cat /etc/mender/mender.conf
{
    "ArtifactVerifyKey": "/etc/mender/artifact-verify-key.pem",
    "InventoryPollIntervalSeconds": 28800,
    "RetryPollIntervalSeconds": 300,
    "ServerURL": "https://docker.mender.io",
    "TenantToken": "dummy",
    "UpdatePollIntervalSeconds": 1800
root@raspberrypi4-64:~# ls -l /etc/mender/artifact-verify-key.pem; sha256sum /etc/mender/artifact-verify-key.pem
-r--r--r--    1 root     root           625 Mar  9  2018 /etc/mender/artifact-verify-key.pem
b1a4f1cb6e325d56371956004036a1e041d14c13ef7b38e31dc0758433b905b8  /etc/mender/artifact-verify-key.pem
root@raspberrypi4-64:~# ls -l /data/test-artifacts/
-rw-r--r--    1 root     root      36540416 Nov  6  2026 chemify-rpi4-0.1.1-signed.mender
-rw-r--r--    1 root     root      36539392 Nov  6  2026 chemify-rpi4-0.1.1-unsigned.mender
-rw-r--r--    1 root     root      36540416 Nov  6  2026 chemify-rpi4-0.1.1-wrongkey.mender
root@raspberrypi4-64:~# ip route; ip addr show eth0 | head -n 1
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq qlen 1000

# === CHECKLIST 1: services ===   [2026-11-06 13:33:39]
root@raspberrypi4-64:~# while systemctl list-jobs --no-legend | grep -q .; do sleep 5; done; uptime
 00:02:10 up 2 min,  load average: 1.40, 0.79, 0.30
root@raspberrypi4-64:~# systemctl is-active mender-authd mender-updated
active
active
root@raspberrypi4-64:~# systemctl is-enabled mender-authd mender-updated
enabled
enabled
root@raspberrypi4-64:~# systemctl --failed --no-legend
* systemd-networkd-wait-online.service loaded failed failed Wait for Network to be Configured

# === CHECKLIST 2: env tools ===   [2026-11-06 13:34:31]
root@raspberrypi4-64:~# which fw_printenv fw_setenv
/usr/bin/fw_printenv
/usr/bin/fw_setenv
root@raspberrypi4-64:~# fw_printenv bootlimit bootcount upgrade_available mender_boot_part mender_boot_part_hex mender_kernel_name altbootcmd
bootlimit=1
bootcount=0
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

# === CHECKLIST 3: partitions ===   [2026-11-06 13:34:32]
root@raspberrypi4-64:~# cat /var/lib/mender/mender.conf
{
    "RootfsPartA": "/dev/mmcblk0p2",
    "RootfsPartB": "/dev/mmcblk0p3"
root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# stat -c "%n dev=%d" /
/ dev=45826

# === CHECKLIST 4: switch to B ===   [2026-11-06 13:34:32]
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)

# === CHECKLIST 4: switch back to A ===   [2026-11-06 13:35:33]
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=0

# === CHECKLIST 5a: successful update case ===   [2026-11-06 13:36:25]
root@raspberrypi4-64:~# mount | grep 'on / '
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=0

# === CHECKLIST 5b: failed update / rollback case ===   [2026-11-06 13:37:44]
root@raspberrypi4-64:~# mount | grep 'on / '
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p3 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=3
mender_boot_part_hex=3
upgrade_available=0
bootcount=2

# === CHECKLIST 5b: restore kernel (reverse rename) ===   [2026-11-06 13:38:30]
root@raspberrypi4-64:~# mount /dev/mmcblk0p2 /mnt/inactive && mv /mnt/inactive/boot/Image.backup /mnt/inactive/boot/Image && ls -l /mnt/inactive/boot/ | grep Image; umount /mnt/inactive; sync
lrwxrwxrwx    1 root     root            15 Mar  9  2018 Image -> Image-6.6.63-v8
-rw-r--r--    1 root     root      27400704 Mar  9  2018 Image-6.6.63-v8

# === verify restore: boot partition A ===   [2026-11-06 13:38:31]
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# ls -l /boot/Image
lrwxrwxrwx    1 root     root            15 Mar  9  2018 /boot/Image -> Image-6.6.63-v8
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=0
```
