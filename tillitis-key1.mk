# Tillitis Key 1 — Firmware and apps build overlay
# Included automatically by CIM via auto discovery.

.PHONY: tillitis-key1-build tillitis-key1-clean tillitis-key1-test

APP_FPGA_DIR      ?= $(TILLITIS_KEY1_DIR)/hw/application_fpga
APPS_DIR          ?= $(APP_FPGA_DIR)/apps

# Ubuntu's golang-1.23 package installs to /usr/lib/go-1.23/bin which
# is not in the default PATH. Add it if present. FIXME: Hardcoding 1.23 here
# will lead to problems sometime in the future. But as long as it's in the
# os-dependencies.yml in the manifest, we should be safe.
GO_UBUNTU_DIR ?= /usr/lib/go-1.23/bin
ifneq (,$(wildcard $(GO_UBUNTU_DIR)/go))
  export PATH := $(GO_UBUNTU_DIR):$(PATH)
endif

# Build firmware ELF (qemu variant), test firmware, and default app.
# qemu_firmware.elf pulls in defaultapp.bin, tkeyimage, and b2s automatically.
tillitis-key1-build:
	$(MAKE) -C $(APP_FPGA_DIR) qemu_firmware.elf testfw.elf
	# Explicitly build tkeyimage with a fixed output path (the upstream
	# .PHONY target may leave the binary in an unexpected state).
	cd $(APP_FPGA_DIR)/tools/tkeyimage && go build -o tkeyimage
	# Generate a flash image with the default app so QEMU can boot the firmware
	# without asserting on a missing partition table.
	cd $(APP_FPGA_DIR) && ./tools/tkeyimage/tkeyimage \
		-o flash.bin -f -app0 apps/defaultapp.bin

# Clean all generated artefacts in the application_fpga tree
tillitis-key1-clean:
	$(MAKE) -C $(APP_FPGA_DIR) clean
	rm -f $(APP_FPGA_DIR)/flash.bin

# Run firmware checks (static analysis)
tillitis-key1-test:
	$(MAKE) -C $(APP_FPGA_DIR) check
