set ${CI:+-x} -euo pipefail

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
