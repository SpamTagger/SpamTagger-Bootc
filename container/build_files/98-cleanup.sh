# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "######################"
echo "# Cleaning up build..."
echo "######################"
setterm --foreground default

setterm --foreground blue
echo "# Bundling $KERNEL_VERSION..."
setterm --foreground default
KERNEL_VERSION="$(rpm -q --queryformat="%{EVR}.%{ARCH}" kernel-core)"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/lib/modules/$KERNEL_VERSION/initramfs.img"
chmod 0600 /lib/modules/"$KERNEL_VERSION"/initramfs.img

setterm --foreground blue
echo "# Removing additional kernels..."
setterm --foreground default
# */
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{EVR}.%{ARCH}')"
kernel_dirs=("$(ls -1 /usr/lib/modules)")
if [[ ${#kernel_dirs[@]} -gt 1 ]]; then
  for kernel_dir in "${kernel_dirs[@]}"; do
    echo "$kernel_dir"
    if [[ "$kernel_dir" != "$KERNEL_VERSION" ]]; then
      echo "Removing $kernel_dir"
      rm -rf "/usr/lib/modules/$kernel_dir"
    fi
  done
fi

setterm --foreground blue
echo "# Removing version locks..."
setterm --foreground default
dnf versionlock clear

setterm --foreground blue
echo "# Removing unnecessary files..."
setterm --foreground default
rm -rf /usr/local
dnf clean all
rm -rf /var/cache/dnf
rm -rf ~/.cpan/build
rm -rf /run/build_files

setterm --foreground blue
echo "# Creating clean /tmp and /var..."
setterm --foreground default
rm -rf /tmp
rm -rf /var
mkdir -m 1777 /tmp
mkdir -m 1777 -p /var/tmp
