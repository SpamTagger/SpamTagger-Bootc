set ${CI:+-x} -euo pipefail

# /*
### OS Release
# set variant and url for unique identification
# NOTE: if VARIANT/DEFAULT_HOSTNAME is added to CentOS the echos must become seds
# */
sed -i 's|^Name=.*|Name="Cayo"|' /usr/lib/os-release
sed -i "s|^Version=.*|Version=\"$IMAGE_VERSION\"|" /usr/lib/os-release
sed -i 's|^VENDOR_NAME=.*|VENDOR_NAME="Universal Blue"|' /usr/lib/os-release
sed -i 's|^VENDOR_URL=.*|VENDOR_URL="www.universal-blue.org"|' /usr/lib/os-release
sed -i 's|^HOME_URL=.*|HOME_URL="https://projectcayo.org"|' /usr/lib/os-release
sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/ublue-os/cayo/issues"|' /usr/lib/os-release
echo 'DEFAULT_HOSTNAME="cayo"' >>/usr/lib/os-release
echo 'VARIANT="Cayo"' >>/usr/lib/os-release
echo 'VARIANT_ID=cayo' >>/usr/lib/os-release

# /*
# set pretty name for base image
# */
SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
SOURCE_NAME="$(grep ^NAME= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Cayo (Version $IMAGE_VERSION / FROM $SOURCE_NAME $SOURCE_VERSION)\"|" /usr/lib/os-release

# /*
# Divergence from Cayo: Custom kernel (ZFS) dropped. Normally the new kernel signature would be imported here.
# /*

### Configuration
# */

# /*
# Duperemove configuration
# */
cat >/etc/default/duperemove <<'EOF'
HashDir=/var/lib/duperemove
OPTIONS="--skip-zeroes --hash=xxhash"
EOF

# /*
### SYSUSERS.D
# */

# /*
# sysusers for dhcpcd
# */
cat >/usr/lib/sysusers.d/cayo-dhcpcd.conf <<'EOF'
u dhcpcd - "Minimalistic DHCP client" /var/lib/dhcpcd
EOF

# /*
### TMPFILES.D
# */

# /*
# Tmpfiles pcp
# */
cat >/usr/lib/tmpfiles.d/cayo-pcp.conf <<'EOF'
d /var/lib/pcp/config/pmda 0775 pcp pcp -
d /var/lib/pcp/config/pmie 0775 pcp pcp -
d /var/lib/pcp/config/pmlogger 0775 pcp pcp -
d /var/lib/pcp/tmp 0775 pcp pcp -
d /var/lib/pcp/tmp/bash 0775 pcp pcp -
d /var/lib/pcp/tmp/json 0775 pcp pcp -
d /var/lib/pcp/tmp/mmv 0775 pcp pcp -
d /var/lib/pcp/tmp/pmie 0775 pcp pcp -
d /var/lib/pcp/tmp/pmlogger 0775 pcp pcp -
d /var/lib/pcp/tmp/pmproxy 0775 pcp pcp -
d /var/log/pcp 0775 pcp pcp -
d /var/log/pcp/pmcd 0775 pcp pcp -
d /var/log/pcp/pmfind 0775 pcp pcp -
d /var/log/pcp/pmie 0775 pcp pcp -
d /var/log/pcp/pmlogger 0775 pcp pcp -
d /var/log/pcp/pmproxy 0775 pcp pcp -
d /var/log/pcp/sa 0775 pcp pcp -
EOF

# /*
# Tmpfiles duperemove
# */
cat >/usr/lib/tmpfiles.d/cayo-duperemove.conf <<'EOF'
d /var/lib/duperemove - - - -
EOF
