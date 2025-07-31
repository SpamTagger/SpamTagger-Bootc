# /*
#shellcheck disable=SC2174
# */

set -xeuo pipefail

# /*
# Unique SpamTagger actions
# */

sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/SpamTagger/SpamTagger-Plus/issues"|' /usr/lib/os-release
echo 'VARIANT="SpamTagger-Plus"' >>/usr/lib/os-release
