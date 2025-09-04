# /*
#shellcheck disable=SC2174
# */

set -xeuo pipefail

# /*
# Unique SpamTagger actions
# */

sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/SpamTagger/SpamTagger-Plus/issues"|' /usr/lib/os-release
echo 'VARIANT="SpamTagger-Plus"' >>/usr/lib/os-release

# /*
# Clone SpamTagger repo
# */

git clone https://github.com/SpamTagger/SpamTagger-Plus /usr/spamtagger

# /*
# Anaconda installation files
# */

if [ ! -d /etc/anaconda/conf.d ]; then
  mkdir -p /etc/anaconda/conf.d
fi
cp /usr/spamtagger/install/anaconda/conf.d/spamtagger-plus.conf /etc/anaconda/conf.d/

# /*
#if [ ! -d /etc/anaconda/post-scripts ]; then
#mkdir -p /etc/anaconda/post-scripts
#fi
#cp /usr/spamtagger/install/anaconda/post-scripts/spamtagger-plus.ks /etc/anaconda/conf.d/
# */

if [ ! -d /etc/anaconda/profile.d ]; then
  mkdir -p /etc/anaconda/profile.d
fi
cp /usr/spamtagger/install/anaconda/profile.d/spamtagger-plus.conf /etc/anaconda/profile.d/

# /*
# Apply SpamTagger installation to rootfs
# */

cd /usr/spamtagger
PRETTY_NAME="$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)"
cat etc/issue | sed "s/__PRETTY_NAME__/$PRETTY_NAME/" >/etc/issue

# /*
# Set default root password 'STPassw0rd'
# */
sed -i 's/root:[^:]*:/root:$y$j9T$kfLbiAeBa5PuQAZtTqBph1$ufRc85kbALH5Eg.IhtZcoyoDZ92SZfJmdX9p22Qg1D5:/' /etc/shadow
