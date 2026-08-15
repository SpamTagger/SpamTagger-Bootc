# vim: set ts=4 sw=4 expandtab :
set unstable := true
set shell:= ["bash", "-c"]

just := just_executable()
podman := require('podman')
podman-remote := which('podman-remote') || podman + ' --remote'
builddir := shell('mkdir -p $1 && echo $1', absolute_path(env('SPAMTAGGER_BUILD', 'build')))
image := "spamtagger-bootc"
variant := env('SPAMTAGGER_VARIANT', shell('yq ".defaults.variant" images.yaml'))
version := env('SPAMTAGGER_VERSION', shell('yq ".defaults.version" images.yaml'))
app_repo := env('APP_REPO', "https://github.com/SpamTagger/$variant")
selinux := path_exists('/sys/fs/selinux')

# Source Images

rechunker := shell("yq '.images.rechunker.source' images.yaml")
bootc-image-builder := shell("yq '.images[\"bootc-image-builder\"].source' images.yaml")
qemu := shell("yq '.images[\"qemu\"].source' images.yaml")

_default:
    @just --list --unsorted

[private]
PRIVKEY := env('HOME') / '.local/share/containers/podman/machine/machine'
[private]
PUBKEY := PRIVKEY + '.pub'
[private]
default-inputs := '
: ${variant:=' + variant + '}
: ${version:=' + version + '}
'
[private]
get-names := just + ' check-valid-image $variant $version
function image-get() {
    if [ -z "$1" ]; then
      echo "image-get: requires a key argument"
      exit 1
    fi
    if [ "$1" = "cppFlags" ]; then
      echo $(IFS="" yq -Mr ".images[\"spamtagger-bootc-${variant}-${version}\"][\"$1\"][]?" images.yaml)
    else
      echo $(IFS="" yq -Mr ".images[\"spamtagger-bootc-${variant}-${version}\"][\"$1\"]" images.yaml)
    fi
}
source_image="$(image-get source)"
image_org="$(image-get org)"
image_registry="$(image-get registry)"
image_repo="$(image-get repo)"
image_name="$(image-get name)"
image_upstream="$(image-get upstream)"
image_version="$(image-get version)"
image_release="$(image-get release)"
image_codename="$(image-get codename)"
exim_version="$(image-get exim)"
image_description="$(image-get description)"
image_is_default="$(image-get default)"
image_product="$(image-get product)"
if [ "true" != "${image_is_default}" ]; then
    image_is_default=false
fi
image_tag="$image_product-$image_version"
'

[private]
build-missing := '
cmd="' + just + ' build $variant $version"
if ! ' + podman + ' image exists "localhost/$image_name:$image_tag"; then
    echo "' + style('warning') + 'Warning' + NORMAL + ': Container Does Not Exist..." >&2
    echo "' + style('warning') + 'Will Run' + NORMAL + ': ' + style('command') + '$cmd' + NORMAL + '" >&2
    seconds=5
    while [ $seconds -gt 0 ]; do
        printf "\rTime remaining: ' + style('error') + '%d' + NORMAL + ' seconds to cancel" $seconds >&2
        sleep 1
        (( seconds-- ))
    done
    echo "" >&2
    echo "' + style('warning') + 'Running' + NORMAL + ': ' + style('command') + '$cmd' + NORMAL + '" >&2
    $cmd
fi
'
[private]
logsum := '''
log_sum() { echo "$1" >> ${GITHUB_STEP_SUMMARY:-/dev/stdout}; }
log_sum "# Push to GHCR result"
log_sum "\`\`\`"
'''

[group('Utility')]
check-valid-image $variant="" $version="":
    #!/usr/bin/env bash
    set -e
    {{ default-inputs }}
    data=$(IFS='' yq -Mr ".images[\"{{ image }}-$variant-$version\"]" images.yaml)
    if [[ "null" == "$data" ]]; then
        echo "ERROR Invalid inputs: no matching image definition found for: {{ image }}-${variant}-${version}"
        exit 1
    fi

