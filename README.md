# Mender integration for Raspberry Pi 4 Model B (Yocto Project Scarthgap)

Board integration of the [Mender](https://mender.io) over-the-air update client for the Raspberry Pi 4 Model B,
delivered by Northern.tech to Chemify.io under **Workstream A: Board Integration** (deliverables D.1 and D.2).

| | |
|---|---|
| Target | Raspberry Pi 4 Model B (4 GB), 64-bit, `MACHINE = "raspberrypi4-64"` |
| Yocto Project | Scarthgap 5.0 (yocto-5.0.15, Poky reference distribution), image `core-image-minimal` |
| Mender Client | 6.1 LTS (`mender-update` / `mender-auth` 5.2.0), meta-mender `scarthgap-v2026.10.02` |
| Bootloader / kernel | U-Boot 2024.01 / Linux 6.6.63 |
| Update scheme | A/B root filesystem with automatic rollback, persistent data partition, signed Artifacts |

## Quick start

Requirements: a Linux build host with the Yocto Project prerequisites, about 100 GB free disk space, and kas
4.0 (see the [integration guide, section 3](docs/01-integration-guide.md#3-build-host-requirements)).

```bash
git clone <repository URL> chemify-rpi4-mender && cd chemify-rpi4-mender
export KAS_WORK_DIR=$HOME/rpi4-mender-work && mkdir -p "$KAS_WORK_DIR"
kas build kas/chemify-rpi4-mender.yml
cd $KAS_WORK_DIR/build/tmp/deploy/images/raspberrypi4-64
lsblk -o NAME,SIZE,MODEL,TRAN    # identify the SD card, e.g. /dev/sdX
sudo bmaptool copy --bmap core-image-minimal-raspberrypi4-64.sdimg.bmap core-image-minimal-raspberrypi4-64.sdimg /dev/sdX
```

Then boot the Raspberry Pi from the card and log in as `root` on the serial console (115200 8N1, GPIO14/15).
**Writing to the wrong device destroys its data**: check the target device carefully.

## Repository layout

| Path | Content |
|---|---|
| `kas/chemify-rpi4-mender.yml` | Build configuration (based on meta-mender-community `kas/raspberrypi4-64.yml`) |
| `kas/chemify-rpi4-mender.lock.yml` | Pinned revisions of all layers (applied automatically by kas) |
| `meta-chemify-rpi4/` | Integration layer: Artifact verification key (development key), `pseudo` backport |
| `docs/01-integration-guide.md` | How to build, flash, boot, configure and update |
| `docs/02-validation-report.md` | Validation on hardware, requirements traceability, results |
| `docs/03-production-notes.md` | What to change before production use |
| `docs/appendix/` | Evidence: excerpts of the console logs of the validation |
| `CHANGELOG.md` | Changes to this repository |

## Important

This is a **development** configuration: `root` can log in without a password, and the Artifact
verification key is a temporary Northern.tech development key whose private key is not part of this
delivery. **Generate your own signing key pair and replace the verification key before your first build**
([integration guide, section 9.2](docs/01-integration-guide.md#92-signing-keys-and-signing-the-artifact)).
Read [docs/03-production-notes.md](docs/03-production-notes.md) before using it in products.

## Support

Northern.tech: `<Northern.tech contact>`
