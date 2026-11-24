# Changelog

All notable changes to this repository are documented here.

## [0.2.0] - 2026-11-24 (draft)

Change request "secrets partition". **The partition table changed: devices with the 0.1 layout must be
re-written with the 0.2 `.sdimg`; they cannot be updated to 0.2 with a Mender Artifact.**

### Added

- Raw 1 MiB partition `secrets` (`/dev/mmcblk0p6`) for the application's encrypted secrets storage:
  no filesystem, not mounted, not changed by updates (`MENDER_EXTRA_PARTS`, `--fstype=none`).
- Class `meta-chemify-rpi4/classes/mender-raw-extra-parts.bbclass`, which keeps raw extra partitions out
  of `/etc/fstab`.
- Optional kas file `kas/hosted-mender.yml` (server URL and tenant token from the environment) and
  integration guide section 10, "Connecting the device to Hosted Mender".
- Validation report section 8 and Appendix E: validation of the change on hardware (2026-11-24).

### Changed

- Partition layout: MBR with extended partition. p1 boot, p2/p3 rootfs A/B, p4 extended, **p5 data**
  (was p4), **p6 secrets**.
- Fixed sizes for the 7 GB target storage: `MENDER_STORAGE_TOTAL_SIZE_MB = "6288"` (rootfs A/B 2048 MiB
  each, was 376 MiB) and `MENDER_DATA_PART_SIZE_MB = "2048"`. The image is 6296 MiB (6.6 GB, was 1 GiB).
- Default `MENDER_ARTIFACT_NAME` is `chemify-rpi4-0.2.0`.
- Documentation version 0.2.

### Removed

- `mender-growfs-data`: the data partition is no longer enlarged to the end of the card on first boot,
  because the secrets partition follows it.

## [0.1.0] - 2026-11-06 (draft)

### Added

- Build configuration `kas/chemify-rpi4-mender.yml` for the Raspberry Pi 4 Model B (`raspberrypi4-64`),
  Yocto Project Scarthgap (yocto-5.0.15), based on meta-mender-community `kas/raspberrypi4-64.yml`.
- Lock file `kas/chemify-rpi4-mender.lock.yml` with the pinned revisions of all layers.
- Mender Client 6.1 LTS (`mender-update` / `mender-auth` 5.2.0) through meta-mender `scarthgap-v2026.10.02`.
- Layer `meta-chemify-rpi4`:
  - `mender` bbappend installing a temporary development Artifact verification key (RSA 3072).
  - Backport of the `pseudo` 1.9.11 recipe from openembedded-core scarthgap (host `tar` / `openat2()`
    compatibility).
- `mender-prepopulate-inactive-partition` enabled, so that both root filesystems are bootable from the start.
- Development login on the serial console (`root` without password).
- HTTPS URLs for the Yocto Project repositories instead of `git://`.
- Documentation: integration guide, validation report with evidence appendices, production notes.

### Validated

- Mender integration checklist (U-Boot variant), signed Artifact deployment, update with commit, manual
  rollback, and failed update with automatic rollback on a Raspberry Pi 4 Model B (2026-11-06). See
  `docs/02-validation-report.md`.
