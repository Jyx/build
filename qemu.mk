# QEMU (tk1 branch) build overlay
# Included automatically by CIM via auto discovery.

.PHONY: qemu-build qemu-clean qemu-test

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
# (e.g. /dev/pts/3) on startup. Use tkey-runapp to connect to it:
#   ./tkey-devtools/tkey-runapp --port /dev/pts/N --app <app.bin>
# To quit QEMU: Ctrl-A then X
.PHONY: qemu-run
qemu-run:
	@test -f $(QEMU_BIN) || { echo "QEMU not built. Run 'make sdk-build' first."; exit 1; }
	@test -f $(FIRMWARE) || { echo "Firmware not built. Run 'make sdk-build' first."; exit 1; }
	@test -f $(FLASH_IMG) || { echo "Flash image not built. Run 'make sdk-build' first."; exit 1; }
	@echo "Starting TKey (tk1-castor) in QEMU..."
	@echo "Note the PTY path printed below. In another terminal, run:"
	@echo "  ./tkey-devtools/tkey-runapp --port /dev/pts/N --app <app.bin>"
	@echo "To quit QEMU: Ctrl-A then X"
	@echo "---"
	$(QEMU_BIN) $(QEMU_FLAGS)

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
