set ${CI:+-x} -euo pipefail

# /*
### add ublue-os specific packages
# */

dnf -y copr enable ublue-os/packages
dnf -y install ublue-os-signing
mv /etc/containers/policy.json /etc/containers/policy.json-upstream
mv /usr/etc/containers/policy.json /etc/containers/
rm -fr /usr/etc
sed -i 's/ublue-os/spamtagger/' /etc/containers/policy.json
dnf -y copr disable ublue-os/packages

# /*
# Common SpamTagger / SpamTagger Plus packages
# */

dnf -y install --setopt=install_weak_deps=False \
  firewalld \
  man-db \
  man-pages \
  open-vm-tools \
  qemu-guest-agent \
  systemd-container \
  usbutils \
  wireguard-tools
