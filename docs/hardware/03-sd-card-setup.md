# SD Card Preparation and Image Burning

**Date**: 2025-11-30
**Status**: 🔄 In Progress

This guide documents preparing the microSD card and burning the Armbian image to it.

## SD Card Selection

For this setup, we're using:
- **Brand**: Amazon Basics microSD Card
- **Capacity**: 64GB
- **Model**: SKU B08TJTB8XS
- **Review Source**: [Bret.dk Review](https://bret.dk/is-the-amazon-basics-microsd-card-still-worth-it/)
- **Rating**: 5-star reviewed

### Why This Card Works

**Requirements for Banana Pi F3:**
- ✅ **Minimum 8GB** (64GB exceeds requirement)
- ✅ **Class 10 or better** (for adequate write speeds)
- ✅ **Reliable brand** (Amazon Basics reviewed positively)

**Usage Notes:**
- SD card is temporary - we'll transfer to eMMC in step 5
- 64GB is overkill for boot media, but good for general use later
- Faster cards (UHS-I, A1/A2) improve boot time but not required

## Before You Begin

### What You'll Need

1. **microSD card** - Amazon Basics 64GB (or similar)
2. **SD card reader** - Built-in or USB adapter
3. **Computer** - Linux, macOS, or Windows
4. **Armbian image** - Downloaded from step 2 (Trixie_current_minimal)
5. **Administrative access** - For writing to storage devices

### Important Warnings

⚠️ **DATA DESTRUCTION WARNING**: Burning an image will completely erase the SD card. Back up any important data first.

⚠️ **DEVICE SELECTION**: Double-check you're writing to the correct device. Writing to the wrong device can destroy your hard drive.

## Method 1: Linux (Command Line)

This is the most common method for Linux users and works well on WSL2.

### Step 1: Insert SD Card and Identify Device

```bash
# Before inserting the SD card
lsblk

# Insert the SD card, then run again to see what's new
lsblk

# Look for a device that matches your SD card size
# Common names: /dev/mmcblk0, /dev/sdb, /dev/sdc
```

**Example output:**
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0 238.5G  0 disk
├─sda1        8:1    0   512M  0 part /boot/efi
└─sda2        8:2    0   238G  0 part /
sdb           8:16   1  59.5G  0 disk          ← This is the 64GB SD card
└─sdb1        8:17   1  59.5G  0 part
```

### Step 2: Unmount SD Card (if mounted)

```bash
# If the card auto-mounted, unmount it (replace /dev/sdb1 with your device)
sudo umount /dev/sdb1

# Or unmount all partitions on the device
sudo umount /dev/sdb*
```

### Step 3: Burn the Image

```bash
# Navigate to where you downloaded the Armbian image
cd ~/armbian-images

# Burn the image (replace /dev/sdb with YOUR SD card device)
# xzcat decompresses on-the-fly
xzcat Armbian_*.img.xz | sudo dd of=/dev/sdb bs=4M status=progress conv=fsync

# This will take several minutes
# Progress will show: bytes written and transfer speed
```

**Important Notes:**
- Use the **device name** (e.g., `/dev/sdb`), NOT a partition (e.g., `/dev/sdb1`)
- `bs=4M` sets block size for faster writes
- `status=progress` shows progress (omit on older systems)
- `conv=fsync` ensures data is fully written

### Step 4: Verify the Write

```bash
# Ensure all data is written to the card
sync

# Optional: Verify the write (takes a while)
# This reads back the written image and compares
sudo dd if=/dev/sdb bs=4M count=<image-size-in-MB/4> | xz > /tmp/verify.img.xz
sha256sum /tmp/verify.img.xz
# Compare with original image checksum
```

### Step 5: Safely Eject

```bash
# Eject the SD card
sudo eject /dev/sdb

# Now physically remove the card
```

## Method 2: macOS (Command Line)

Similar to Linux but uses slightly different commands.

### Step 1: Identify Device

```bash
# List disks before inserting
diskutil list

# Insert SD card, then list again
diskutil list

# Look for /disk2 or /disk3 (not /disk0 which is your Mac's drive!)
```

### Step 2: Unmount and Burn

```bash
# Unmount (but don't eject)
diskutil unmountDisk /dev/disk2

# Burn the image (use /dev/rdisk2 for faster writing)
xzcat Armbian_*.img.xz | sudo dd of=/dev/rdisk2 bs=4m

# Note: macOS uses lowercase 'm' in bs=4m
```

### Step 3: Eject

```bash
sudo diskutil eject /dev/disk2
```

## Method 3: Windows (Balena Etcher - Graphical)

The easiest method for Windows users.

### Step 1: Download Balena Etcher

1. Visit: https://etcher.balena.io/
2. Download the Windows installer
3. Install Balena Etcher

### Step 2: Burn Image

1. **Launch Balena Etcher**
2. **Flash from file**: Click and select your `Armbian_*.img.xz` file
3. **Select target**: Choose your SD card (Etcher shows size to help identify)
4. **Flash!**: Click Flash button
5. **Wait**: Progress bar shows writing and verification
6. **Done**: Etcher auto-unmounts when complete

**Advantages:**
- ✅ Graphical interface
- ✅ Automatic decompression
- ✅ Built-in verification
- ✅ Hard to select wrong device (shows removable drives only)

## Method 4: Windows (Rufus)

Alternative GUI tool for Windows.

### Step 1: Download Rufus

1. Visit: https://rufus.ie/
2. Download the portable version
3. Run Rufus (no installation needed)

### Step 2: Configure and Burn

1. **Device**: Select your SD card
2. **Boot selection**: Click SELECT and choose the `.img.xz` file
3. **Partition scheme**: Leave default (GPT)
4. **File system**: Leave default
5. **Click START**: Rufus will decompress and write
6. **Wait**: Progress bar shows status
7. **Close**: When done, close Rufus and eject card

## Method 5: Raspberry Pi Imager

Works on Windows, macOS, and Linux - specifically designed for SBC images.

### Step 1: Install

Download from: https://www.raspberrypi.com/software/

### Step 2: Burn Image

1. **Choose Device**: Select "No filtering" (it's not a Pi)
2. **Choose OS**: Scroll down → "Use custom" → Select your Armbian `.img.xz`
3. **Choose Storage**: Select your SD card
4. **Write**: Click Write button
5. **Wait**: Progress and verification run automatically
6. **Done**: Eject when complete

## Verification After Burning

After burning, the SD card should have two partitions visible:

### On Linux:
```bash
lsblk

# You should see something like:
# sdb           8:16   1  59.5G  0 disk
# ├─sdb1        8:17   1   256M  0 part  ← Boot partition (FAT32)
# └─sdb2        8:18   1   1.5G  0 part  ← Root filesystem (ext4)
```

### On Windows/macOS:
- You may only see the boot partition (FAT32)
- The Linux partition (ext4) won't be readable - this is normal

## Troubleshooting

### "Permission denied" Error (Linux/macOS)

```bash
# Use sudo for dd command
sudo dd if=image.img of=/dev/sdb ...
```

### "Device is busy" Error

```bash
# Unmount all partitions first
sudo umount /dev/sdb*

# Then try burning again
```

### Write Seems Stuck at 0%

- **Normal for xzcat**: Decompression happens first, then writing starts
- **Wait**: First progress may take 30-60 seconds
- **Patience**: Full process takes 5-10 minutes for 2GB image

### SD Card Not Detected

- Try a different USB port
- Try a different card reader
- Ensure card is fully inserted
- Check if card is write-protected (physical switch)

### Verification Failed (Balena Etcher)

- Try burning again
- Check SD card health (may be defective)
- Try a different SD card

## Post-Burn Checklist

Before removing the SD card:

- [x] Burning completed without errors
- [x] Verification passed (if using Etcher/Imager)
- [x] Data synced to disk (`sync` command or safe eject)
- [x] Card properly ejected/unmounted
- [x] Ready to insert into Banana Pi F3

## What's on the SD Card Now?

After burning, the SD card contains:

1. **Boot Partition** (FAT32, ~256MB)
   - Bootloader (U-Boot)
   - Linux kernel
   - Device tree files
   - Boot configuration

2. **Root Partition** (ext4, ~1.5GB)
   - Debian Trixie minimal filesystem
   - Essential system utilities
   - SSH server
   - Package manager (apt)

## Performance Considerations

**Boot time from SD card:**
- First boot: 2-3 minutes (initial setup)
- Subsequent boots: 30-60 seconds
- eMMC will be faster (we'll transfer in step 5)

**SD card life for runner use:**
- ❌ **Not recommended** for long-term runner operation
- ✅ **Perfect** for initial setup and boot
- ✅ **Transfer to eMMC** for production use (much better endurance)

## Why We Transfer to eMMC Later

The Banana Pi F3 has 128GB eMMC onboard. We use SD card only for initial boot because:

1. **Speed**: eMMC is much faster than SD card
2. **Reliability**: eMMC has better wear leveling
3. **Endurance**: eMMC handles write-heavy workloads better
4. **Performance**: Lower latency for Docker builds

## Important: Power Supply Requirements

Before first boot, ensure you have adequate power:

**Minimum Requirements:**
- **Voltage**: 5V regulated
- **Current**: 3A minimum (5A strongly recommended)
- **Connector**: USB Type-C

**Recommended:**
- Quality USB-C power supply (5V/5A)
- USB-C PD (Power Delivery) charger works well
- Avoid cheap phone chargers (insufficient current)

**Why this matters:**
- Underpowered supply causes instability
- Can cause random reboots during builds
- May prevent proper boot
- Critical for 8-core CPU under load

See [BANANA-PI-F3-REFERENCE.md](../BANANA-PI-F3-REFERENCE.md) for full hardware specifications.

## Next Steps

Now that the SD card is prepared:

1. ✅ **SD card burned with Armbian**
2. ✅ **Image verified**
3. ⚠️ **Ensure**: Adequate power supply (5V/5A recommended)
4. ➡️ **Next**: [Insert card and first boot](04-first-boot.md)
5. **Then**: Configure network and create user account

## References

- **Balena Etcher**: https://etcher.balena.io/
- **Rufus**: https://rufus.ie/
- **Raspberry Pi Imager**: https://www.raspberrypi.com/software/
- **Amazon Basics SD Card Review**: https://bret.dk/is-the-amazon-basics-microsd-card-still-worth-it/

---

**Completion Status**: Ready to burn SD card
**Time Required**: ~10-15 minutes (burning + verification)
**Next Guide**: [04-first-boot.md](04-first-boot.md)
