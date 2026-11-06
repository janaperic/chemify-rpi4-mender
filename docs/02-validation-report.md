# Validation Report: Mender Integration on Raspberry Pi 4 Model B

| | |
|---|---|
| Title | Validation Report: Mender Integration on Raspberry Pi 4 Model B |
| Version | 0.1 (draft) |
| Date | 2026-11-06 |
| Author | Northern.tech |
| Customer | Chemify.io |
| SoW reference | Workstream A: Board Integration (acceptance criteria AC.1) |

## 1. Summary

Northern.tech integrated the Mender Client (Mender Client 6.1 LTS) into a Yocto Project Scarthgap image for
the Raspberry Pi 4 Model B and validated it on target hardware on 2026-11-06.

- The standard Mender integration checklist (U-Boot variant) passed in full (AC.1.1).
- Full A/B root filesystem updates with Mender Artifacts were demonstrated: a successful update with
  commit, a manual rollback, and an update that cannot boot, with automatic fallback to the previous
  version (AC.1.2).
- Signature verification with development keys generated with OpenSSL was demonstrated: the signed Artifact
  was installed; an unsigned Artifact and an Artifact signed with a different key were rejected without
  changing the system (AC.1.3).

Open item: the delivery of this repository to Chemify (D.2), see section 7.

## 2. Test environment

