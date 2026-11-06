# Appendix A: First boot of the delivered image

| | |
|---|---|
| Title | Appendix A to the Validation Report: First boot of the delivered image |
| Version | 0.1 (draft) |
| Date | 2026-11-06 (date of test: 2026-11-06) |
| Author | Northern.tech |
| Customer | Chemify.io |
| SoW reference | Workstream A: Board Integration (evidence for AC.1) |
| Device | Raspberry Pi 4 Model B Rev 1.5 (4 GB), serial console 115200 8N1 |
| Software | Image `chemify-rpi4-0.1.0` (Mender Client 6.1 LTS: mender-update / mender-auth 5.2.0), written with `bmaptool` and the `.sdimg.bmap` produced by the build |

First power-on of a freshly written SD card. U-Boot starts with its built-in default environment (no environment stored on a new card yet), boots rootfs A (`/dev/mmcblk0p2`), the Mender services start once `systemd-networkd-wait-online` has timed out (no network), and the data partition has been grown to fill the card.

Notes on the format: the excerpt is a transcript of the serial console. Each command is shown after a
`root@raspberrypi4-64:~#` prompt. Boot output is trimmed to the relevant U-Boot and kernel lines, the
board's MAC address and serial number are redacted, and lines starting with `#` are section markers
added for readability. The device has no real-time clock and no network, so timestamps inside
Mender log lines show 1970.

```text
# power applied   [2026-11-06 14:00:09]
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

root@raspberrypi4-64:~# mount | grep 'on / '
/dev/mmcblk0p2 on / type ext4 (rw,relatime)
root@raspberrypi4-64:~# mender-update show-artifact
record_id=1 severity=info time="1970-Jan-01 00:00:33.485960" name="Global" msg="Installing the bootstrap Artifact" 
chemify-rpi4-0.1.0
root@raspberrypi4-64:~# fw_printenv mender_boot_part mender_boot_part_hex upgrade_available bootcount bootlimit
mender_boot_part=2
mender_boot_part_hex=2
upgrade_available=0
bootcount=1
bootlimit=1
root@raspberrypi4-64:~# while systemctl list-jobs --no-legend | grep -q .; do sleep 5; done; systemctl is-active mender-authd mender-updated; systemctl is-enabled mender-authd mender-updated
active
active
enabled
enabled
root@raspberrypi4-64:~# df -h /data | tail -n 1
/dev/mmcblk0p4           12.8G     68.0K     12.2G   0% /data
root@raspberrypi4-64:~# ip route; ip addr show eth0 | head -n 1
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq qlen 1000
```
