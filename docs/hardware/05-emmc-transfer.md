# Transferring System to eMMC

**Date**: 2025-11-30
**Status**: ✅ Completed

This guide documents transferring the Armbian system from the SD card to the internal 128GB eMMC storage.

## Why Transfer to eMMC?

The Banana Pi F3 has 128GB of fast eMMC storage onboard. Transferring from SD card to eMMC provides:

**Performance Benefits:**
- ⚡ **Faster boot times** - eMMC is much faster than SD cards
- ⚡ **Better I/O performance** - Lower latency for Docker builds
- ⚡ **Faster package operations** - apt update/upgrade much quicker
- ⚡ **Better Docker performance** - Container layer operations faster

**Reliability Benefits:**
- 🛡️ **Better wear leveling** - eMMC designed for more write cycles
- 🛡️ **More durable** - Better suited for CI/CD workloads
- 🛡️ **No accidental removal** - Internal storage, can't be bumped loose
- 🛡️ **Better endurance** - Handles frequent writes better than SD cards

**Capacity:**
- 📦 **128GB eMMC** vs 64GB SD card
- More space for Docker images and build caches

## Prerequisites

Before starting the transfer:

- [x] System booted successfully from SD card
- [x] SSH access working
- [x] Internet connectivity verified
- [x] At least 10-15 minutes available
- [x] Backup any important data (though system is fresh)

## Current System Status

Check your current storage:

```bash
# View current disk usage
df -h

# Check block devices
lsblk

# You should see:
# - mmcblk0: SD card (currently booted)
# - mmcblk1: eMMC (target for transfer)
```

## Method 1: Using armbian-config (Recommended)

Armbian provides a user-friendly configuration tool with a menu-driven interface.

### Step 1: Launch armbian-config

```bash
# Must run as root or with sudo
sudo armbian-config
```

This launches a text-based menu interface.

### Step 2: Navigate to System Menu

- Use arrow keys to navigate
- Select **"System"** from the main menu
- Press Enter

### Step 3: Select Install Option

- Look for option: **"Install"** or **"Install to eMMC/USB/SATA"**
- Press Enter

### Step 4: Choose Boot from eMMC

You'll be presented with options:
1. **Boot from eMMC - system on eMMC** ← Choose this
2. Boot from SD - system on USB/SATA
3. Boot from USB - system on USB

Select option 1: **Boot from eMMC - system on eMMC**

### Step 5: Choose Filesystem Type

**Actual choice made**: ext4

Recommended: **ext4** (most common, well-tested)

Options typically include:
- **ext4** (recommended) ← We chose this
- btrfs (advanced features, but less tested on SBCs)
- f2fs (flash-optimized, but ext4 is more stable)

### Step 6: Confirm the Transfer

**⚠️ WARNING**: This will erase all data on the eMMC!

The tool will:
1. Format the eMMC
2. Copy the entire root filesystem from SD to eMMC
3. Install bootloader to eMMC
4. Update boot configuration

**Estimated time**: 5-10 minutes depending on data size

### Step 7: Monitor Progress

**Actual experience**: The transfer process runs automatically and displays progress.

You'll see:
- Formatting partitions
- Copying files (this is the longest part)
- Installing bootloader
- Updating boot configuration

**Do not interrupt this process!**

**Completion message**: "All done. Power off"

**Actual time taken**: ~5-10 minutes (varies by data size)

### Step 8: Power Off

When complete, the tool will prompt you to power off:

```bash
# Power off the system
sudo poweroff
```

### Step 9: Remove SD Card

**CRITICAL**: The Banana Pi F3 boots from SD card first if present!