| Item | Description |
|---|---|
| Device under test | Raspberry Pi 4 Model B Rev 1.5, 4 GB RAM (board revision code `0xc03115`) |
| Storage | 16 GB microSD card (14.5 GiB), written with `bmaptool` |
| Power | 5.1 V supply, current limit 3 A, switched remotely. No undervoltage warning occurred in any test |
| Console | Serial console on GPIO14/15, 115200 8N1. All tests were run on this console |
| Network | None: the Ethernet port was not connected (`eth0: NO-CARRIER`, no routes), as recommended by the integration checklist for the manual checks |
| Build host | x86-64, Ubuntu 24.04 LTS, kas 4.0 |
| Software under test | Build of this repository (`kas/chemify-rpi4-mender.yml` with the pinned revisions in `kas/chemify-rpi4-mender.lock.yml`); see the [integration guide, section 2](01-integration-guide.md#2-software-versions) |

Images and Artifacts used:

| Name | Type | Description |
|---|---|---|
| `chemify-rpi4-0.1.0` | SD card image (`.sdimg`) | Default build of this repository |
| `chemify-rpi4-0.1.1` | Mender Artifact | Built with `MENDER_ARTIFACT_NAME=chemify-rpi4-0.1.1`; used in three variants: signed with the development key, unsigned, and signed with a different RSA 3072 key |
| `chemify-rpi4-0.1.2-broken` | Mender Artifact | Root filesystem of 0.1.1 with `/boot/Image` removed, so it cannot boot; validly signed with the development key |

The Artifacts were placed in `/data/test-artifacts/` on the device before the tests. The `mender-updated`
service was stopped after each boot during the update tests, as required for standalone operation.

Test sessions (all on 2026-11-06):

| Session | Purpose | Evidence |
|---|---|---|
| First boot | First boot of `chemify-rpi4-0.1.0` written with the build's block map | [Appendix A](appendix/A-first-boot.md) |
| Session 1, part 1 | Mender integration checklist | [Appendix B](appendix/B-integration-checklist.md) |
| Session 1, part 2 | Signature verification, update with commit, manual rollback | [Appendix C](appendix/C-signed-artifacts-and-updates.md) |
| Session 2 | Failed update with automatic rollback | [Appendix D](appendix/D-failed-update-rollback.md) |

## 3. Requirements traceability

Status values: **Met** (evidence available), **Partially met**, **Not yet verified**, **Not applicable**.

| ID | Requirement / criterion | How it is met | Evidence | Status |
|---|---|---|---|---|
| R.1 | Integrate the Mender client on Raspberry Pi 4 (4 GB RAM, 7 GB available disk space) running Yocto Scarthgap | Yocto Project 5.0.15 (Scarthgap) image with the Mender Client, built from this repository. Validated on a Raspberry Pi 4 Model B with 4 GB RAM. The image needs 1 GiB of storage; the rest of the card is used by the data partition | Appendix A: `RPI 4 Model B (0xc03115)`, `Memory: .../4050944K`, `Poky ... 5.0.15`, services `active`; Appendix B | **Met** |
| R.1.1 | Mender Client version = latest LTS at the start of the integration | Mender Client 6.1 (`mender-update`/`mender-auth` 5.2.0), from meta-mender `scarthgap-v2026.10.02`. Mender's [supported releases](https://docs.mender.io/release-information/supported-releases) page (table "Components and LTS releases", consulted 2026-11-06) lists Mender Client 6.1 (2026-10) as the latest release, with status "Supported"; Mender Client 5.0 is listed as "EOL (since 2026-09)" | Appendix C: `mender-update --version` → `5.2.0`; image manifest (guide section 2.2) | **Met** |
| R.1.2 | Bootloader, kernel and root filesystem configured with the standard Mender A/B layout plus persistent data partition | U-Boot with Mender boot logic; partitions boot / rootfs A / rootfs B / data; data partition persistent and grown to fill the card | Guide section 1.1; Appendix B steps 2-4: `RootfsPartA=/dev/mmcblk0p2`, `RootfsPartB=/dev/mmcblk0p3`, boot from both; Appendix A: `/data` 12.8G | **Met** |
| R.1.3 | Full A/B rootfs updates with automatic rollback on update failure | Rootfs update with a Mender Artifact into the inactive partition, commit; automatic rollback by U-Boot when the new version does not boot | Appendix C (update 0.1.0 → 0.1.1, commit, persists after reboot); Appendix D (`Failed to load '/boot/Image'` → `Bootlimit (1) exceeded. Using altbootcmd.` → previous partition, version 0.1.0) | **Met** |
| R.1.4 | Artifacts signed with the standard Mender signature flow; temporary development keys generated by Northern.tech provisioned on the board | RSA 3072 key pair generated with OpenSSL (commands from the Mender documentation). Artifacts signed with `mender-artifact sign`; public key installed as `/etc/mender/artifact-verify-key.pem` through `meta-chemify-rpi4`, `ArtifactVerifyKey` set in `/etc/mender/mender.conf` | Appendix C.1 (key, `mender-artifact validate`); session 1 start (Appendix B): `mender.conf` with `ArtifactVerifyKey`, key checksum `b1a4f1cb...` on the device | **Met** |
| R.2 | Changes needed to support the board submitted to standard Mender open-source repositories where applicable | No change to Mender's open-source repositories was needed to support the board: the integration uses meta-mender and meta-mender-community unmodified. The only code change, the `pseudo` backport, is already upstream in openembedded-core (yocto-5.0.21). The remaining settings (layer revisions, HTTPS URLs, verification key, development login) are configuration choices of this integration, see section 7.1 | Section 7.1; `meta-chemify-rpi4/README.md` | **Not applicable** |
| AC.1.1 | Successful completion of the standard Mender integration checklist | All checklist steps passed, see section 4 | Appendix B | **Met** |
| AC.1.2 | Demonstrated A/B rootfs update with automatic fallback on failure on target hardware | Successful update with commit and a failed update with automatic fallback, using real Mender Artifacts, see section 5 | Appendices C and D | **Met** |
| AC.1.3 | Verification of signed Artifact deployment on the target board using development keys generated via OpenSSL | Signed Artifact installed; unsigned and wrongly signed Artifacts rejected, see section 5.1 | Appendix C | **Met** |

Assumptions A.1 and A.2 hold: the build uses the standard upstream Yocto Project, meta-raspberrypi and Mender
layers (plus one backported upstream recipe, see the guide, section 3.4.2), and only standard Mender
features were used.

## 4. Mender integration checklist (AC.1.1)

Reference: [Mender integration checklist](https://docs.mender.io/client-installation/integration-checklist),
U-Boot variant. Image `chemify-rpi4-0.1.0`, session 1. Full transcript: [Appendix B](appendix/B-integration-checklist.md).

| Step | Command(s) | Expected | Observed | Result |
|---|---|---|---|---|
| 1. Mender services active and enabled | `systemctl is-active mender-authd mender-updated`; `systemctl is-enabled mender-authd mender-updated` | Both `active` and `enabled` | `active` `active`; `enabled` `enabled`. The services start about 2 minutes after boot when no network is connected (section 6) | Pass |
| 2. Bootloader environment tools present | `which fw_printenv fw_setenv`; `fw_printenv ...`; `fw_setenv` | Tools present and working | `/usr/bin/fw_printenv`, `/usr/bin/fw_setenv`; environment printed (`bootlimit=1`, `mender_boot_part=2`, ...); `fw_setenv` without arguments exits with 0 | Pass |
| 3. Identify A/B partitions | `cat /var/lib/mender/mender.conf`; `mount \| grep 'on / '`; `stat -c "%n dev=%d" /` | Active root partition matches one of `RootfsPartA`/`RootfsPartB` | `RootfsPartA=/dev/mmcblk0p2`, `RootfsPartB=/dev/mmcblk0p3`; `/dev/mmcblk0p2 on /`; device number 45826 = 179:2. Rootfs A active, B inactive | Pass |
| 4a. Switch to the inactive partition | `fw_setenv mender_boot_part 3`; `fw_setenv mender_boot_part_hex 3`; `reboot` | Device boots rootfs B | `/dev/mmcblk0p3 on /` | Pass |
| 4b. Switch back | `fw_setenv mender_boot_part 2`; `fw_setenv mender_boot_part_hex 2`; `reboot` | Device boots rootfs A | `/dev/mmcblk0p2 on /`; `upgrade_available=0`, `bootcount=0` | Pass |
| 5a. Successful update case: start transition | `fw_setenv upgrade_available 1`; `fw_setenv bootcount 0`; switch to partition 3; `reboot` | New partition active, `bootcount=1`, `upgrade_available=1` | `/dev/mmcblk0p3 on /`; `mender_boot_part=3`, `upgrade_available=1`, `bootcount=1` | Pass |
| 5a. Successful update case: end transition | `fw_setenv upgrade_available 0`; `fw_setenv bootcount 0`; `reboot` | Values stable after reboot | `/dev/mmcblk0p3 on /`; `mender_boot_part=3`, `upgrade_available=0`, `bootcount=0` | Pass |
| 5b. Failed update case | Start transition to the inactive partition (now 2); break its kernel: `mount /dev/mmcblk0p2 /mnt/inactive`, `mv /mnt/inactive/boot/Image /mnt/inactive/boot/Image.backup`, `umount`; `reboot` | Bootloader rolls back: original partition active, `upgrade_available=0` | Console: `Failed to load '/boot/Image'`, `resetting ...`, `Warning: Bootlimit (1) exceeded. Using altbootcmd.`; then `/dev/mmcblk0p3 on /`, `mender_boot_part=3`, `upgrade_available=0`, `bootcount=2` | Pass |
| 5b. Restore the kernel | `mount /dev/mmcblk0p2 /mnt/inactive`; `mv /mnt/inactive/boot/Image.backup /mnt/inactive/boot/Image`; `umount` | Kernel restored | `Image -> Image-6.6.63-v8` | Pass |
| Final state | Switch to partition 2, `reboot` | Device back on rootfs A, restored kernel boots | `/dev/mmcblk0p2 on /`; `/boot/Image -> Image-6.6.63-v8`; `upgrade_available=0` | Pass |

Clarifications:

- **Kernel file.** The checklist refers to a kernel file named `vmlinuz-*`. On this board, U-Boot loads the
  kernel from `/boot/Image` inside the root filesystem partition (a symbolic link to `Image-6.6.63-v8`), so
  this file was renamed in step 5b.
- **How the rollback was triggered.** With the kernel missing, U-Boot cannot load it and, because an update
  is in progress (`upgrade_available=1`), resets the board (`mender_try_to_recover`). On the next start
  `bootcount` exceeds `bootlimit=1`, and U-Boot runs `altbootcmd`, which switches back to the previous
  partition and clears `upgrade_available`. This matches the checklist's description: the rollback is
  caused by the second, unplanned boot during the transition.
- **Restoring the kernel.** The checklist's restore snippet repeats the rename used to break the kernel. The
  kernel was restored by renaming it back (`Image.backup` → `Image`), and the restored partition was then
  booted successfully.
- **Final state.** The device was left on rootfs A (partition 2) with both root filesystems bootable.

## 5. Update tests with Mender Artifacts (AC.1.2, AC.1.3)

### 5.1 Signature verification (AC.1.3, R.1.4)

On the build host, `mender-artifact validate` with the development public key accepts the signed Artifacts
and rejects the others (`missing signature`, `crypto/rsa: verification error`, exit code 5). On the device
(`mender-updated` stopped):

| Test | Command | Expected | Observed | Result |
|---|---|---|---|---|
| Unsigned Artifact | `mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-unsigned.mender` | Rejected, system unchanged | `Signature verification Error: expecting signed artifact, but no signature file found`, `System not modified.`, exit code 1 | Pass |
| Artifact signed with a different key | `mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-wrongkey.mender` | Rejected, system unchanged | `Signature verification Error: Wrong manifest signature or wrong key`, `System not modified.`, exit code 1 | Pass |
| System unchanged | `mender-update show-artifact`; `fw_printenv ...` | Still 0.1.0, no update pending | `chemify-rpi4-0.1.0`; `mender_boot_part=2`, `upgrade_available=0` | Pass |
| Signed Artifact | `mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-signed.mender` | Accepted and installed | `Installed, but not committed.`; `mender_boot_part=3`, `upgrade_available=1` | Pass |

### 5.2 Manual rollback before commit

| Step | Command | Observed | Result |
|---|---|---|---|
| Boot the installed update | `reboot` | `/dev/mmcblk0p3 on /`; `upgrade_available=1`, `bootcount=1` | Pass |
| Roll back | `mender-update rollback` | `Rolled back.`; `mender_boot_part=2`, `upgrade_available=0` | Pass |
| Boot the previous version | `reboot` | `/dev/mmcblk0p2 on /`; `mender-update show-artifact` → `chemify-rpi4-0.1.0` | Pass |

### 5.3 Successful update with commit (AC.1.2)

| Step | Command | Observed | Result |
|---|---|---|---|
| Install | `mender-update install /data/test-artifacts/chemify-rpi4-0.1.1-signed.mender` | `Installed, but not committed.`; `mender_boot_part=3`, `upgrade_available=1` | Pass |
| Boot the new version | `reboot` | `/dev/mmcblk0p3 on /`; `upgrade_available=1`, `bootcount=1` | Pass |
| Commit | `mender-update commit` | `Committed.`; `mender-update show-artifact` → `chemify-rpi4-0.1.1`; `upgrade_available=0` | Pass |
| Persistence | `reboot` | `/dev/mmcblk0p3 on /`; `chemify-rpi4-0.1.1`; `upgrade_available=0`; services `active` | Pass |

### 5.4 Failed update with automatic rollback (AC.1.2)

Session 2, on a newly written SD card with `chemify-rpi4-0.1.0`. Full transcript:
[Appendix D](appendix/D-failed-update-rollback.md).

| Step | Command | Observed | Result |
|---|---|---|---|
| Starting point | `mount \| grep 'on / '`; `mender-update show-artifact` | `/dev/mmcblk0p3 on /` (see note below); `chemify-rpi4-0.1.0` | Pass |
| Install an update that cannot boot | `mender-update install /data/test-artifacts/chemify-rpi4-0.1.2-broken-signed.mender` | Signature accepted, `Installed, but not committed.`; `mender_boot_part=2`, `upgrade_available=1` | Pass |
| Reboot | `reboot` | Console: `Failed to load '/boot/Image'`, `resetting ...`, `Warning: Bootlimit (1) exceeded. Using altbootcmd.`, then the previous version boots | Pass |
| State after automatic rollback | `mount ...`; `fw_printenv ...`; `mender-update show-artifact` | `/dev/mmcblk0p3 on /`; `mender_boot_part=3`, `upgrade_available=0`; `chemify-rpi4-0.1.0` | Pass |
| Client refuses to commit | `mender-update commit` | `Upgrade failed and was reverted: refusing to commit!`, `Committing failed.`, `Rolled back.`; version still `chemify-rpi4-0.1.0` | Pass |

Note: the SD card for session 2 kept the U-Boot environment from session 1 (see section 6), so the device
started on rootfs B. The update was therefore written to rootfs A, and the automatic rollback returned to
rootfs B. This is the same scenario with the roles of A and B swapped.

## 6. Observations

| # | Observation | Assessment |
|---|---|---|
| 1 | Without a network connection, `mender-authd` and `mender-updated` start about 2 minutes after boot: both units are ordered after `network-online.target`, and `systemd-networkd-wait-online.service` waits for its timeout and then fails. `systemctl is-system-running` reports `degraded` because of that unit | Expected behaviour without a network. See the production notes for offline devices |
| 2 | With the default meta-mender configuration, the `.sdimg` leaves rootfs B empty (only `lost+found`) until the first update. The bootloader checks of the integration checklist cannot switch to an empty partition | `mender-prepopulate-inactive-partition` is enabled in this configuration; optional for production |
| 3 | The device clock starts at 1970-01-01 on every boot (no real-time clock, no network time) | No impact on the tests. Time synchronisation is needed for production (TLS) |
| 4 | Root filesystem updates do not update the device tree, overlays, firmware or `config.txt` on the boot partition (the device tree used is the one loaded by the Raspberry Pi firmware) | Known limitation of the Raspberry Pi integration; see the production notes |
| 5 | To place the test Artifacts on the device, the SD cards for sessions 1 and 2 were prepared by adding the files to the data partition of the image. As a side effect, these cards kept the U-Boot environment of the previous session (U-Boot itself was identical). The delivered image, written with the block map produced by the build, starts with a clean default environment and boots rootfs A (Appendix A) | Test-setup detail; does not affect the results. Documented in the guide's troubleshooting section |
| 6 | No undervoltage warnings and no hangs of the device occurred; every reboot completed without manual intervention | |

## 7. Open items

### 7.1 R.2: upstream submissions

R.2 is not applicable to this integration: no change to Mender's open-source repositories was needed to
support the Raspberry Pi 4. For information, `kas/chemify-rpi4-mender.yml` overrides three settings of the
meta-mender-community scarthgap base configuration (`kas/include/mender-base.yml`):

1. meta-mender `scarthgap-v2026.10.02` (Mender Client 6.1 LTS) instead of `scarthgap-v2025.11` (Mender Client
   5.0, end of life since 2026-09).
2. `https://` instead of `git://` repository URLs (guide, section 3.4.3).
3. The base configuration's yocto-5.0.15 pins are kept; the `pseudo` backport in `meta-chemify-rpi4` makes
   them build on current Ubuntu 24.04 hosts (guide, section 3.4.2). Moving to yocto-5.0.21 or later makes
   the backport unnecessary (production notes, section 9).

### 7.2 D.2: delivery of the repository

This repository is delivered to Chemify through a GitHub repository shared with Chemify:
`<repository URL>`.

> TODO (pending validation): record the repository URL above and confirm that Chemify has access.

### 7.3 Signing keys

The development key pair was generated by Northern.tech for validation only (R.1.4). Its private key is
not part of this delivery and is not handed over. Chemify generates its own key pair and replaces the
development public key in `meta-chemify-rpi4` before building images for its devices (integration guide,
section 9.2; production notes, section 3).

## 8. Evidence index

| Appendix | Content |
|---|---|
| [A: First boot](appendix/A-first-boot.md) | First boot of the delivered image: board, memory, U-Boot default environment, rootfs A, services, data partition |
| [B: Integration checklist](appendix/B-integration-checklist.md) | Complete checklist session (session 1, part 1) |
| [C: Signed Artifacts and updates](appendix/C-signed-artifacts-and-updates.md) | Key and Artifact verification on the build host; signature rejection, manual rollback, update with commit on the device |
| [D: Failed update with automatic rollback](appendix/D-failed-update-rollback.md) | Session 2 |
