# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "################################"
echo "# Configuring SpamTagger-Plus..."
echo "################################"
setterm --foreground default

cd /opt/build

setterm --foreground blue
echo "Configuring CPAN..."
setterm --foreground default
mkdir -p /root/.cpan/CPAN
echo '
$CPAN::Config = {
  'build_requires_install_policy' => q[yes],
  'connect_to_internet_ok' => 1,
  'cpan_home' => q[/root/.cpan],
  'gzip' => q[/bin/gzip],
  'tar' => q[/bin/tar --no-same-owner],
  'keep_source_where' => q[/root/.cpan/sources],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'mbuildpl_arg' => q[],
  'mbuild_arg' => q[],
  'mbuild_install_arg' => q[],
  'prefs_dir' => q[/root/.cpan/prefs],
  'urllist' => [q[http://www.cpan.org/]],
  'inactivity_timeout' => 0,
};
1;
__END__' >/root/.cpan/CPAN/MyConfig.pm

setterm --foreground blue
echo "# Installing App::Staticperl and PPI..."
setterm --foreground default
cpanm -n App::Staticperl PPI

setterm --foreground blue
echo "# Cloning SpamTagger and Zend..."
setterm --foreground default
git clone --recurse-submodules --depth=1 https://github.com/SpamTagger/SpamTagger-Plus /usr/spamtagger

setterm --foreground blue
echo "# Cleaning up repo files..."
setterm --foreground default
rm -rf /usr/spamtagger/.git*
mv /usr/spamtagger/www/vendor/Zend /usr/spamtagger/www/vendor/Zend.git
mv /usr/spamtagger/www/vendor/Zend.git/library/Zend /usr/spamtagger/www/vendor/Zend
rm -rf /usr/spamtagger/www/vendor/Zend.git

setterm --foreground blue
echo "# Preparing library directory..."
setterm --foreground default
mkdir -p /opt/staticperl/lib/perl5

# /*
# setterm --foreground blue
# echo "# Adding to default \@INC paths..."
# setterm --foreground default
# echo "use lib '/opt/staticperl/lib/perl5/';" >>"$INSTALL_DIR/lib/perl5/lib.pl"
# echo "use lib '/usr/spamtagger/lib/';" >>"$INSTALL_DIR/lib/perl5/lib.pl"
# */

setterm --foreground blue
echo "# Generating required module list..."
setterm --foreground default
perl /run/build-files/detect-modules.pl /usr/spamtagger >/etc/staticperlrc

setterm --foreground blue
echo "# Creating .staticperlrc..."
setterm --foreground default
# /*
# VERSION=${PERL_VERSION:5:11}
# echo "--with-perl /opt/${PERL_VERSION}/bin/perl" >>/tmp/staticperlrc
# echo "--prefix /opt/staticperl" >>/tmp/staticperlrc
# echo "--libdir /usr/spamtagger/lib" >>/tmp/staticperlrc
# echo "--strip PPI" >>/tmp/staticperlrc
# echo "--no-core-modules" >>/tmp/staticperlrc
# echo "--clean" >>/tmp/staticperlrc
# echo "--verbose" >>/tmp/staticperlrc
# echo "--force" >>/tmp/staticperlrc
echo "--libdir /usr/spamtagger/lib" >>/tmp/staticperlrc
echo "--no-core-modules" >>/tmp/staticperlrc
echo "--clean" >>/tmp/staticperlrc
echo "--verbose" >>/tmp/staticperlrc
echo "--force" >>/tmp/staticperlrc
echo "PERL_VERSION=/opt/${PERL_VERSION}/bin/perl" >>/tmp/staticperlrc
# */

echo "PERL_PREFIX=/opt/staticperl" >>/tmp/staticperlrc
echo "PERL_VERSION=https://mirror.netcologne.de/cpan/src/5.0/${PERL_VERSION}.tar.xz" >>/tmp/staticperlrc
echo "PERL_CCFLAGS=-DPERL_STATIC_INLINE" >>/tmp/staticperl
# /*
# setterm --foreground blue
# echo "Patching Staticperl for root user in container..."
# setterm --foreground default
# sed -i 's/tar xf -/tar xf - --no-same-owner/' $(which staticperl)
# */

setterm --foreground blue
echo "# Building our Perl..."
setterm --foreground default
mv /tmp/staticperlrc /etc/staticperlrc
staticperl mkperl --strip ppi --verbose

find /opt/staticperl
sleep 200

setterm --foreground blue
echo "# Cleaning up staticperl..."
setterm --foreground default
find /opt/staticperl -name '*.packlist' -delete
find /opt/staticperl -name '*.pod' -delete
find /opt/staticperl -name '*.so' -delete
find /opt/staticperl -type d -name '.git' -prune -exec rm -rf {} +
rm -rf /opt/staticperl/lib/perl5/*/pod
rm -rf /opt/staticperl/lib/perl5/*/auto
