# <img src="https://raw.githubusercontent.com/SpamTagger/SpamTagger-Bootc/refs/heads/main/spamtagger-bootc.svg" alt="SpamTagger Bootc Logo" style="height:2em; vertical-align:middle;"> SpamTagger Bootc

![SpamTagger Bootc Image Stack](https://raw.githubusercontent.com/SpamTagger/assets/5c7d152bda6e496a3cf111027dffba5798ba3915/bootc-stack.svg "This tool is used to generate Bootc-compatible, Debian-based, OCI images with SpamTagger tools pre-installed. This allows for automated building of SpamTagger appliance images in a variety of formats.")

## 🚧 Under Construction 🚧

This tool currently builds from a generic Debian Bootc image with few modification and does not yet produce a usable SpamTagger configuration. Regardless of the progress made in this repository, note that the [SpamTagger](https://github.com/SpamTagger/SpamTagger) application is still under construction as well. Any images built from this repository will not provide functional email filtering until both this repository and that one have a stable release.

## 🏝️ What is SpamTagger-Bootc? 🏝️

The SpamTagger-Bootc repository is responsible for [building](https://github.com/SpamTagger/SpamTagger-Bootc/blob/main/ARCHITECTURE.md) [Debian](https://debian.org)-based [BootC](https://bootc.dev) operating system containers with [SpamTagger](https://spamtagger.org) appliance functionality built in to the read-only layer of the image.

## ✨ Features ✨

This architecture provides:

* Simple building of images with CI/CD
* Consistency between deployments
* Predictable upgrade behaviour
* Clean roll-backs
* Incorruptable application code
* [Among other considerations](https://github.com/orgs/SpamTagger/discussions/3)

## 🤔 Why Does This Exist 🤔

SpamTagger is a revival of the MailCleaner spam filtering appliance. Historically, MailCleaner didn't have a very consistent and repeatable set of build tools, making it very difficult to ensure that subsequent builds would be upgrade-compatible with older builds. Application code was completely unprotected and changes throughout the life of the appliance could cause appliance functionality to degrade over time (see [hysteresis](https://en.wikipedia.org/wiki/Hysteresis)).

With the SpamTagger revival as a fully free and open source project, it was crucial to find a way to build, distribute and provide consistent upgrades for appliances while minimizing hosting costs and complexity.

BootC is a fairly new technology which is in its very early days for non-RHEL systems, but some early exploration has shown that it is possible to build successfully on Debian, which allows SpamTagger to continue with as few architectural changes as possible from MailCleaner's historical legacy.

## 🧭 Getting Started 🧭

Typically, you shouldn't need to touch anything in this repository. GitHub actions regularly build new OS images with the latest version of SpamTagger and the latest Debian packages available at the time, and we provide VM images based on those.

If you want to [contribute](https://github.com/SpamTagger/SpamTagger/Wiki/Contributing-Guide) to SpamTagger and your contribution applies to the OS layer rather than the application layer (eg. adding additional packages, or configuring system services), then you may need to contribute those changes here.

You may also just want to build a custom SpamTagger-Bootc image by pointing this builder to a custom SpamTagger repository, layering on additional changes, or building your own application images based on this one.

You can read more in the [architecture](https://github.com/SpamTagger/SpamTagger-Bootc/wiki/Architecture) and [build](https://github.com/SpamTagger/SpamTagger-Bootc/wiki/Building) documents to learn how the parts go together and how to build your own modified or unmodified images.