[group('Utility')]
gen-tags $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ get-names }}
    set ${CI:+-x} -eou pipefail

    # Generate Timestamp with incrementing version point
    TIMESTAMP="$(date +%Y%m%d)"
    LIST_TAGS="$(mktemp)"
    while [[ ! -s "$LIST_TAGS" ]]; do
       skopeo list-tags docker://$image_registry/$image_org/$image_name > "$LIST_TAGS"
    done
    if [[ $(cat "$LIST_TAGS" | jq "any(.Tags[]; contains(\"$variant-$version.$TIMESTAMP\"))") == "true" ]]; then
       POINT="1"
       while $(cat "$LIST_TAGS" | jq -e "any(.Tags[]; contains(\"$variant-$version-$TIMESTAMP.$POINT\"))")
       do
           (( POINT++ ))
       done
    fi

    if [[ -n "${POINT:-}" ]]; then
        TIMESTAMP="$TIMESTAMP.$POINT"
    fi

    SHA_SHORT="$(git rev-parse --short HEAD)"
    TAGS=()
    for t in $image_version $image_codename $image_release; do
        if [[ -n "{{ env('GITHUB_PR_NUMBER', '') }}" ]]; then
            TAGS+=("${t}-pr-{{ env('GITHUB_PR_NUMBER', '') }}")
        else
            TAGS+=("${t}")
            TAGS+=("${t}-$SHA_SHORT")
            TAGS+=("${t}.$TIMESTAMP")
        fi
    done
    declare -A output
    output["TAGS"]="${TAGS[*]}"
    output["TIMESTAMP"]="$TIMESTAMP"
    echo "${output[@]@K}"

# Run a Container

alias run := run-container

# Run Container Image
[group('Container')]
[no-exit-message]
run-container $variant="" $version="":
    #!/usr/bin/env bash
    set -eou pipefail
    {{ default-inputs }}
    {{ get-names }}
    {{ build-missing }}
    echo "{{ style('warning') }}Running:{{ NORMAL }} {{ style('command') }}{{ just }} run -it --rm localhost/$image_name:$image_tag bash -l {{ NORMAL }}"
    {{ podman }} run -it --rm "localhost/$image_name:$image_tag" bash -l

# Build a Container

alias build := build-container

