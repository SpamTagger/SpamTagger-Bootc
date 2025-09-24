# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "################"
echo "# Configuring OS"
echo "################"
setterm --foreground default

# /*
# NOTE: if VARIANT_ID and DEFAULT_HOSTNAME are added to the upstream file, the `echo`s must become `sed`s
# */
setterm --foreground blue
echo "# Configuring os-release..."
setterm --foreground default
sed -i 's|^Name=.*|Name="SpamTagger BootC"|' /usr/lib/os-release
sed -i "s|^Version=.*|Version=\"$IMAGE_VERSION\"|" /usr/lib/os-release
sed -i 's|^VENDOR_NAME=.*|VENDOR_NAME="SpamTagger"|' /usr/lib/os-release
sed -i 's|^VENDOR_URL=.*|VENDOR_URL="spamtagger.org"|' /usr/lib/os-release
sed -i 's|^HOME_URL=.*|HOME_URL="https://spamtagger.org"|' /usr/lib/os-release
echo "DEFAULT_HOSTNAME=\"spamtagger-plus\"" >>/usr/lib/os-release
echo "VARIANT_ID=\"$IMAGE_VERSION\"" >>/usr/lib/os-release
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"SpamTagger (FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release

setterm --foreground blue
echo "# Configuring DCHP client..."
setterm --foreground default
cat >/usr/lib/sysusers.d/cayo-dhcpcd.conf <<'EOF'
u dhcpcd - "Minimalistic DHCP client" /var/lib/dhcpcd
EOF
