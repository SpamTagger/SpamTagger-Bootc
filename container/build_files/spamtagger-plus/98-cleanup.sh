# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "############################"
echo "# Cleaning up application..."
echo "############################"
setterm --foreground default

setterm --foreground blue
echo "# Removing extraneous packages..."
setterm --foreground default
dnf remove -y \
  amd-gpu-firmware \
  amd-ucode-firemware \
  atheros-firmware \
  avahi-libs \
  bash-completion \
  brcmfmac-firmware \
  c-ares \
  checkpolicy \
  cirrus-audio-firmware \
  console-login-helper-messages \
  cryptsetup \
  cyrus-sasl-gssapi \
  dmidecode \
  dosfstools \
  duktape \
  dwz \
  e2fsprogs \
  e2fsprogs-libs \
  epel-release \
  ethtool \
  expatprogs \
  flashrom \
  flatpak-session-helper \
  gawk-all-langpacks \
  gss-proxy \
  hwdata \
  insights-core-selinux \
  intel-audio-firmware \
  intel-gpu-firmware \
  iwlegacy-firmware \
  iwlwifi-dvm-firmware \
  iwlwifi-mvm-firmware \
  jq \
  kpartx \
  lcms2 \
  libdnf-plugin-subscription-manager \
  linux-firmware-whence \
  make \
  man-db \
  man-pages \
  mdadm \
  memstrack \
  microcode_ctl \
  mt7xxx-firmware \
  nxpwireless-firmware \
  nfs-utils \
  nss* \
  nvme-cli \
  ocaml-srpm-macros \
  openblas-srpm-macros \
  package-notes-srpm-macros \
  perl \
  perldoc \
  perl-App-cpanminus \
  perl-FindBin \
  perl-ExtUtils-MakeMaker \
  perl-Log-Log4perl \
  perl-Safe \
  perl-Test-Manifest \
  perl-Test-Pod \
  perl-Test-Pod-Coverage \
  poppler \
  pinentry \
  pkgconf \
  pkgconf-m4 \
  pyproject-srpm-macros \
  python-unversioned-command \
  python3-subscription-manager-rhsm \
  qt6-srpm-macros \
  quota-nls \
  re2c \
  realtek-firmware \
  redhat-rpm-config \
  rpcbind \
  rust-toolset-srpm-macros \
  samba-client-libs \
  samba-common \
  samba-common-libs \
  sequoia-sq \
  socat \
  sos \
  sssd-* \
  sudo-python-plugin \
  tiwilink-firmware \
  toolbox \
  vim-* \
  xxd \
  yggdrasil \
  yggdrasil-worker-package-manager