# Build Container Image
[group('Container')]
build-container $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ just }} check-valid-image $variant $version
    {{ get-names }}
    mkdir -p {{ builddir / '$variant-$version' }}
    set ${CI:+-x} -eou pipefail
    # Verify Source: do after upstream starts signing images

    # Tags
    declare -A gen_tags="($({{ just }} gen-tags $variant $version))"
    tags=(${gen_tags["TAGS"]})
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"
    TAGS=()
    for tag in "${tags[@]}"; do
        TAGS+=("--tag" "localhost/$image_name:$variant-$tag")
    done

    # OSTree Labels
    IMAGE_VERSION="$image_version.$TIMESTAMP"
    LABELS=(
        "--label" "containers.bootc=1"
        "--label" "io.artifacthub.package.deprecated=false"
        "--label" "io.artifacthub.package.keywords=bootc,debian"
        "--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/205223896?s=200&v=4"
        "--label" "io.artifacthub.package.maintainers=[{\"name\": \"JohnMertz\", \"email\": \"git@john.me.tz\"}]"
        "--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/$image_registry/$image_org/$image_repo/main/README.md"
        "--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)"
        "--label" "org.opencontainers.image.description=$image_description"
        "--label" "org.opencontainers.image.license=GPLv3"
        "--label" "org.opencontainers.image.source=https://raw.githubusercontent.com/$image_org/$image_repo/refs/heads/main/Containerfile.in"
        "--label" "org.opencontainers.image.title=\"$variant $version\""
        "--label" "org.opencontainers.image.url=https://github.com/$image_org/$image_repo"
        "--label" "org.opencontainers.image.vendor=$image_org"
        "--label" "org.opencontainers.image.version=${IMAGE_VERSION}"
    )

    # Hypothetically provide support for other architectures supported by Debian*/
    # NOTE: Currently DCC only supports amd64 and arm64
    ARCH=$(arch)
    [[ "$ARCH" == "aarch64" ]] && ARCH=arm64
    [[ "$ARCH" == "armv7l" ]] && ARCH=armhf
    [[ "$ARCH" == "x86_64" ]] && ARCH=amd64
    [[ "$ARCH" == "ppc64le" ]] && ARCH=ppc64el
    # riscv64 and s390x map directly

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        "--cpp-flag=-DIMAGE_VERSION_SUB=$IMAGE_VERSION"
        "--cpp-flag=-DEXIM_VERSION_SUB=$exim_version"
        "--cpp-flag=-DVERSION_SUB=$version"
        "--cpp-flag=-DVARIANT_SUB=$variant"
        "--cpp-flag=-DSOURCE_IMAGE=$source_image"
        "--cpp-flag=-DARCH_SUB=$ARCH"
        "--cpp-flag=-DSPAMTAGGER_HASH_SUB=$(curl -s https://api.github.com/repos/SpamTagger/${variant}/commits?per_page=1 | jq -r '.[] | .sha')"
        "--cpp-flag=-DST_MAILSCANNER_HASH_SUB=$(curl -s https://api.github.com/repos/SpamTagger/st-mailscanner/commits?per_page=1 | jq -r '.[] | .sha')"
        "--cpp-flag=-DST_EXIM_HASH_SUB=$(curl -s https://api.github.com/repos/SpamTagger/st-exim/commits?per_page=1 | jq -r '.[] | .sha')"
    )
    mapfile -t image_cpp_flags < <(image-get cppFlags)
    for FLAG in $image_cpp_flags; do
        BUILD_ARGS+=("--cpp-flag=-D$FLAG")
    done
    if [[ "{{ app_repo }}" == http* ]]; then
        BUILD_ARGS+=("--cpp-flag=-DAPP_REPO_SUB={{ app_repo }}")
    else
        BUILD_ARGS+=("--cpp-flag=-DUSE_LOCAL_REPO")
        BUILD_ARGS+=("--cpp-flag=-DAPP_REPO_SUB={{ app_repo }}")
    fi

    {{ if env('CI', '') != '' { 'BUILD_ARGS+=("--cpp-flag=-DCI_SETX")' } else { '' } }}

    # Render Containerfile
    flags=()
    for f in "${BUILD_ARGS[@]}"; do
        if [[ "$f" =~ cpp-flag ]]; then
            flags+=("${f#*flag=}")
        fi
    done
    {{ require('cpp') }} -E --traditional -P container/Containerfile.in ${flags[@]} > {{ builddir / '$variant-$version/Containerfile' }}
    labels="LABEL"
    for l in "${LABELS[@]}"; do
        if [[ "$l" != "--label" ]]; then
            labels+=" $(jq -R <<< "${l%%=*}")=$(jq -R <<< "${l#*=}")"
        fi
    done
    echo "$labels" >> {{ builddir / '$variant-$version/Containerfile' }}
    sed -i '/^$/d;/^#.*$/d' {{ builddir / '$variant-$version/Containerfile' }}

    {{ podman }} pull $source_image

    # Build Image
    {{ podman }} build -f container/Containerfile.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" {{ justfile_dir() }}/container

# Test Container

alias test := test-container

# Run Tests in Container Image
[group('Container')]
test-container $variant="" $version="" $registry="":
    #!/usr/bin/env bash
    set -eou pipefail
    : "${registry:=localhost}"
    {{ default-inputs }}
    {{ get-names }}
    {{ build-missing }}
    echo "{{ style('warning') }}Running:{{ NORMAL }} {{ style('command') }}{{ just }} running tests in $registry/$image_name:$image_tag"
    {{ podman }} run -it --rm "$registry/$image_name:$image_tag" /usr/spamtagger/tests/run_tests.sh

# HHD-Dev Rechunk Image
[group('Container')]
hhd-rechunk $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ just }} check-valid-image $variant $version
    {{ get-names }}
    mkdir -p {{ builddir / '$variant-$version' }}
    {{ if shell('id -u') != '0' { podman + ' unshare -- ' + just + ' hhd-rechunk $variant $version; exit $?' } else { '' } }}

    set ${CI:+-x} -eou pipefail

    # Labels
    VERSION="$({{ podman }} inspect localhost/$image_name:$image_tag --format '{{{{ index .Config.Labels "org.opencontainers.image.version" }}')"
    LABELS="$({{ podman }} inspect localhost/$image_name:$image_tag | jq -r '.[].Config.Labels | to_entries | map("\(.key)=\(.value|tostring)")|.[]')"
    CREF=$({{ podman }} create localhost/$image_name:$variant-$version bash)
    OUT_NAME="$image_name.tar"
    MOUNT="$({{ podman }} mount $CREF)"

    {{ podman }} pull --retry 3 "{{ rechunker }}"

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        {{ rechunker }} \
        /sources/rechunk/1_prune.sh

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --volume "cache_ostree:/var/ostree" \
        --env TREE=/var/tree \
        --env REPO=/var/ostree/repo \
        --env RESET_TIMESTAMP=1 \
        --user 0:0 \
        {{ rechunker }} \
        /sources/rechunk/2_create.sh

    {{ podman }} unmount "$CREF"
    {{ podman }} rm "$CREF"
    {{ if env("CI", "") != "" { just + ' clean $variant $version localhost' } else { '' } }}

    {{ podman }} run --rm \
        --security-opt label=disable \
        --volume "{{ builddir / '$variant-$version' }}:/workspace" \
        --volume "{{ justfile_dir() }}:/var/git" \
        --volume cache_ostree:/var/ostree \
        --env REPO=/var/ostree/repo \
        --env PREV_REF="$image_registry/$image_org/$image_name:$image_tag" \
        --env LABELS="$LABELS" \
        --env OUT_NAME="$OUT_NAME" \
        --env VERSION="$VERSION" \
        --env VERSION_FN=/workspace/version.txt \
        --env OUT_REF="oci-archive:$OUT_NAME" \
        --env GIT_DIR="/var/git" \
        --user 0:0 \
        {{ rechunker }} \
        /sources/rechunk/3_chunk.sh
    {{ podman }} volume rm cache_ostree
    {{ if env("CI", "") != "" { 'mv ' + builddir / '$variant-$version/$image_name.tar ' + justfile_dir() / '$image_name.tar' } else { '' } }}

