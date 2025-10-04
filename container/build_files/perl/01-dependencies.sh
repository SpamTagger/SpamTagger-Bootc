# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

echo "#################################"
echo "# Installing Perl dependencies..."
echo "#################################"

echo "Installing Fedora's Perl and build dependencies..."
dnf -y install --setopt=install_weak_deps=False --allowerasing \
  bzip2 \
  curl \
  findutils \
  gcc \
  git \
  gzip \
  make \
  patch \
  perl \
  perl-App-cpanminus \
  tar \
  util-linux \
  xz &&
  dnf clean all
