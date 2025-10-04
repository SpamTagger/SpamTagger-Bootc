# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

echo "##########################"
echo "# Building our own Perl..."
echo "##########################"

setterm --foreground blue
echo "# Downloading $PERL_VERSION..."
PERL_URL="https://www.cpan.org/src/5.0/${PERL_VERSION}.tar.gz"
setterm --foreground default
mkdir -p /opt/build
cd /opt/build
curl -fsSL "$PERL_URL" -o "$PERL_VERSION.tar.gz"

setterm --foreground blue
echo "# Extracting $PERL_VERSION..."
setterm --foreground default
tar --no-same-owner -xzf "${PERL_VERSION}.tar.gz"
cd ${PERL_VERSION}

setterm --foreground blue
echo "# Configuring $PERL_VERSION..."
setterm --foreground default
./Configure -des -Dprefix=/opt/${PERL_VERSION}

setterm --foreground blue
echo "# Building $PERL_VERSION..."
setterm --foreground default
make -j$(nproc)

setterm --foreground blue
echo "# Installing $PERL_VERSION..."
setterm --foreground default
make install
export PATH="/opt/${PERL_VERSION}:$PATH"
export PERL5LIB=

setterm --foreground blue
echo "# Cleaning up Perl sources and build files..."
setterm --foreground default
cd /
rm -rf ${PERL_VERSION} ${PERL_VERSION}.tar.gz
