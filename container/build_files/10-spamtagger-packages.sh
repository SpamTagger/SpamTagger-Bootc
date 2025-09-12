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

dnf -y install --setopt=install_weak_deps=False --allowerasing \
  bind \
  bogofilter \
  bzip2 \
  clamav \
  clamav-unofficial-sigs \
  cronie \
  crontabs \
  dnsutils \
  exim \
  exim-greylist \
  fail2ban \
  git \
  ipset \
  iputils \
  kbd \
  libspf2 \
  links \
  lsb-release \
  lzma \
  man-pages \
  netpbm \
  openssl \
  openssh \
  openssh-server \
  open-vm-tools \
  perl \
  perl-doc \
  perl-App-cpanminus \
  perl-Authen-Radius \
  perl-BSD-Resource \
  perl-Convert-BinHex \
  perl-Data-Validate-IP \
  perl-Date-Calc \
  perl-DateTime \
  perl-DBD-SQLite \
  perl-DBI \
  perl-Devel-Size \
  perl-File-Touch \
  perl-GeoIP2 \
  perl-IPC-Run \
  perl-IPC-Run3 \
  perl-Mail-DKIM \
  perl-Mail-SPF \
  perl-MailTools \
  perl-Math-Int128 \
  perl-Module-Build \
  perl-Net-CIDR-Lite \
  perl-Net-CIDR \
  perl-Net-DNS \
  perl-Net-HTTP \
  perl-Net-IP \
  perl-Net-SMTP-SSL \
  perl-PerlIO-gzip \
  perl-Proc-ProcessTable \
  perl-Razor-Agent \
  perl-Sys-Hostname \
  perl-Test-Manifest \
  perl-Test-Pod \
  perl-Test-Pod-Coverage \
  perl-URI \
  podman \
  poppler-utils \
  procps \
  python-is-python3 \
  pyzor \
  qemu-guest-agent \
  re2c \
  rrdtool \
  rsyslog \
  spamassassin \
  systemd-container \
  telnet \
  tesseract \
  usbutils \
  vim \
  wget man-db \
  wireguard-tools

# /*
# DCC doesn't have an official package, but is packaged on OBS
# */
OBS_PATH="https://download.opensuse.org/repositories/home:/voegelas/AlmaLinux_10/x86_64/"
VERSION=$(curl $OBS_PATH 2>/dev/null | grep -P 'dcc-[0-9]' | grep -v mirrorlist | sed 's/.*href="\.\/\([^"]*\)".*/\1/')
wget $OBS_PATH$VERSION
rpm -i $VERSION
rm $VERSION

# /*
# GreylistD doesn't have an official package. Investigate built-in greylisting configuration provided by exim-greaylist:
# https://github.com/Exim/exim/wiki/SimpleGreylisting
# Otherwise, greylistd is just a python program, so we can fetch from GitHub and write a simple installer.
# git clone https://github.com/SpamTagger/greylistd
# */

# /*
# missing Apache modules
# libapache2-mpm-itk (or something like (mod_mpm-itx) doesn't exist. Other MPM modules probably exist, but I don't think we actually need to run multilple vhosts, so this is not needed.
# */

# /* missing php modules
# php-imap
# php-mcrypt
# php-xmlrpc (provided by Zend)
# */

# /* Perl packages which are not in the source (probably in MailScanner or SpamAssassin)
# perl-business-isbn
# perl-config-yaml
# perl-Archive-Any-Lite
# perl-Archive-Zip-SimpleZip
# perl-convert-tnef
# perl-data-dump
# perl-data-validate-domain
# perl-digest-hmac
# perl-encode-detect
# perl-extutils-cbuilder
# perl-filesys-df
# perl-html-Parser
# perl-html-tagset
# perl-inline-c
# perl-io-compress
# perl-io-socket-inet6
# perl-io-socket-ssl
# perl-io-string
# perl-io-stringy
# perl-Net-DNS-Resolver-Programmable
# perl-Net-IMAP-Simple
# perl-Net-IMAP-Simple-SSL
# perl-ole-storage-lite
# perl-parse-recdescent
# perl-sendmail-pmilter (should only be required for Milter mode, so not needed)
# perl-sys-sigaction
# */

# /*
# Dependencies for custom Exim package. Test what features are missing from CentOS package before compiling our own.
# libssl3 (now openssl-devel?) \
# libpcre3
# */

# /* Pending acceptance for EPEL 10 https://bodhi.fedoraproject.org/updates/?packages=pwgen
# pwgen
# */

# /* Possibly replaced by perl-Razor-Agent, but would likely need an updated module.
# razor
# */
