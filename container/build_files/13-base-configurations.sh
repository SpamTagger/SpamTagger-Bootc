set ${CI:+-x} -euo pipefail

# /*
### OS Release
# set variant and url for unique identification
# NOTE: if VARIANT/DEFAULT_HOSTNAME is added to CentOS the echos must become seds
# */
sed -i 's|^Name=.*|Name="SpamTagger BootC"|' /usr/lib/os-release
sed -i "s|^Version=.*|Version=\"$IMAGE_VERSION\"|" /usr/lib/os-release
sed -i 's|^VENDOR_NAME=.*|VENDOR_NAME="SpamTagger"|' /usr/lib/os-release
sed -i 's|^VENDOR_URL=.*|VENDOR_URL="spamtagger.org"|' /usr/lib/os-release
sed -i 's|^HOME_URL=.*|HOME_URL="https://spamtagger.org"|' /usr/lib/os-release
echo "DEFAULT_HOSTNAME=\"$IMAGE_VERSION\"" >>/usr/lib/os-release
echo "VARIANT_ID=\"$IMAGE_VERSION\"" >>/usr/lib/os-release

# /*
# set pretty name for base image
# */
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"SpamTagger (FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release

# /*
# Divergence from Cayo: Custom kernel (ZFS) dropped. Normally the new kernel signature would be imported here.
# /*

# /*
# sysusers for dhcpcd
# */
cat >/usr/lib/sysusers.d/cayo-dhcpcd.conf <<'EOF'
u dhcpcd - "Minimalistic DHCP client" /var/lib/dhcpcd
EOF
