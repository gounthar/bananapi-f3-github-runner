# Hardware Setup Documentation

This directory contains step-by-step guides for the complete hardware setup of the Banana Pi F3 as a GitHub Actions runner.

## Setup Sequence

Follow these guides in order for a complete setup from unboxing to ready-for-automation:

1. **[01-unboxing.md](01-unboxing.md)** - Unboxing the Banana Pi F3, hardware overview, what you need
2. **[02-armbian-download.md](02-armbian-download.md)** - Downloading and verifying Armbian images
3. **[03-sd-card-setup.md](03-sd-card-setup.md)** - Preparing and burning the SD card
4. **[04-first-boot.md](04-first-boot.md)** - Initial boot, user creation, network configuration
5. **[05-emmc-transfer.md](05-emmc-transfer.md)** - Transferring system from SD card to eMMC
6. **[06-ssh-hardening.md](06-ssh-hardening.md)** - SSH key setup and security hardening
7. **[07-system-preparation.md](07-system-preparation.md)** - Final preparation for Ansible deployment

## Quick Reference

### What You'll Need

- Banana Pi F3 board
- Power supply (USB-C, 5V/3A minimum)
- microSD card (16GB+ recommended, Class 10 or better)
- Ethernet cable (for initial setup)
- Computer with SD card reader
- (Optional) USB-to-Serial adapter for console access

### Estimated Time

- Hardware setup: 30 minutes
- SD card preparation: 15-30 minutes
- First boot and configuration: 15-20 minutes
- eMMC transfer: 10-15 minutes
- SSH hardening: 10 minutes
- System preparation: 20-30 minutes

**Total**: ~2-3 hours for complete setup

### Prerequisites

- Basic Linux command line knowledge
- SSH client installed on your computer
- Internet connection for downloads

## After Hardware Setup

Once hardware setup is complete, proceed to the automated Ansible deployment:

```bash
# From project root
ansible-playbook -i inventory.yml playbooks/setup-runner.yml
```

See the main [README.md](../../README.md) for automation details.
