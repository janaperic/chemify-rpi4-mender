# Install the Artifact verification (public) key so the Mender client only
# accepts Artifacts signed with the matching private key (SoW R.1.4).
# See https://docs.mender.io/operating-system-updates-yocto-project/build-for-production
# The key in files/ is a TEMPORARY DEVELOPMENT KEY of Northern.tech (private key not delivered).
# Replace it with your own public key before your first build.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://artifact-verify-key.pem"
