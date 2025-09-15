set unstable := true

just := just_executable()
podman := require('podman')
podman-remote := which('podman-remote') || podman + ' --remote'
builddir := shell('mkdir -p $1 && echo $1', absolute_path(env('SPAMTAGGER_BUILD', 'build')))
image := "spamtagger-bootc"
variant := env('SPAMTAGGER_VARIANT', shell('yq ".defaults.variant" images.yaml'))
version := env('SPAMTAGGER_VERSION', shell('yq ".defaults.version" images.yaml'))

# Source Images

rechunker := shell("yq '.images.rechunker.source' images.yaml")
bootc-image-builder := shell("yq '.images.bootc-image-builder.source' images.yaml")
qemu := shell("yq '.images.qemu.source' images.yaml")

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
    KEY="${1}"
    data=$(IFS="" yq -Mr "explode(.)|.images|.' + image + '-$variant-$version|.$KEY" images.yaml)
    echo ${data}
}
source_image="$(image-get source)"
image_org="$(image-get org)"
image_registry="$(image-get registry)"
image_repo="$(image-get repo)"
image_name="$(image-get name)"
image_upstream="$(image-get upstream)"
image_version="$(image-get version)"
image_description="$(image-get description)"
image_cpp_flags="$(image-get cppFlags[])"
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
explode-yaml:
    yq -r "explode(.)|.images" images.yaml

