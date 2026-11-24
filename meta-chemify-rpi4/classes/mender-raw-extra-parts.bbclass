# Keep raw (unformatted) Mender extra partitions out of /etc/fstab.
#
# meta-mender writes an /etc/fstab entry and creates a mount directory for every
# partition in MENDER_EXTRA_PARTS. A raw partition (for example one that the
# application formats and opens itself as an encrypted container) must not be
# mounted at boot, so this class removes that entry and the empty mount directory
# again, after meta-mender has written them.
#
# Usage (image recipes, e.g. through IMAGE_CLASSES):
#   IMAGE_CLASSES += "mender-raw-extra-parts"
#   MENDER_RAW_EXTRA_PARTS = "secrets"
#
# Each name in MENDER_RAW_EXTRA_PARTS must also be listed in MENDER_EXTRA_PARTS and
# have a MENDER_EXTRA_PARTS_MOUNT_LOCATIONS[<name>] entry (meta-mender identifies the
# fstab line by it).

MENDER_RAW_EXTRA_PARTS ??= ""

def mender_raw_extra_parts_mounts(d):
    extra = (d.getVar('MENDER_EXTRA_PARTS') or "").split()
    mounts = []
    for part in (d.getVar('MENDER_RAW_EXTRA_PARTS') or "").split():
        if part not in extra:
            bb.fatal("MENDER_RAW_EXTRA_PARTS: '%s' is not listed in MENDER_EXTRA_PARTS" % part)
        mount = (d.getVarFlag('MENDER_EXTRA_PARTS_MOUNT_LOCATIONS', part) or "").strip()
        if not mount.startswith('/') or mount == '/':
            bb.fatal("MENDER_RAW_EXTRA_PARTS: set MENDER_EXTRA_PARTS_MOUNT_LOCATIONS[%s] to an absolute path" % part)
        mounts.append(mount)
    return ' '.join(mounts)

# :append, so that it runs after meta-mender's mender_update_fstab_file.
ROOTFS_POSTPROCESS_COMMAND:append = " mender_raw_extra_parts_fstab_cleanup"

mender_raw_extra_parts_fstab_cleanup() {
    fstab=${IMAGE_ROOTFS}${sysconfdir}/fstab
    for mnt in ${@mender_raw_extra_parts_mounts(d)}; do
        if ! awk -v m="$mnt" '$2 == m { found = 1 } END { exit !found }' $fstab; then
            bbfatal "No /etc/fstab entry for raw extra partition mount location $mnt"
        fi
        awk -v m="$mnt" '$2 != m' $fstab > $fstab.tmp
        cat $fstab.tmp > $fstab
        rm -f $fstab.tmp
        rmdir ${IMAGE_ROOTFS}$mnt
    done
    # meta-mender writes the extra partition entries after the data partition entry;
    # fail if an entry for a raw partition device is still present.
    for dev in ${@' '.join('%s%d' % (d.getVar('MENDER_STORAGE_DEVICE_BASE'), mender_get_extra_parts_offset_by_id(d, p)) for p in (d.getVar('MENDER_RAW_EXTRA_PARTS') or '').split())}; do
        if awk -v p="$dev" '$1 == p { found = 1 } END { exit !found }' $fstab; then
            bbfatal "/etc/fstab still contains an entry for raw extra partition $dev"
        fi
    done
}