# Removes all Tags of an image from container storage.
[group('Utility')]
clean $variant $version $registry="":
    #!/usr/bin/env bash
    set -eou pipefail

    : "${registry:=localhost}"
    {{ get-names }}
    declare -a CLEAN="($({{ podman }} image list $registry/$image_name --noheading --format 'table {{{{ .ID }}' | uniq))"
    if [[ -n "${CLEAN[@]:-}" ]]; then
        {{ podman }} rmi -f "${CLEAN[@]}"
    fi

# Login to GHCR
[group('CI')]
@login-to-ghcr:
    {{ podman }} login ghcr.io -u "$GITHUB_ACTOR"  -p "$GITHUB_TOKEN"

# Push Images to Registry
[group('CI')]
push-to-registry $variant="" $version="" $destination="" $transport="":
    #!/usr/bin/bash
    {{ if env('CI', '') != '' { logsum } else { '' } }}
    {{ default-inputs }}
    {{ get-names }}

    set ${CI:+-x} -eou pipefail

    if [[ "{{ env('COSIGN_PRIVATE_KEY' ) }}" != '' ]]; then
      echo "$COSIGN_PRIVATE_KEY" > /tmp/cosign.key
      sed -i 's/ublue-os/spamtagger/' /etc/containers/registries.d/ublue-os.yaml
      echo "privateKeyFile: /tmp/cosign.key" > "/tmp/sigstore-params.yaml"
      echo "privateKeyPassphraseFile: /dev/null" >> "/tmp/sigstore-params.yaml"
    fi

    : "${destination:=$image_registry/$image_org}"
    : "${transport:="docker://"}"

    declare -A gen_tags="($({{ just }} gen-tags $variant $version))"
    tags=(${gen_tags["TAGS"]})
    for tag in "${tags[@]}"; do
        for i in {1..5}; do
            {{ podman }} push {{ if env('COSIGN_PRIVATE_KEY', '') != '' { '--sign-by-sigstore=/tmp/sigstore-params.yaml' } else { '' } }} "localhost/$image_name:$variant-$tag" "$transport$destination/$variant-$tag" 2>&1 && break || sleep $((5 * i));
            if [[ $i -eq '5' ]]; then
                exit 1
            fi
        done
        {{ if env('CI', '') != '' { 'log_sum $destination/$image_name:$variant-$tag' } else { '' } }}
    done
    {{ if env('CI', '') != '' { 'log_sum "\`\`\`"' } else { '' } }}
    {{ if env('COSIGN_PRIVATE_KEY', '') != '' { 'rm /tmp/cosign.key' } else { '' } }}

