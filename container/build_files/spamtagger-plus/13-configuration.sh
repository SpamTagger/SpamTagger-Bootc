# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "################################"
echo "# Configuring SpamTagger-Plus..."
echo "################################"
setterm --foreground default

setterm --foreground blue
echo "# Updating os-release..."
setterm --foreground default
sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/SpamTagger/SpamTagger-Plus/issues"|' /usr/lib/os-release
echo 'VARIANT="SpamTagger-Plus"' >>/usr/lib/os-release

setterm --foreground blue
echo "# Updating /etc/issue..."
setterm --foreground default
PRETTY_NAME="$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)"
cat etc/issue | sed "s/__PRETTY_NAME__/$PRETTY_NAME/" >/etc/issue

setterm --foreground blue
echo "# Setting default password..."
setterm --foreground default
sed -i 's/root:[^:]*:/root:$y$j9T$kfLbiAeBa5PuQAZtTqBph1$ufRc85kbALH5Eg.IhtZcoyoDZ92SZfJmdX9p22Qg1D5:/' /etc/shadow

setterm --foreground blue
echo "# Creating blank configuration file..."
setterm --foreground default
touch /etc/spamtagger.conf

/* TODO: move Anaconda configuration files to this repo instead of the source repo. Get it to actually work... */
setterm --foreground blue
echo "# Applying Anaconda installer configuration..."
setterm --foreground default
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
