# tkey-devtools — Go-based development tools build overlay
# Included automatically by CIM via auto discovery.

.PHONY: tkey-devtools-build tkey-devtools-clean tkey-devtools-test

# Ubuntu's golang-1.23 package installs to /usr/lib/go-1.23/bin which
# is not in the default PATH. Add it if present. FIXME: Hardcoding 1.23 here
# will lead to problems sometime in the future. But as long as it's in the
# os-dependencies.yml in the manifest, we should be safe.
GO_UBUNTU_DIR ?= /usr/lib/go-1.23/bin
ifneq (,$(wildcard $(GO_UBUNTU_DIR)/go))
  export PATH := $(GO_UBUNTU_DIR):$(PATH)
endif

# Build the main CLI tools. hidread is skipped by default because it
# requires CGO + libusb headers that may not be present on all hosts.
tkey-devtools-build:
	$(MAKE) -C $(TKEY_DEVTOOLS_DIR) tkey-runapp

tkey-devtools-clean:
	$(MAKE) -C $(TKEY_DEVTOOLS_DIR) clean

tkey-devtools-test:
	@test -e ./tkey-qemu-CDC.pty || { echo "CDC PTY symlink not found. Run: make qemu-usb-mux <pts-number>"; exit 1; }
	./tkey-devtools/tkey-runapp --port ./tkey-qemu-CDC.pty ./tillitis-key1/hw/application_fpga/apps/testapp.bin
