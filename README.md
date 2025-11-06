# SpamTagger-Bootc

This repository is used to generate OCI images and derived VMs and ISOs for [SpamTagger Plus](https://github.com/SpamTagger/SpamTagger-Plus) appliances (with future support for [SpamTagger](https://github.com/SpamTagger/SpamTagger) already in place).

## 🚧 Under Construction 🚧

This tool currently builds from Debian's `stable-slim` image and installs most of the required packages for a SpamTagger Plus appliance. However, the work to comprehensively configure SpamTagger services is still ongoing. Regardless of the progress made in this repository, note that the SpamTagger Plus application is still under construction as well. At this time, any images built from this repository will not provide functional email filtering until both this repository and that one have a stable release.

## 🏝️ Background 🏝️

This project was initially inspired by [Cayo](https://github.com/ublue-os/cayo) and initially targetted a CentOS Stream 10 base. Since then, the Cayo project had most of what made it unique (compared to `ucore` and `centos-bootc`) have been merge upstream and the project is being deprecated. It would have been entirely possible to continue work on SpamTagger-Bootc using the latest Cayo tools and those that we had built on top of them, but other developments have allowed us to change tracks.

At around the same time that Cayo was wrapping up, [another group](https://github.com/bootcrew)  started having success building non-RPM based distributions using BootC, including Debian. MailCleaner has always been based on Debian so it would be most familiar to existing users and also simpler to port all work already done to update MailCleaner-Next/SpamTagger-Plus prior to the shift to CentOS Stream. There have also been concerns about CentOS's relationship to RedHat, it's less stable place in the Enterprise Linux development cycle and uncertain future. So, the current focus is to migrate back to Debian Stable.

## 🥅 Goals 🥅

SpamTagger bootc images are meant to be suitable for appliance applications in a wide variety of contexts. To reach this goal the following techniques are employed:

- `bootc` images provide an "immutable" root filesystem so that OS and application code cannot be modified or broken by the user or vulnerabilities.
- `bootc` also ensures that all deployments of the same version have identical operating system and application code. This means that bugs should be replicable across each deployment rather than being subject to an unknown number of confounding factors.
- `bootc` also provides auto-updates to new versions of the application and operating system which are atomic and which replace the entire root filesystem image. This ensures that all updates will be installed completely and successfully.
- In the event that the system successfully installs an update which is broken, `bootc` also provides automatic rollbacks to the last working version if the system fails to boot.
- `bootc` also enables for rolling back to any other previous release which still exists in the registry as well as checking out different tagged versions to halt updates or put the system into an alternate update track (say `spamtagger-plus-13` instead of `spamtagger-plus` to prevent automatically updating to `spamtagger-plus-14` when the first Debian 14 builds become available).
- `Debian` provides a stable, familiar base for existing MailCleaner users as well as the large number of newcomers who are already familiar with Debian-based distributions.
- The minimum necessary tools for a functional mail filtering appliance will be included. The images should remain quite minimal in size (probably just over 2GB) and will not be suitable as a general-purpose server.
- Administrative changes on the OS level will be strongly discouraged, aside from basics like network configuration.
- Additional features which are generally desirable for other members of the community should be made available to be integrated back into the projects (as is a requirement of the [license](https://github.com/SpamTagger-Bootc/blob/main/LICENSE.md)). Other features which are more niche may be made available through system extensions via `systemd sysext` or Podman's [quadlets](https://github.com/containers/appstore).
- Installing additional applications and services outside of the OS and application sandbox via tools like Docker, Distrobox, Brew and Pip is still possible.
- The CI/CD tools in this repository provide automated tools for building container images which can be pulled directly into a containerized environment, switched out from [an existing bootc installation](https://github.com/bootc-dev/bootc/blob/main/docs/src/man/bootc-switch.md) or [self-installed to an existing disk/filesystem](https://bootc-dev.github.io/bootc//bootc-install.html#executing-bootc-install) on a machine with Podman. These images will also be built into VM images supported by most major hypervisors (likely to be the primary method), as well as installable ISOs, and other formats.
- It should also be possible to run images within a development environment using tools like
[`distrobox`](https://distrobox.it) where the root filesystem becomes writable and tools like `git` and text editors can be easily installed.

## 🧑‍🔧 Technical Details 🧑‍🔧

This repository inherits many of the good practices started out by UBlue and Cayo and seeks to continue and extend those where possible. Included in this is a focus on keeping the tooling open, easy to follow, functional in a local development environment, and possible to automate using CI/CD workflows.

SpamTagger images:

1. are defined via `images.yaml` with version and variant names.
2. use `just` recipes in the `Justfile` to manage the build related functions, providing the same local build commands as are used in CI.
3. The `Containerfile` is dynamically generated from `containers/Containerfile.in` with substituted arguments and flow control using Podman's native C pre-processor (CPP) support.
4. use devcontainer for a consistent build environment both locally and in CI

`images.yaml` uses anchors and aliases to build different images and tags from common components. A hint to see the expanded contents:

```
yq -r "explode(.)|.images" images.yaml
```

SpamTagger will primarily build two images:

- one for [SpamTagger Plus](https://github.com/SpamTagger/SpamTagger-Plus), the direct successor to MailCleaner which retains a WebUI and other more complex features.
- and eventually one for [SpamTagger](https://github.com/SpamTagger/SpamTagger), the simplified, commandline-only hard fork

Each of those is tagged at runtime with the version of Debian which it is based upon as well as a timestamp. This allows users to track a different life-cycle:

- tracking `spamtagger-plus` will ensure that you always update to the latest, including across OS upgrades.
- tracking `spamtagger-plus-13` will ensure that you have the latest version built on Debian 13, but not any future releases tagged as `spamtagger-plus-14`.
- tracking `spamtagger-plus-20250801` will ensure that you never update past that specific release.

In the future, additional tags may exist for testing experimental feature branches.

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
- [SpmTagger Plus](https://github.com/SpamTagger-Plus) application repository
- Other [SpamTagger](https://github.com/SpamTagger) projects
