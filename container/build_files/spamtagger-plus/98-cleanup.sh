# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "############################"
echo "# Cleaning up application..."
echo "############################"
setterm --foreground default

setterm --foreground blue
echo "# Removing extraneous packages..."
setterm --foreground default
