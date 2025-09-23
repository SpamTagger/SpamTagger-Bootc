# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "#####################"
echo "# Finalizing image..."
echo "#####################"
setterm --foreground default

setterm --foreground blue
echo "# Creating clean /tmp and /var..."
setterm --foreground default
rm -rf /tmp
rm -rf /var
mkdir -m 1777 /tmp
mkdir -m 1777 -p /var/tmp

setterm --foreground blue
echo "# Creating OSTree commit..."
setterm --foreground default
ostree container commit
