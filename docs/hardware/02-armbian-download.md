# Downloading and Verifying Armbian

**Date**: 2025-11-30
**Status**: ✅ Completed

This guide documents the process of finding, downloading, and verifying the Armbian image for the Banana Pi F3.

## Official Armbian Page

The official Armbian page for Banana Pi F3 is:
**https://www.armbian.com/bananapi-f3/**

## Available Images (as of 2025-11-30)

Armbian offers several image variants for the Banana Pi F3:

### Recommended: Debian 13 (Trixie) - Stable Current

**Why this choice?**
- Debian Trixie matches the documented system (from ARCHITECTURE.md)
- Current kernel (6.6.99) is stable and well-tested
- Minimal image reduces bloat and security surface
- Same base as our existing deployment

**Download Details:**
- **Distribution**: Debian 13 "Trixie"
- **Type**: Minimal/IOT (essential packages only)
- **Kernel**: 6.6.99-current-spacemit
- **Size**: 258.6 MB
- **Build Date**: November 22, 2025
- **Direct Download**: https://dl.armbian.com/bananapif3/Trixie_current_minimal
- **Torrent**: https://dl.armbian.com/bananapif3/Trixie_current_minimal.torrent

### Alternative Options

#### Ubuntu 24.04 (Noble) - Stable Current
- **Size**: 246.9 MB
- **Kernel**: 6.6.99-current-spacemit
- **Use case**: If you prefer Ubuntu over Debian
- **Download**: https://dl.armbian.com/bananapif3/Noble_current_minimal

#### Edge Kernels (6.17) - Bleeding Edge
- **Not recommended** for production runner
- Active development, may have unreported issues
- Available for both Trixie and Noble

#### Rolling Releases - For Enthusiasts
- **Not recommended** for GitHub runner
- Ubuntu 25.04 (Plucky) available
- Frequent updates, less stability

## Downloading the Image

### Method 1: Direct Download (Recommended)

```bash
# Create download directory
mkdir -p ~/armbian-images
cd ~/armbian-images

# Download Debian Trixie Minimal image
wget https://dl.armbian.com/bananapif3/Trixie_current_minimal

# This downloads a .xz compressed image file
# Example filename: Armbian_25.11.1_Bananapif3_trixie_current_6.6.99_minimal.img.xz
```

### Method 2: Torrent Download (Faster for some)

```bash
# Download via torrent (requires transmission-cli or similar)
wget https://dl.armbian.com/bananapif3/Trixie_current_minimal.torrent
transmission-cli Trixie_current_minimal.torrent
```

## Verifying the Download

**Critical Security Step**: Always verify downloaded images to ensure integrity and authenticity.

### Step 1: Download Verification Files

```bash
# Download SHA256 checksum file
wget https://dl.armbian.com/bananapif3/Trixie_current_minimal.sha

# Download PGP signature (optional but recommended)
wget https://dl.armbian.com/bananapif3/Trixie_current_minimal.asc
```

### Step 2: Verify SHA256 Checksum

```bash
# Check the SHA256 hash
sha256sum -c Armbian_*.img.xz.sha

# Expected output:
# Armbian_25.11.1_Bananapif3_trixie_current_6.6.99_minimal.img.xz: OK
```

If the output shows "OK", the download is intact. If it shows "FAILED", re-download the image.

### Step 3: Verify PGP Signature (Optional but Recommended)

```bash
# Import Armbian GPG key (first time only)
wget https://apt.armbian.com/armbian.key
gpg --import armbian.key

# Verify the signature
gpg --verify Armbian_*.img.xz.asc Armbian_*.img.xz

# Expected output should include:
# gpg: Good signature from "Armbian"
```

**Warning**: If signature verification fails, do not use the image - it may be compromised.

## Understanding Image Naming

Armbian images follow this naming convention:

