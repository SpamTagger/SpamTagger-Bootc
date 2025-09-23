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
echo "# Creating OSTree commit..."
setterm --foreground default
ostree container commit
