# /*
#shellcheck disable=SC2174,SC2114
# */

# /*
# This file is a combination of 01-common.sh and centos/02-centos.sh`
# in the Cayo repository, since we aren't building for Fedoar.
# Differences will be noted in comments.
# */

set ${CI:+-x} -euo pipefail

# /*
# See https://github.com/CentOS/centos-bootc/issues/191
# */
mkdir -m 0700 -p /var/roothome

# /*
# make /opt writable
#
# Divergence from Cayo where /usr/local is also writable via /var/usrlocal/
# This breaks deployment in Distrobox since `distrobox-init` throws ane error
# when it tried to `mkdir` at /usr/local, which already exists as a symlink`
# */
mkdir -p /var/opt
rm -rf /opt /usr/local
ln -sf var/opt /opt

# /*
# remove any wifi support and subscription manager
# */
dnf -y remove \
  atheros-firmware \
  brcmfmac-firmware \
  iwlegacy-firmware \
  iwlwifi-dvm-firmware \
  iwlwifi-mvm-firmware \
  mt7xxx-firmware \
  nxpwireless-firmware \
  realtek-firmware \
  tiwilink-firmware \
  libdnf-plugin-subscription-manager \
  python3-subscription-manager-rhsm \
  subscription-manager \
  subscription-manager-rhsm-certificates

# /*
# use CoreOS' generator for emergency/rescue boot
# see detail: https://github.com/ublue-os/main/issues/653
# */
COREOS_SULOGIN_GENERATOR_PATH=/usr/lib/systemd/system-generators/coreos-sulogin-force-generator
curl -fSL -o "${COREOS_SULOGIN_GENERATOR_PATH}" https://raw.githubusercontent.com/coreos/fedora-coreos-config/refs/heads/stable/overlay.d/05core/usr/lib/systemd/system-generators/coreos-sulogin-force-generator
chmod +x "${COREOS_SULOGIN_GENERATOR_PATH}"

# /*
# Zram Generator
# */
cat >/usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
EOF

# /*
# Configure Updates
# */
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

# /*
# enable CRB, EPEL and other repos
# */
dnf config-manager --set-enabled crb
dnf -y install epel-release
dnf -y upgrade epel-release

# /*
# Install Packages
# */
dnf -y --setopt=install_weak_deps=False install \
  python3-dnf-plugin-versionlock \
  systemd-resolved \
  ssh-key-dir

# /*
# Ensure systemd-resolved is enabled
# */
cat >/usr/lib/systemd/system-preset/91-cayo-resolved.preset <<'EOF'
enable systemd-resolved.service
EOF
cat >/usr/lib/tmpfiles.d/cayo-resolved.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF

systemctl preset systemd-resolved.service