1. Wait for system to fully power down (all LEDs off)
2. **Physically remove the microSD card**
3. Store the SD card safely (it's a working backup!)

**Common mistake**: Forgetting to remove the SD card. The system will boot from SD instead of eMMC if the card is still inserted, even after transfer!

### Step 10: Power On from eMMC

1. Ensure SD card is removed
2. Power on the Banana Pi F3
3. It will now boot from eMMC

## Method 2: Using nand-sata-install Directly

Alternative command-line method:

```bash
# Run the installation script directly
sudo nand-sata-install
```

Follow the interactive prompts (similar to armbian-config method).

## After Transfer: First Boot from eMMC

### Verify Boot Source

After booting from eMMC, verify:

```bash
# Check which device is mounted as root
lsblk

# Root (/) should now be on mmcblk1 (eMMC), not mmcblk0 (SD)
```

**Actual output after successful transfer:**
```
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
mmcblk2      179:0    0 116.5G  0 disk
└─mmcblk2p1  179:1    0 115.3G  0 part /var/log.hdd
                                       /
mmcblk2boot0 179:8    0     4M  1 disk
mmcblk2boot1 179:16   0     4M  1 disk
zram0        250:0    0   7.8G  0 disk [SWAP]
zram1        250:1    0    50M  0 disk /var/log
```

**Key points:**
- Root (/) is on **mmcblk2p1** (eMMC, 115.3G)
- No mmcblk0 in the output (SD card removed)
- Boot partitions visible: mmcblk2boot0 and mmcblk2boot1

### Check Available Space

```bash
# Check disk space on eMMC
df -h /
```

**Actual output:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk2p1  113G  1.2G  107G   2% /
```

**Comparison to SD card:**
- **Before (SD)**: 58G total, 56G available
- **After (eMMC)**: 113G total, 107G available
- **Gain**: Nearly 2x the storage capacity!

### Verify System Performance

```bash
# Test disk I/O speed
sudo hdparm -tT /dev/mmcblk1

# Compare with SD card (if you reconnect it later)
# eMMC should be significantly faster
```

### Check SSH Access Still Works

```bash
# From your local machine
ssh bananapi-f3

# Verify system info
hostname
uptime
free -h
cat /sys/class/thermal/thermal_zone0/temp
```

**Actual verification after eMMC boot:**
```
bananapif3
 22:25:41 up 1 min,  1 user,  load average: 0.13, 0.07, 0.03
               total        used        free      shared  buff/cache   available
Mem:            15Gi       366Mi        15Gi       9.1Mi       154Mi        15Gi
Swap:          7.8Gi          0B       7.8Gi
26000
```

**Status**:
✅ SSH working perfectly
✅ Hostname preserved: bananapif3
✅ Memory usage: 2% (366MB / 15GB)
✅ Temperature: 26°C (excellent cooling)
✅ Same IP address via DHCP (192.168.1.157)

## What Happens During Transfer?

### The Transfer Process

1. **Partition Creation**
   - Creates boot partition (~256MB, FAT32)
   - Creates root partition (remaining space, ext4)

2. **File Copy**
   - Copies entire root filesystem
   - Preserves all files, permissions, users
   - Includes all configurations you made

3. **Bootloader Installation**
   - Installs U-Boot to eMMC
   - Configures boot parameters
   - Sets eMMC as primary boot device

4. **Boot Configuration**
   - Updates kernel boot arguments
   - Configures device tree
   - Sets up initramfs

### What's Preserved

✅ **Everything is copied:**
- All system files
- User accounts (root, poddingue)
- SSH keys and authorized_keys
- Network configuration
- Timezone and locale settings
- All installed packages

### What Changes

- **Boot device**: SD card → eMMC
- **Device names**: /dev/mmcblk0 → /dev/mmcblk1
- **Performance**: Much faster
- **Available space**: 58GB → ~110GB

## Troubleshooting

### System Won't Boot After Transfer

**Symptom**: No boot, blank screen

**Solutions:**
1. Re-insert SD card and boot from it (your backup!)
2. Try the transfer process again
3. Check if SD card is still inserted (remove it)

### Wrong Disk Being Used

**Check current root device:**
```bash
mount | grep "on / "

# Should show: /dev/mmcblk1p2 on / type ext4
# If shows mmcblk0, you're still on SD card
```

### IP Address Changed

If the system gets a different IP after reboot:

```bash
# Find new IP from router/DHCP server
# Or connect HDMI + keyboard and run:
ip addr show eth0

# Update your SSH config
nano ~/.ssh/config
# Update the HostName line
```

### Transfer Failed/Interrupted

**If transfer was interrupted:**
1. Boot from SD card (eMMC may be partially written)
2. Run the transfer process again
3. eMMC will be reformatted and transfer will restart

## Performance Comparison

### Before (SD Card)

```bash
# Typical SD card speeds
Read:  20-40 MB/s
Write: 10-20 MB/s
```

### After (eMMC)

```bash
# Typical eMMC speeds on Banana Pi F3
Read:  100-150 MB/s
Write: 50-80 MB/s
```

**Result**: 3-5x faster storage performance!

## What to Do with the SD Card

**Keep it as a backup!** The SD card has a working Armbian system that you can:

1. **Emergency recovery** - Boot from SD if eMMC has issues
2. **Testing** - Test risky changes on SD before applying to eMMC
3. **Backup** - It's a snapshot of a working system
4. **Reinstall** - Fresh start if needed

**Label it**: "Armbian Trixie - BPI-F3 - Working Backup"

## Post-Transfer Checklist

After successful transfer to eMMC:

- [x] System boots from eMMC (SD card removed)
- [x] Root partition is on mmcblk2p1 (115.3GB eMMC)
- [x] Available space ~107GB (vs 56GB on SD)
- [x] SSH access works (same IP: 192.168.1.157)
- [x] Network connectivity verified
- [x] User accounts intact (poddingue login works)
- [x] SSH keys still work (ED25519 key authentication)
- [x] System running cool at 26°C
- [x] Memory usage normal (2% / 15GB)

**Transfer completed successfully!** ✅

## Next Steps

Now that you're running on eMMC:

1. ✅ **System transferred to eMMC**
2. ✅ **Performance improved significantly**
3. ➡️ **Next**: [SSH Security Hardening](06-ssh-hardening.md)
4. **Then**: System preparation and package updates

## Important Notes

### Boot Priority

The Banana Pi F3 boot order is:
1. SD card (if present)
2. eMMC (if no SD card)
3. USB (if configured)

**Always remove the SD card** when you want to boot from eMMC!

### Reverting to SD Card

To boot from SD card again:
1. Power off
2. Insert SD card
3. Power on
4. System will boot from SD instead of eMMC

### Future Updates

After this transfer, ALL system updates, package installations, and configurations happen on eMMC. The SD card remains as it was at transfer time (a snapshot).

---

**Completion Status**: ✅ Transfer completed successfully
**Time Required**: ~15-20 minutes (transfer + reboot + verification)
**Actual Results**:
- eMMC filesystem: 113G total, 107G available
- Boot time: ~1 minute from power on
- Temperature: 26°C (excellent)
- All configuration preserved perfectly

**Next Guide**: [06-ssh-hardening.md](06-ssh-hardening.md)