[group('Utility')]
check-valid-image $variant="" $version="":
    #!/usr/bin/env bash
    set -e
    {{ default-inputs }}
    data=$(IFS='' yq -Mr "explode(.)|.images|.{{ image }}-$variant-$version" images.yaml)
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
    if [[ $(cat "$LIST_TAGS" | jq "any(.Tags[]; contains(\"$image_tag-$TIMESTAMP\"))") == "true" ]]; then
       POINT="1"
       while $(cat "$LIST_TAGS" | jq -e "any(.Tags[]; contains(\"$image_tag-$TIMESTAMP.$POINT\"))")
       do
           (( POINT++ ))
       done
    fi

    if [[ -n "${POINT:-}" ]]; then
        TIMESTAMP="$TIMESTAMP.$POINT"
    fi

    # Add a sha tag for tracking builds during a pull request
    SHA_SHORT="$(git rev-parse --short HEAD)"

    # Define Versions
    COMMIT_TAGS=()
    if [[ -n "{{ env('GITHUB_PR_NUMBER', '') }}" ]]; then
        COMMIT_TAGS=("$image_tag" "pr-$image_tag-$SHA_SHORT" "pr-$image_tag-{{ env('GITHUB_PR_NUMBER', '') }}")
    fi
    BUILD_TAGS=("$variant" "$image_tag" "$image_tag-$TIMESTAMP")

    declare -A output
    output["BUILD_TAGS"]="${BUILD_TAGS[*]}"
    output["COMMIT_TAGS"]="${COMMIT_TAGS[*]}"
    output["TIMESTAMP"]="$TIMESTAMP"
    echo "${output[@]@K}"

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file" >&2
        {{ just }} --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile" >&2
    {{ just }} --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file" >&2
        {{ just }} --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile" >&2
    {{ just }} --unstable --fmt -f Justfile || { exit 1; }

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
    if [[ "{{ env('GITHUB_EVENT_NAME', '') }}" =~ pull_request ]]; then
        tags=(${gen_tags["COMMIT_TAGS"]})
    else
        tags=(${gen_tags["BUILD_TAGS"]})
    fi
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"
    TAGS=()
    for tag in "${tags[@]}"; do
        TAGS+=("--tag" "localhost/$image_name:$tag")
    done

    # Divergence from Cayo: Custom kernel (ZFS) dropped. In Cayo an additional AKMODS image layer is pulled here.

    # Labels
    IMAGE_VERSION="$image_version.$TIMESTAMP"
    # Divergence from Cayo: KERNEL_VERSION would be inspected from AKMODS image instead
    # Divergence from Cayo: Updated labels
    LABELS=(
        "--label" "containers.bootc=1"
        "--label" "io.artifacthub.package.deprecated=false"
        "--label" "io.artifacthub.package.keywords=bootc,spamtagger-bootc,centos,cayo,ublue,universal-blue"
        "--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/205223896&v=4"
        "--label" "io.artifacthub.package.maintainers=[{\"name\": \"John Mertz\", \"email\": \"git@john.me.tz\"}]"
        "--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/$image_registry/$image_org/$image_repo/main/README.md"
        "--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)"
        "--label" "org.opencontainers.image.description=$image_description"
        "--label" "org.opencontainers.image.license=GPLv3.0+"
        "--label" "org.opencontainers.image.source=https://raw.githubusercontent.com/SpamTagger/SpamTagger-Bootc/refs/heads/main/Containerfile.in"
        "--label" "org.opencontainers.image.title=$image_name"
        "--label" "org.opencontainers.image.url=https://github.com/$image_org/$image_repo"
        "--label" "org.opencontainers.image.vendor=$image_org"
        "--label" "org.opencontainers.image.version=${IMAGE_VERSION}"
    )

    # BuildArgs
    BUILD_ARGS=(
        "--security-opt=label=disable"
        "--cap-add=all"
        "--device" "/dev/fuse"
        # Divergence from Cayo: KERNEL_NAME not specified, since no variants are needed for CentOS
        "--cpp-flag=-DIMAGE_VERSION_ARG=IMAGE_VERSION=$IMAGE_VERSION"
        "--cpp-flag=-DSOURCE_IMAGE=$source_image"
        # Divergence from Cayo: Removed additional flag: --cpp-flag=-DZFS=$AKMODS_ZFS_IMAGE
    )
    for FLAG in $image_cpp_flags; do
        BUILD_ARGS+=("--cpp-flag=-D$FLAG")
    done
    {{ if env('CI', '') != '' { 'BUILD_ARGS+=("--cpp-flag=-DCI_SETX")' } else { '' } }}

    # Render Containerfile
    flags=()
    for f in "${BUILD_ARGS[@]}"; do
        if [[ "$f" =~ cpp-flag ]]; then
            flags+=("${f#*flag=}")
        fi
    done
    {{ require('cpp') }} -E -traditional container/Containerfile.in ${flags[@]} > {{ builddir / '$variant-$version/Containerfile' }}
    labels="LABEL"
    for l in "${LABELS[@]}"; do
        if [[ "$l" != "--label" ]]; then
            labels+=" $(jq -R <<< "${l%%=*}")=$(jq -R <<< "${l#*=}")"
        fi
    done
    echo "$labels" >> {{ builddir / '$variant-$version/Containerfile' }}
    sed -i '/^$/d;/^#.*$/d' {{ builddir / '$variant-$version/Containerfile' }}

    # Build Image
    {{ podman }} build -f container/Containerfile.in "${BUILD_ARGS[@]}" "${LABELS[@]}" "${TAGS[@]}" {{ justfile_dir() }}/container

# Test Container

alias test := test-container

# Run Container Image
[group('Container')]
test-container $variant="" $version="" $registry="":
    #!/usr/bin/env bash
    set -eou pipefail
    : "${registry:=localhost}"
    {{ default-inputs }}
    {{ get-names }}
    {{ build-missing }}
    echo "{{ style('warning') }}Running:{{ NORMAL }} {{ style('command') }}{{ just }} running tests in $registry/$image_name:$image_tag"
    {{ podman }} run -it --rm "$registry/$image_name:$image_tag" prove /usr/spamtagger/tests/

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

    declare -a TAGS=($({{ podman }} image list localhost/$image_name:$image_tag --noheading --format 'table {{{{ .Tag }}'))
    for tag in "${TAGS[@]}"; do
        for i in {1..5}; do
            {{ podman }} push {{ if env('COSIGN_PRIVATE_KEY', '') != '' { '--sign-by-sigstore=/tmp/sigstore-params.yaml' } else { '' } }} "localhost/$image_name:$image_tag" "$transport$destination/$image_name:$tag" 2>&1 && break || sleep $((5 * i));
            if [[ $i -eq '5' ]]; then
                exit 1
            fi
        done
        {{ if env('CI', '') != '' { 'log_sum $destination/$image_name:$tag' } else { '' } }}
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
    fq_name="$registry/$image_name:$image_tag"
    set -eou pipefail
    # Create Build Dir
    mkdir -p {{ builddir / 'disks' }}

    # Process Template
    cp BIB/disk.toml {{ builddir / '$variant-$version.toml' }}
    if [[ "{{ PUBKEY }}" != ""  ]]; then
        sed -i "s|<SSHPUBKEY>|$(cat {{ PUBKEY }})|" {{ builddir / '$variant-$version.toml' }}
    else
        sed -i "/<SSHPUBKEY>/d" {{ builddir / '$variant-$version.toml' }}
    fi

    # Load image into rootful podman-machine
    if ! {{ podman-remote }} image exists $fq_name && ! {{ podman }} image exists $fq_name; then
        if ! [ "$registry" == "localhost" ]; then
          # If using localhost registry, try pulling and check again
          {{ podman-remote}} pull $fq_name
          if ! {{ podman-remote }} image exists $fq_name && ! {{ podman }} image exists $fq_name; then
            echo "{{ style('error') }}Error:{{ NORMAL }} Image \"$fq_name\" not in image-store" >&2
            exit 1
          fi
        else
          echo "{{ style('error') }}Error:{{ NORMAL }} Image \"$fq_name\" not in image-store" >&2
          exit 1
        fi
    fi
    if ! {{ podman-remote }} image exists $fq_name; then
        COPYTMP="$(mktemp -p {{ builddir }} -d -t podman_scp.XXXXXXXXXX)" && trap 'rm -rf $COPYTMP' EXIT SIGINT
        TMPDIR="$COPYTMP" {{ podman }} image scp $fq_name podman-machine-default-root::
        rm -rf "$COPYTMP"
    fi

    # Pull Bootc Image Builder
    {{ podman-remote }} pull --retry 3 {{ bootc-image-builder }}

    # Remove existing image, if it exists
    if [ -f "{{ builddir /'disks/$variant-$version.qcow2' }}" ]; then
        echo Removing existing disk image {{ builddir /'disks/$variant-$version.qcow2' }}
        rm -f {{ builddir /'disks/$variant-$version.qcow2' }}
    fi

    # Build Disk Image
    {{ podman-remote }} run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v {{ builddir / '$variant-$version' }}.toml:/config.toml:ro \
        -v {{ builddir }}/disks:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        {{ if env('CI', '') != '' { '--progress verbose' } else { '--progress auto' } }} \
        --type qcow2 \
        --use-librepo=True \
        --rootfs xfs \
        $fq_name

     # Sparsify and compress
     echo Shrinking disk image
     qemu-img convert -c -O qcow2 {{ builddir }}/disks/qcow2/disk.qcow2 {{ builddir /'disks/$variant-$version.qcow2' }}
     rm -rf {{ builddir }}/disks/qcow2 {{ builddir }}/disks/manifest-qcow2.json {{ builddir / '$variant-$version*' }}

# Convert disk to supported other VM formats
[group('BIB')]
convert-disk $variant="" $version="" $diskformat="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${diskformat:=all}"
    {{ get-names }}
    set -ou pipefail
    if [ ! -f {{ builddir / 'disks/$variant-$version.qcow2' }} ]; then
        # Attempt to build if not already built
        {{ just }} build-disk $variant $version
        if [ ! -f {{ builddir / 'disks/$variant-$version.qcow2' }} ]; then
            echo "{{ style('error') }}Error:{{ NORMAL }} Disk Image \"$image_name-$version-$variant\" not built" >&2 && exit 1
        fi
    fi
    if [ "$diskformat" == "vmdk" || [ "$diskformat" == "all" ]; then
        if [ -f "{{ builddir / 'disks/$variant-$version.vmdk' }}" ]; then
            echo Removing existing disk image {{ builddir / 'disks/$variant-$version.vmdk' }}
            rm -f {{ builddir / 'disks/$variant-$version.vmdk' }}
        fi
        echo Creating VMDK disk
        qemu-img convert -p -f qcow2 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 {{ builddir / 'disks/$variant-$version.qcow2' }} {{ builddir / 'disks/$variant-$version.vmdk' }}
    fi
    if [ "$diskformat" == "vhdx" ] || [ "$diskformat" == "all" ]; then
        if [ -f "{{ builddir / 'disks/$variant-$version.vhdx' }}" ]; then
            echo Removing existing disk image {{ builddir / 'disks/$variant-$version.vhdx' }}
            rm -f {{ builddir / 'disks/$variant-$version.vhdx' }}
        fi
        echo Creating VHDX disk
        qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic,block_size=1M {{ builddir / 'disks/$variant-$version.qcow2' }} {{ builddir / 'disks/$variant-$version.vhdx' }}
    fi

# Bundle VM images into compressed archives with bundled files
[group('BIB')]
bundle-vm $variant="" $version="" $vmformat="":
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
            {{ just }} convert-disk $variant $version $DISK
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

# Build ISO
[group('BIB')]
build-iso $variant="" $version="" $registry="": start-machine
    #!/usr/bin/env bash
    {{ default-inputs }}
    : "${registry:=localhost}"
    {{ get-names }}
    fq_name="$registry/$image_name:$variant-$version"
    set -eou pipefail

    if [ ! -d {{ builddir / 'isos' }} ]; then
        echo Creating build directory {{ builddir / 'isos' }}
        mkdir -p {{ builddir / 'isos' }}
    elif [ -e {{ builddir / 'isos/$variant-$version.iso' }} ]; then
        echo Removing existing ISO image {{ builddir / 'isos/$variant-$version.iso' }}
        rm {{ builddir / 'isos/$variant-$version.iso' }}
    fi

    if [ -d {{ builddir / 'product' }} ]; then
        rm -rf {{ builddir / 'product' }}
    fi

    declare -A gen_tags="($({{ just }} gen-tags $variant $version))"
    TIMESTAMP="${gen_tags["TIMESTAMP"]}"

    cp -r BIB/anaconda/product {{ builddir / 'product' }}
    cd {{ builddir / 'product' }}
    if [ "$variant" == 'spamtagger' ]; then
      sed -i "s/<VARIANT>/SpamTagger/" .buildstamp
    else
      sed -i "s/<VARIANT>/SpamTagger Plus/" .buildstamp
    fi
    sed -i "s/<VERSION>/$version/" .buildstamp
    sed -i "s/<TAG>/$TIMESTAMP/" .buildstamp
    find . | cpio -c -o | gzip -9cv >../product.img
    cd -
    mv {{ builddir /'product.img' }} ./
    #rm -rf {{ builddir / 'product' }}

    # Process Template
    cp BIB/iso.toml {{ builddir / '$variant-$version.toml' }}
    sed -i "s|<URL>|$fq_name|" {{ builddir / '$variant-$version.toml' }}
    if [[ $registry == "localhost" ]]; then
        sed -i "s|<SIGPOLICY>||" {{ builddir / '$variant-$version.toml' }}
    else
        sed -i "s|<SIGPOLICY>| --enforce-container-sigpolicy|" {{ builddir / '$variant-$version.toml' }}
    fi

    # Load image into rootful podman-machine
    if ! {{ podman-remote }} image exists $fq_name && ! {{ podman }} image exists $fq_name; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Image \"$fq_name\" not in image-store" >&2
        exit 1
    fi
    if ! {{ podman-remote }} image exists $fq_name; then
        COPYTMP="$(mktemp -p {{ builddir }} -d -t podman_scp.XXXXXXXXXX)" && trap 'rm -rf $COPYTMP' EXIT SIGINT
        TMPDIR="$COPYTMP" {{ podman }} image scp $fq_name podman-machine-default-root::
        rm -rf "$COPYTMP"
    fi

    # Pull Bootc Image Builder
    {{ podman-remote }} pull --retry 3 {{ bootc-image-builder }}

    if [ ! -d {{ builddir / '$variant-$version' }} ]; then
        mkdir {{ builddir / '$variant-$version' }}
    fi

    # Build ISO
    {{ podman-remote }} run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v {{ builddir / '$variant-$version.toml' }}:/config.toml:ro \
        -v {{ builddir / '$variant-$version' }}:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        {{ if env('CI', '') != '' { '--progress verbose' } else { '--progress auto' } }} \
        --type anaconda-iso \
        --use-librepo=True \
        $fq_name

    mv {{ builddir / '$variant-$version/bootiso/install.iso' }} {{ builddir / 'isos/$variant-$version.iso' }}
    rm -rf {{ builddir / '$variant-$version' }} product.img

# Run ISO
[group('BIB')]
run-iso $variant="" $version="":
    #!/usr/bin/env bash
    {{ default-inputs }}
    {{ get-names }}
    set -euo pipefail
    if [ ! -f {{ builddir / '$variant-$version/bootiso/install.iso' }} ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Install ISO \"$image_name-$variant-$version\" not built" >&2 && exit 1
    fi
    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Needs to be on the podman-machine due to dnsmasq requesting excessive UIDs/GIDs

    # Ram Size
    ram_size="$({{ podman-remote }} machine inspect | jq -r '.[].Resources.Memory')"
    ram_size="$(( ram_size / 2))"
    ram_size="$(( ram_size >= 8192 ? 8192 : $(( ram_size >= 4096 ? 4096 : $(( ram_size >= 2048 ? 2048 : $(( ram_size >= 1024 ? 1024 : 0 )) )) )) ))"
    if [ $ram_size = "0" ]; then
        echo "{{ style('error') }}Error:{{ NORMAL }} Not Enough Memory configured in podman machine" >&2 && exit 1
    fi

    # CPU Cores
    cpu_cores="$(( $({{ podman-remote }} machine inspect | jq -r '.[].Resources.CPUs') / 2 ))"
    cpu_cores="$(( cpu_cores > 0 ? cpu_cores : 1 ))"

    # Pull qemu container
    {{ podman-remote }} pull --retry 3 {{ qemu }}

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=$cpu_cores")
    run_args+=(--env "RAM_SIZE=${ram_size}M")
    run_args+=(--env "DISK_SIZE=20G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--device=/dev/kvm)
    run_args+=(--device=/dev/net/tun)
    run_args+=(--cap-add NET_ADMIN)
    run_args+=(--volume "{{ builddir / '$variant-$version/bootiso/install.iso' }}":"/boot.iso")

    # Run the VM and open the browser to connect
    {{ podman-remote }} run "${run_args[@]}" {{ qemu }}
