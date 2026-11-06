# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

### Added

- Optional kas file `kas/hosted-mender.yml` (server URL and tenant token from the environment) and
  integration guide section 10, "Connecting the device to Hosted Mender".

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