```
Armbian_[VERSION]_[BOARD]_[DISTRIBUTION]_[KERNEL]_[TYPE].img.xz

Example:
Armbian_25.11.1_Bananapif3_trixie_current_6.6.99_minimal.img.xz
        │         │         │       │       │          │
        │         │         │       │       │          └─ Image type (minimal/desktop)
        │         │         │       │       └─ Kernel version
        │         │         │       └─ Kernel branch (current/edge)
        │         │         └─ Distribution (debian/trixie)
        │         └─ Board name (bananapif3)
        └─ Armbian version (25.11.1)
```

## What's in a Minimal Image?

The **minimal** image includes:
- Base operating system (Debian Trixie)
- Linux kernel 6.6.99-current-spacemit
- Essential system utilities
- SSH server (for remote access)
- Network configuration tools
- Package manager (apt)

**NOT included** (we'll install later):
- Desktop environment
- Docker
- Development tools
- Go compiler
- GitHub runner

This is perfect for our use case - we'll install exactly what we need via Ansible.

## Download Checklist

Before proceeding to SD card preparation, verify:

- [x] Image downloaded successfully (no interruptions)
- [x] SHA256 checksum verified and matches
- [x] PGP signature verified (if checking)
- [x] File size matches expected (~258.6 MB for Trixie minimal)
- [x] File ends with `.img.xz` (compressed image)

## Storage Requirements

- **Downloaded file**: ~259 MB (compressed .xz)
- **Extracted image**: ~1.5-2 GB (uncompressed .img)
- **SD card minimum**: 8 GB (16 GB+ recommended)
- **eMMC target**: 128 GB (built-in on Banana Pi F3)

## Why .xz Compression?

The image is compressed with xz for efficient distribution:
- **Compression ratio**: ~85% (2GB → 259MB)
- **Decompression**: Handled automatically during burning
- **Integrity**: Less data to download = fewer corruption opportunities

## Troubleshooting

### Slow Download Speed

```bash
# Try using a different mirror or torrent
# Armbian uses CDN, so speeds vary by location

# Alternative: Use torrent for better speeds
sudo apt install transmission-cli
transmission-cli Trixie_current_minimal.torrent
```

### Checksum Mismatch

```bash
# Re-download the image
rm Armbian_*.img.xz
wget https://dl.armbian.com/bananapif3/Trixie_current_minimal

# Verify again
sha256sum -c Armbian_*.img.xz.sha
```

### File Corruption During Download

```bash
# Use wget with resume capability
wget -c https://dl.armbian.com/bananapif3/Trixie_current_minimal

# The -c flag allows resuming interrupted downloads
```

## Next Steps

Now that the Armbian image is downloaded and verified:

1. ✅ **Armbian image downloaded**
2. ✅ **Checksum verified**
3. ➡️ **Next**: [Prepare SD card](03-sd-card-setup.md)
4. **Then**: First boot and initial configuration

## Reference Links

- **Armbian Official Site**: https://www.armbian.com/
- **Banana Pi F3 Page**: https://www.armbian.com/bananapi-f3/
- **Download Mirror**: https://dl.armbian.com/bananapif3/
- **Armbian Documentation**: https://docs.armbian.com/
- **Release Notes**: https://www.armbian.com/newsflash/

## Notes for GitHub Runner Use

Why Debian Trixie minimal is optimal for our runner:

**Advantages:**
- ✅ **Minimal footprint** - More disk space for builds
- ✅ **Fewer packages** - Reduced security surface
- ✅ **Faster updates** - Less to update during maintenance
- ✅ **Better performance** - No desktop overhead
- ✅ **Automation-friendly** - Designed for headless use
- ✅ **Stable kernel** - Current (not edge) means tested code
- ✅ **Debian ecosystem** - Excellent package availability

**Runner-Specific Benefits:**
- Minimal install = predictable environment
- No GUI overhead = all resources for builds
- Debian Trixie = latest packages without bleeding edge instability
- Clean slate for Ansible deployment

---

**Completion Status**: Armbian image downloaded and verified
**Time Required**: ~10-20 minutes (depending on download speed)
**Next Guide**: [03-sd-card-setup.md](03-sd-card-setup.md)
