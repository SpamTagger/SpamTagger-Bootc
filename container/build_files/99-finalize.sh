# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "#####################"
echo "# Finalizing image..."
echo "#####################"
setterm --foreground default

# /*
setterm --foreground blue
echo "# Creating OSTree commit..."
setterm --foreground default
ostree container commit
# */

mkdir -p /usr/lib/ostree
printf "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | tee "/usr/lib/ostree/prepare-root.conf"

export OSTREE_SELINUX_ENABLED=0
ostree admin init-fs /
ostree commit --orphan --bootable
