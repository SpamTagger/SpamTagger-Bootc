# SpamTagger-Bootc

This is a trial run to generate OCI images and derived VMs and ISOs for SpamTagger (Plus) appliances based on CentOS Stream 10. It is an early work in progress. Regardless of any success building images with this repository, note that the [SpamTagger](https://github.com/SpamTagger/SpamTagger) and [SpamTagger Plus](https://github.com/SpamTagger/SpamTagger-Plus) applications are also still a work in progress and any images build from this repository will not provide functional email filtering until they do.

This project pulls significantly from the [Cayo](https://github.com/ublue-os/cayo) project which builds OCI images for more general purpose container and storage workloads. This project removes many of the tools built in to Cayo to suit only the functions necessary for the SpamTagger applications. Cayo and SpamTagger-Bootc, as it's derivative, provide bootc images built on the solid foundations of CentOS.

## Quick Summary

SpamTagger bootc images are meant to be suitable for appliance applications in a wide variety of contexts. This approach is taken because of the following advantages:

- bootc used for an "immutable" rootfs so that OS and application code cannot be modified or broken by the user or vulnerabilities and so that bugs can be replicable
- auto-updates to new versions of the application and operating system
- built on the solid foundations of CentOS
- installation via [existing bootc install methods](https://docs.fedoraproject.org/en-US/bootc/bare-metal/) or an Anaconda ISO installer
- optional features will be provided as system extensions (systemd sysext)

## Developing and Building

This repository inherits many of the good practices started out by Cayo and seeks to continue and extend those where possible. Included in this is a focus on keeping the tooling easy to follow,enabling local development and testing and leveraging GitHub workflows to automate and host as much as possible.

SpamTagger images:

1. are defined via `images.yaml` with all key "static" inputs required for a build (some tags and labels are generated or inspected)
2. use `just` recipies to manage the build related functions, providing the same local build commands as are used in CI
3. use Podman's native C preprocssor(CPP) support for flow control not otherwise available in a Containerfile
4. use devcontainer for a consistent build environment both locally and in CI

`images.yaml` uses anchors and aliases. A hint to see the expanded contents:

> `yq -r "explode(.)|.images" images.yaml`

SpamTagger will build two images:
- one for [SpamTagger](https://github.com/SpamTagger/SpamTagger), the simplified, commandline-only hard fork 
- the other for [SpamTagger Plus](https://github.com/SpamTagger/SpamTagger-Plus), the direct successor to MailCleaner which retains a WebUI and other more complex features.

If optional features are enabled, they will be provided using `systemd sysext` rather than building multiple images

The primary installation target for these images will be VMs, since this is what existing MailCleaner users expect. However, it is eventually a goal to provide an ISO installer for each image using `bootc-image-builder` to enable installation on a broader range of systems.

The goal
- Provide the minimum necessary tools for a functional mail filtering appliance.
- Ensure that all installations have identical OS and application code.
- Strongly discourage administrative changes on the OS level, aside from basics like network configuration.
- Any additional services and applications should be installed outside of OS and application sandbox via tools like Docker, Distrobox, Brew and Pip.
- Potential extensions to the base appliance via `systemd sysext` and Podman's [quadlets](https://github.com/containers/appstore). This is distribution agnostic and will allow Universal Blue to contribute to Podman's long term health and success.

## See also

- [SpamTagger](https://github.com/SpamTagger/SpamTagger) application repository
- [SpmTagger Plus](https://github.com/SpamTagger-Plus) application repository
- Other [SpamTagger](https://github.com/SpamTagger) projects