# Podmaon Machine Init
[group('Podman Machine')]
init-machine:
    #!/usr/bin/env bash
    set -ou pipefail
    ram_size="$(( $(free --mega | awk '/^Mem:/{print $7}') / 2 ))"
    ram_size="$(( ram_size >= 16384 ? 16384 : $(( ram_size >= 8192 ? 8192 : $(( ram_size >= 4096 ? 4096 : $(( ram_size >= 2048 ? 2048 : $(( ram_size >= 1024 ? 1024 : 0 )) )) )) )) ))"
    {{ podman-remote }} machine init \
        --rootful \
        --memory "${ram_size}" \
        --volume "{{ justfile_dir() + ":" + justfile_dir() }}" \
        --volume "{{ env('HOME') + ":" + env('HOME') }}" 2>{{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'VM already exists' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
        exit $ec
    fi
    exit 0

# Start Podman Machine
[group('Podman Machine')]
start-machine: init-machine
    #!/usr/bin/env bash
    set -ou pipefail
    {{ podman }} machine start 2>{{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'already running' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
        exit $ec
    fi
    exit 0

# Build Disk Image
[group('BIB')]
build-disk $variant="" $version="" $registry="": start-machine
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    set -eou pipefail

    if [[ "$registry" == 'localhost' ]]; then
      fq_name="$image_name:$image_tag"
    else
      fq_name="$registry/$image_name:$image_tag"
    fi

    # Create Build Dir
    mkdir -p {{ builddir }}/disks

    # Prepare Disk configuration
    echo "Preparing disk configuration at {{ builddir }}/$variant-$version.toml..."
    cp BIB/disk.toml {{ builddir }}/$variant-$version.toml
    if [[ "{{ PUBKEY }}" != ""  ]]; then
        sed -i "s|<SSHPUBKEY>|$(cat {{ PUBKEY }})|" {{ builddir }}/$variant-$version.toml
    else
        sed -i "/<SSHPUBKEY>/d" {{ builddir }}/$variant-$version.toml
    fi

    # If using localhost registry, we need to build
    TMP_IMAGE="$image_name-$image_tag.tar"
    if  [ "$registry" == "localhost" ]; then
        # Ensure image exists locally
        echo "Checking if $fq_name exists locally..."
        if ! {{ podman }} image exists $fq_name; then
            echo "$fq_name does not exist. Running 'just build-container $variant $version'..."
            just build $variant $version
        fi
        # Copy into Podman Machine
        echo "Copying local image to Podman Machine VM (so that we can run it as 'root')..."
        if [[ -e {{ builddir }}/$TMP_IMAGE ]]; then
            rm {{ builddir }}/$TMP_IMAGE
        fi
        {{ podman }} save --format oci-archive -o "{{ builddir }}/$TMP_IMAGE" "$fq_name"
        podman machine ssh rm /tmp/$TMP_IMAGE 2>/dev/null || true
        podman machine ssh sudo podman rmi $fq_name 2>/dev/null || true
        echo "Loading image into Podman Machine storage..."
        cat "{{ builddir }}/$TMP_IMAGE" | podman machine ssh sudo podman load
        rm {{ builddir }}/$TMP_IMAGE
    else
        echo "Pulling image from $fq_name..."
        {{ podman-remote }} pull $fq_name
    fi

    # Remove existing image, if it exists
    if [ -f {{ builddir }}/disks/$variant-$version.img ]; then
        echo "Removing existing disk image {{ builddir }}/disks/$variant-$version.img..."
        rm -f {{ builddir }}/disks/$variant-$version.img
    fi
 
    # Preallocate disk image
    if [[ ! -d {{ builddir }}/disks ]]; then
        mkdir {{ builddir }}/disks
    fi
    if [[ ! -e {{ builddir }}/disks/$variant-$version.img ]]; then
        echo "Allocating a blank disk image at {{ builddir }}/disks/$variant-$version.img..."
        fallocate -l 20G "{{ builddir }}/disks/$variant-$version.img"
    fi

    # Build Disk Image insde machine using rootful storage
    echo "Booting $fq_name in Podman Machine and installing to disk image with `bootc install to-disk`..."
    {{ podman-remote }} run \
        --rm --privileged --pid=host \
        -it \
        -v /{{ builddir }}/disks:/data{{ if selinux == 'true' { ':Z' } else { '' } }} \
        -e BOOTC_SETENFORCE0_FALLBACK=1 \
        -e RUST_LOG=debug \
        "$fq_name" \
        bootc install to-disk "/data/$variant-$version.img" \
            --via-loopback \
            --composefs-backend \
            --filesystem ext4 \
            --target-imgref $registry/$image_name:$variant-$version \
            --wipe \
            --bootloader systemd \
            --karg "splash"
    echo "Disk image should be available at {{ builddir }}/disks/$variant-$version.img"

# Build Disk Image
[group('BIB')]
build-disk-from-ghcr $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ get-names }}
    just build-disk $variant $version ghcr.io/$image_org
    echo "Completed ghcr.io/$image_org/$image_name:$variant-$version"

# Convert disk to supported other VM formats
[group('BIB')]
vm-disk $diskformat="" $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${diskformat:=all}"
    {{ get-names }}
    set -ou pipefail
    if [ ! -f {{ builddir / 'disks/$variant-$version.img' }} ]; then
        just build-disk
    fi
    if [ "$diskformat" == "qcow2" ] || [ "$diskformat" == "all" ]; then
        if [ -f {{ builddir / 'disks/$variant-$version.qcow2' }} ]; then
            echo Removing existing disk image {{ builddir / 'disks/$variant-$version.qcow2' }}
            rm -f {{ builddir / 'disks/$variant-$version.qcow2' }}
        fi
        echo Creating QCOW2 disk
        qemu-img convert -p -O qcow2 {{ builddir / 'disks/$variant-$version.img' }} {{ builddir / 'disks/$variant-$version.qcow2' }}
    fi
    if [ "$diskformat" == "vmdk" ] || [ "$diskformat" == "all" ]; then
        if [ -f {{ builddir / 'disks/$variant-$version.vmdk' }} ]; then
            echo Removing existing disk image {{ builddir / 'disks/$variant-$version.vmdk' }}
            rm -f {{ builddir / 'disks/$variant-$version.vmdk' }}
        fi
        echo Creating VMDK disk
        qemu-img convert -p -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 {{ builddir / 'disks/$variant-$version.img' }} {{ builddir / 'disks/$variant-$version.vmdk' }}
    fi
    if [ "$diskformat" == "vhdx" ] || [ "$diskformat" == "all" ]; then
        if [ -f {{ builddir / 'disks/$variant-$version.vhdx' }} ]; then
            echo Removing existing disk image {{ builddir / 'disks/$variant-$version.vhdx' }}
            rm -f {{ builddir / 'disks/$variant-$version.vhdx' }}
        fi
        echo Creating VHDX disk
        qemu-img convert -p -O vhdx -o subformat=dynamic,block_size=1M {{ builddir / 'disks/$variant-$version.img' }} {{ builddir / 'disks/$variant-$version.vhdx' }}
    fi

# Bundle VM images into compressed archives with bundled files
[group('BIB')]
bundle-vm $vmformat="" $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${vmformat:=all}"
    {{ get-names }}
    set -ou pipefail

    if [ ! -d {{ builddir / 'bundles' }} ]; then
        mkdir {{ builddir / 'bundles' }}
    fi
    if [ "$vmformat" == "all" ]; then
        {{ just }} bundle-vm $variant $version kvm
        {{ just }} bundle-vm $variant $version ami
        {{ just }} bundle-vm $variant $version ova
        {{ just }} bundle-vm $variant $version vhdx
    else
        DISK="{{ vmformat }}"
        if [ "$vmformat" == "ova" ] || [ "$vmformat" == "ami" ]; then
            DISK='vmdk'
        fi
        if [ "$vmformat" == "kvm" ]; then
            DISK='qcow2'
        fi
        if [ ! -f {{ builddir / 'disks/$variant-$version' }}.$DISK ]; then
            {{ just }} vm-disk $variant $version $DISK
            if [ ! -f {{ builddir / 'disks/$variant-$version' }}.$DISK ]; then
                echo "{{ style('error') }}Error:{{ NORMAL }} Disk Image \"$version-$variant.$DISK\" does not exist" >&2 && exit 1
            fi
        fi
        if [ -f {{ builddir / 'bundles/$variant-$version.$vmformat.zip' }}.$DISK ]; then
            echo Removing existing VM bundle {{ builddir / 'bundles/$variant-$version-$vmformat.zip' }}
            rm {{ builddir / 'bundles/$variant-$version-$vmformat.zip' }}
        fi
        echo Compressing $vmformat
        zip -r -j {{ builddir / 'bundles/$variant-$version-$vmformat.zip' }} {{ builddir / 'disks/$variant-$version' }}.$DISK BIB/vm-files/$vmformat/*
        echo Generating checksum for $vmformat
        sha256sum {{ builddir / 'bundles/$variant-$version-$vmformat.zip' }} > {{ builddir / 'bundles/$variant-$version-$vmformat.zip.sha256' }}
    fi

[group('BIB')]
push-to-cdn $variant="" $version="":
    #!/usr/bin/env bash
    echo "not implemented"

# Run Disk Image
[group('BIB')]
run-disk $variant="" $version="" $registry="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    set -ou pipefail
    if [ ! -f {{ builddir / 'disks/$variant-$version.qcow2' }} ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Disk Image \"$image_name-$version-$variant\" not built" >&2 && exit 1
    fi

    {{ require('macadam') }} init \
        --ssh-identity-path {{ PRIVKEY }} \
        --username root \
        {{ builddir / 'disks/$variant-$version.qcow2' }} 2> {{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'VM already exists' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
    fi

    macadam start 2>{{ builddir }}/error.log
    ec=$?
    if [ $ec != 0 ] && ! grep -q 'already running' {{ builddir }}/error.log; then
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(sed -E 's/Error:\s//' {{ builddir }}/error.log)" >&2
        printf '{{ style('error') }}Error:{{ NORMAL }} %s\n' "$(tail -n1 ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/macadam/gvproxy.log)" >&2
        exit $?
    fi
    macadam ssh -- cat /etc/os-release
    macadam ssh -- systemctl status
