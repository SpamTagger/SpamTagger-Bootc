# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "####################################"
echo "# Preparing filesystem for OSTree..."
echo "####################################"
setterm --foreground default

# /*
# See https://github.com/CentOS/centos-bootc/issues/191
# */
setterm --foreground blue
echo "# Symlinking '/var/roothome..."
setterm --foreground default
mkdir -m 0700 -p /var/roothome
rm -rf /root
ln -sf /var/roothome /root

setterm --foreground blue
echo "# Symlinking /var/opt/..."
setterm --foreground default
mkdir -p /var/opt
rm -rf /opt
ln -sf /var/opt /opt

setterm --foreground blue
echo "# Freeing /usr/local..."
setterm --foreground default
rm -rf /usr/local

setterm --foreground blue
echo "# Configuring CoreOS boot recovery..."
setterm --foreground default
COREOS_SULOGIN_GENERATOR_PATH=/usr/lib/systemd/system-generators/coreos-sulogin-force-generator
curl -fSL -o "${COREOS_SULOGIN_GENERATOR_PATH}" https://raw.githubusercontent.com/coreos/fedora-coreos-config/refs/heads/stable/overlay.d/05core/usr/lib/systemd/system-generators/coreos-sulogin-force-generator
chmod +x "${COREOS_SULOGIN_GENERATOR_PATH}"

setterm --foreground blue
echo "# Setting minimum RAM size..."
setterm --foreground default
cat >/usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 4096)
EOF

setterm --foreground blue
echo "# Configuring BootC..."
setterm --foreground default
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

setterm --foreground blue
echo "# Enabling additional repositories..."
setterm --foreground default
dnf -y remove subscription-manager subscription-manager-rhsm-certificates
dnf config-manager --set-enabled crb
dnf -y install epel-release
dnf -y upgrade epel-release

setterm --foreground blue
echo "# Setting up systemd-resolved..."
setterm --foreground default
dnf -y --setopt=install_weak_deps=False install \
  python3-dnf-plugin-versionlock \
  ssh-key-dir \
  systemd-resolved
cat >/usr/lib/systemd/system-preset/91-cayo-resolved.preset <<'EOF'
enable systemd-resolved.service
EOF
cat >/usr/lib/tmpfiles.d/cayo-resolved.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF
systemctl preset systemd-resolved.service
