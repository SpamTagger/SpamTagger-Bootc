# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "##########################"
echo "# Building our own Perl..."
echo "##########################"
setterm --foreground default

setterm --foreground blue
echo "Installing CentOS's Perl and build dependencies..."
setterm --foreground default
dnf -y install --setopt=install_weak_deps=False --allowerasing perl make gcc

# /*
# Build arguments
#
# We will use the latest App::Staticperl release, the same version of Perl provided by CentOS and install to /usr/local/bin
# We also need to force the use of the standard 'tar' so that we can use '--no-same-owner' in order to extract as root
# */

STATICPERL_VERSION="1.46"
PERLVERSION=$(dnf list perl | tail -n 1 | sed 's/[^:]*:\([^\-]*\)\-.*/\1/')
PERL_PATH="/usr/local/bin/perl"
PERL_URL="https://mirror.netcologne.de/cpan/src/5.0/perl-${PERLVERSION}.tar.xz"
STATICPERL_URL="https://www.cpan.org/authors/id/M/ML/MLEHMANN/App-Staticperl-$STATICPERL_VERSION.tar.gz"
INSTALL_DIR="/usr/local/bin/"
TAR_BIN="/usr/bin/tar"

setterm --foreground blue
echo "Creating build directory..."
setterm --foreground default
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

setterm --foreground blue
echo "Downloading APP::StaticPerl..."
setterm --foreground default
curl -L "$STATICPERL_URL" -o staticperl.tar.gz

setterm --foreground blue
echo "Extracting tarball..."
setterm --foreground default
$TAR_BIN --no-same-owner -xzf "staticperl.tar.gz"
cd App-Staticperl-$STATICPERL_VERSION

setterm --foreground blue
echo "Building Static Perl..."
setterm --foreground default
perl Makefile.PL

setterm --foreground blue
echo "Preparing library directory..."
setterm --foreground default
mkdir -p $INSTALL_DIR/lib/perl5

setterm --foreground blue
echo "Adding '/usr/spamtagger' to Perl's library path..."
setterm --foreground default
echo "use lib '$INSTALL_DIR/lib/perl5/spamtagger';" >>"$INSTALL_DIR/lib/perl5/lib.pl"

setterm --foreground blue
echo "Running make..."
setterm --foreground default
make

setterm --foreground blue
echo "Running make install..."
setterm --foreground default
make install

setterm --foreground blue
echo "Creating staticperlrc..."
setterm --foreground default
echo "PERL_VERSION=$PERL_URL" >>/tmp/staticperlrc
echo "PERL_PREFIX=$PERL_PATH" >>/tmp/staticperlrc
echo "PERL_LIB=/usr/lib/perl5" >>/tmp/staticperlrc
echo "PERL_ARCHLIB=/usr/lib/perl5/arch" >>/tmp/staticperlrc
echo "PERL_PKGDIR=/usr/share/perl" >>/tmp/staticperlrc

setterm --foreground blue
echo "Patching Staticperl for root user in container..."
setterm --foreground default
sed -i 's/tar xf -/tar xf - --no-same-owner/' $(which staticperl)

setterm --foreground blue
echo "Removing CentOS's Perl..."
setterm --foreground default
dnf remove perl -y

setterm --foreground blue
echo "Build our Perl..."
setterm --foreground default
STATICPERLRC=/tmp/staticperlrc staticperl install --strip ppi

# /*
#echo "Verifying installation..."
#perl -v
# */

setterm --foreground blue
echo "Removing build depedndencies..."
setterm --foreground default
dnf remove -y make gcc
