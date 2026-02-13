# <img src="https://raw.githubusercontent.com/SpamTagger/SpamTagger-Bootc/refs/heads/main/spamtagger-bootc.svg" alt="SpamTagger Bootc Logo" style="height:2em; vertical-align:middle;"> SpamTagger Bootc

![SpamTagger Bootc Image Stack](https://raw.githubusercontent.com/SpamTagger/assets/5c7d152bda6e496a3cf111027dffba5798ba3915/bootc-stack.svg "This tool is used to generate Bootc-compatible, Debian-based, OCI images with SpamTagger tools pre-installed. This allows for automated building of SpamTagger appliance images in a variety of formats.")

## 🚧 Under Construction 🚧

This tool currently builds from a generic Debian Bootc image with few modification and does not yet produce a usable SpamTagger configuration. Regardless of the progress made in this repository, note that the [SpamTagger](https://github.com/SpamTagger/SpamTagger) application is still under construction as well. Any images built from this repository will not provide functional email filtering until both this repository and that one have a stable release.

## 🏝️ Background 🏝️

This project pulls significantly from various projects under the [Universal Blue (UBlue)](https://github.com/ublue-os) umbrella, as well as other projects inspired by it. SpamTagger-Bootc aims to produce minimal images with only the essential tools needed for email filtering and administration.

SpamTagger inherits from MailCleaner, which has historically been built of Debian throught its whole life. In order to remain familiar to users and to require the fewest possible changes, an updated Debian base is maintained. There is currently no official Debian Bootc image, so we are currently maintaining [our own fork](https://github.com/SpamTagger/debian-boot-core) of a community-built image.

BootC is a new and exciting technology which allows for creating read-only root filesystem images which can be deployed and atomically updated in a wide variety of contexts. It should ensure that SpamTagger appliances remain consistent, secure, up-to-date, and immune from degradation over time due to [hysteresis](https://en.wikipedia.org/wiki/Hysteresis).

SpamTagger is deployed within the read-only layer of these images so that the application code cannot be broken accidentally. Facilities remain in place for user modifications within a writable directory and additional packages and features can be added via contributions to the project, or through `system-sysext` extensons, containers, `brew` packages, `pip` or other package managers.

## 🧑‍🔧 Technical Details 🧑‍🔧

The rationale for the adopting of BootC was discussed in [this thread](https://github.com/orgs/SpamTagger/discussions/3). This projects aims to keeping the tooling open, easy to follow, functional in a local development environment, and automated using GitHub workflows.

To understand how the tools work SpamTagger images:

1. are defined via `images.yaml` with key "static" inputs required for a build (some tags and labels are generated or inspected).
2. use `just` recipies to manage the build related functions, providing the same local build commands as are used in CI.
3. use Podman's native C pre-processor (CPP) support for flow control (generation of a container file from `Containerfile`) instead of entirely static definitions in one or more `Containerfile`.
4. use devcontainer for a consistent build environment both locally and in CI

`images.yaml` uses anchors and aliases to build different images and tags from common components. A hint to see the expanded contents:

```
yq -r "explode(.)|.images" images.yaml
```

SpamTagger will primarily build two images:

- one for [SpamTagger](https://github.com/SpamTagger/SpamTagger), the direct successor to MailCleaner which retains a WebUI and other more complex features.
- and eventually one for [SpamTagger Core](https://github.com/SpamTagger/SpamTagger-Core), the simplified, commandline-only hard fork

Each of those is tagged at runtime with the version of Debian which it is based upon as well as a timestamp. This allows users to track a different life-cycle:

- tracking `spamtagger` will ensure that you always update to the latest, including across OS upgrades.
- tracking `spamtagger-13` will ensure that you have the latest version built on Debian 13, but not any future releases tagged as `spamtagger-14`.
- tracking `spamtagger-13-20250801` will ensure that you never update past that specific release.

In the future, additional tags for testing experimental feature branches.

## 🔨 Building 🔨

Building SpamTagger Bootc images on any workstation should be identical to how it is build with GitHub Actions. However you will need the following dependencies:

- `just` - The main scripting/orchestration tool.
- `bash` - Required for most commands within the `just` scripts.
- GNU core utiliies (especially `sed` and `grep`) - Required to modify template files and take conditional actions.
- `cpp` - Required for preprossor arguments to run different actions for each variant.
- `jq` - Required to parse JSON manifest files.
- `yq` - Required to parse YAML markup files for different images and versions that are available.
- `podman` - Container runtime for running the isolated build processes and including upstream image layers.
- `skopeo` - Required to fetch details from existing images in the registry.
- `podman-machine` (optional) - Only required for building VM disk images and ISOs.

Each build action has an associated `just` command. You can view them all by running `just --list`.

You will primarily need:

- `just build` - (alias for `just build-container`) to build the container image and tag it within your container list (`podman images`)
- `just hhd-rechunk` - to reduce the container size.
- `just build-disk` - create a `qcow2` disk image from the container image.
- `just build-iso` - create an ISO installation image from the `qcow2` image.
- `just convert-disk` - converts `qcow2` image to `vhdx` and/or `vmdk`.
- `just bundle-vm` - compresses VM images with accompanying files into an archive and creates a checksum.
- `push-to-cdn` - (work-in-progress) push the compressed VMs and checksums to CDN for download.

## See Also

- [SpamTagger](https://github.com/SpamTagger/SpamTagger) application repository
- [SpmTagger Core](https://github.com/SpamTagger-Core) application repository
- Other [SpamTagger](https://github.com/SpamTagger) projects
