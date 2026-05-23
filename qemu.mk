# QEMU (tk1 branch) build overlay
# Included automatically by CIM via auto discovery.

.PHONY: qemu-build qemu-clean qemu-test qemu-usb-mux

# Allow passing the PTY number as a positional argument:
#   make qemu-usb-mux 17
ifneq ($(filter qemu-usb-mux,$(MAKECMDGOALS)),)
  QEMU_MUX_PTY := $(word 2,$(MAKECMDGOALS))
  ifneq ($(QEMU_MUX_PTY),)
    $(eval $(QEMU_MUX_PTY):;@:)
  endif
endif

QEMU_BUILD_DIR := $(QEMU_DIR)/build

qemu-build:
	mkdir -p $(QEMU_BUILD_DIR)
	cd $(QEMU_BUILD_DIR) && ../configure \
		--target-list=riscv32-softmmu \
		--disable-werror
	$(MAKE) -C $(QEMU_BUILD_DIR)

qemu-clean:
	rm -rf $(QEMU_BUILD_DIR)

qemu-test:
	$(MAKE) -C $(QEMU_BUILD_DIR) check

# Paths to built artifacts
QEMU_BIN    := $(QEMU_BUILD_DIR)/qemu-system-riscv32
FIRMWARE    := $(WORKSPACE)/tillitis-key1/hw/application_fpga/qemu_firmware.elf
FLASH_IMG   := $(WORKSPACE)/tillitis-key1/hw/application_fpga/flash.bin

# Common QEMU flags for tk1-castor
QEMU_FLAGS  := -nographic -M tk1-castor,fifo=chrid -chardev pty,id=chrid \
               -bios $(FIRMWARE) -drive file=$(FLASH_IMG),if=mtd,format=raw,index=0

# Run the TKey in QEMU with a PTY chardev. QEMU will print the PTY path
# (e.g. /dev/pts/3) on startup. The UART inside QEMU expects the internal
# "USB Mode Protocol", so you must run the qemu_usb_mux.py wrapper to get a
# CDC serial port for tkey-runapp:
#
#   make qemu-usb-mux <pts-number>
#
# Then load an app using the mux CDC PTY:
#   make tkey-devtools-test
#
# To quit QEMU: Ctrl-A then X
.PHONY: qemu-run
qemu-run:
	@test -f $(QEMU_BIN) || { echo "QEMU not built. Run 'make sdk-build' first."; exit 1; }
	@test -f $(FIRMWARE) || { echo "Firmware not built. Run 'make sdk-build' first."; exit 1; }
	@test -f $(FLASH_IMG) || { echo "Flash image not built. Run 'make sdk-build' first."; exit 1; }
	@echo "Starting TKey (tk1-castor) in QEMU..."
	@echo "Note the PTY path printed below. In another terminal, run the USB mux:"
	@echo "  make qemu-usb-mux <pts-number>"
	@echo "Then in a third terminal, load the test app:"
	@echo "  make tkey-devtools-test"
	@echo "To quit QEMU: Ctrl-A then X"
	@echo "---"
	$(QEMU_BIN) $(QEMU_FLAGS)

# Start the QEMU USB mux for the given PTY number (e.g. make qemu-usb-mux 17)
qemu-usb-mux:
	@test -n "$(QEMU_MUX_PTY)" || { echo "Usage: make qemu-usb-mux <pts-number>"; exit 1; }
	@test -c /dev/pts/$(QEMU_MUX_PTY) || { echo "/dev/pts/$(QEMU_MUX_PTY) is not a valid character device"; exit 1; }
	@rm -f ./tkey-qemu-*.pty
	python3 $(QEMU_DIR)/tools/tk1/qemu_usb_mux.py --symlink ./tkey-qemu /dev/pts/$(QEMU_MUX_PTY)

# Run QEMU with GDB server on port 1234 and stop at startup (-S).
# Attach with: riscv32-unknown-elf-gdb -ex 'target remote localhost:1234'
.PHONY: qemu-run-gdb
qemu-run-gdb:
	@test -f $(QEMU_BIN) || { echo "QEMU not built. Run 'make sdk-build' first."; exit 1; }
	@test -f $(FIRMWARE) || { echo "Firmware not built. Run 'make sdk-build' first."; exit 1; }
	@test -f $(FLASH_IMG) || { echo "Flash image not built. Run 'make sdk-build' first."; exit 1; }
	@echo "Starting TKey in QEMU with GDB server on localhost:1234 ..."
	@echo "Attach with: riscv32-unknown-elf-gdb -ex 'target remote localhost:1234'"
	@echo "To quit QEMU: Ctrl-A then X"
	@echo "---"
	$(QEMU_BIN) $(QEMU_FLAGS) -s -S
