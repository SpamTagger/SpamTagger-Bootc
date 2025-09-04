from pyanaconda.installclass import BaseInstallClass
from pyanaconda.product import productName
from pyanaconda import network
from pyanaconda import nm


class CustomBaseInstallClass(BaseInstallClass):
    name = "SpamTagger Plus"
    sortPriority = 30000
    if not productName.startswith("SpamTagger Plus"):
        hidden = True
    defaultFS = "xfs"
    bootloaderTimeoutDefault = 5
    bootloaderExtraArgs = []

    ignoredPackages = ["ntfsprogs"]

    installUpdates = False

    _l10n_domain = "comps"

    efi_dir = "centos"

    help_placeholder = "RHEL7Placeholder.html"
    help_placeholder_with_links = "RHEL7PlaceholderWithLinks.html"

    def configure(self, anaconda):
        BaseInstallClass.configure(self, anaconda)
        BaseInstallClass.setDefaultPartitioning(self, anaconda.storage)

    def setNetworkOnbootDefault(self, ksdata):
        if ksdata.method.method not in ("url", "nfs"):
            return
        if network.has_some_wired_autoconnect_device():
            return
        dev = network.default_route_device()
        if not dev:
            return
        if nm.nm_device_type_is_wifi(dev):
            return
        network.update_onboot_value(dev, "yes", ksdata)

    def __init__(self):
        BaseInstallClass.__init__(self)
