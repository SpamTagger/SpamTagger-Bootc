# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

echo "##########################"
echo "# Building our own Perl..."
echo "##########################"

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

setterm --foreground blue
echo "# Finding current stable Perl version..."
setterm --foreground default
PERL_URL_VERSION=$(curl -fsSL "https://www.perl.org/get.html#unix_like" | grep -Eo 'perl-5+\.[0-9][02468]\.[0-9]+' | sort -V | tail -n 1)
PERL_VERSION=${PERL_URL_VERSION#perl-}

setterm --foreground blue
echo "# Downloading Perl v$PERL_VERSION..."
PERL_URL="https://www.cpan.org/src/5.0/${PERL_URL_VERSION}.tar.gz"
setterm --foreground default
mkdir -p /opt/build
cd /opt/build
curl -fsSL "$PERL_URL" -o "$PERL_URL_VERSION.tar.gz"

setterm --foreground blue
echo "# Extracting Perl v$PERL_VERSION..."
setterm --foreground default
tar --no-same-owner -xzf "${PERL_URL_VERSION}.tar.gz"
cd ${PERL_URL_VERSION}

setterm --foreground blue
echo "# Configuring Perl v$PERL_VERSION..."
setterm --foreground default
./Configure -des -Dprefix=/opt/${PERL_URL_VERSION}

setterm --foreground blue
echo "# Building Perl v$PERL_VERSION..."
setterm --foreground default
make -j$(nproc)

setterm --foreground blue
echo "# Installing Perl v$PERL_VERSION..."
setterm --foreground default
make install
export PATH="/opt/${PERL_URL_VERSION}:$PATH"
export PERL5LIB=

setterm --foreground blue
echo "# Cleaning up Perl sources and build files..."
setterm --foreground default
cd /opt/build
rm -rf ${PERL_URL_VERSION} ${PERL_URL_VERSION}.tar.gz
