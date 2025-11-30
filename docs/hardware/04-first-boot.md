# First Boot and Initial Configuration

**Date**: 2025-11-30
**Status**: ✅ Completed

This guide documents the first boot process, initial login, and basic configuration of the Banana Pi F3 with Armbian.

## Hardware Setup

### Our Configuration

**Power Supply:**
- **Device**: Pine64 PinePower Desktop
- **Specifications**: Clean 5V power delivery
- **Link**: https://pine64.org/devices/pinepower_desktop/
- **Why**: Stable, reliable power for SBC workloads

**Network:**
- **Connection**: Gigabit Ethernet (wired)
- **Switch**: TP-LINK TL-SG1048 (48-port managed switch)
- **Interface**: eth0 (primary Ethernet port)

**Storage:**
- **Boot Media**: Amazon Basics 64GB microSD card
- **OS**: Armbian Debian Trixie minimal (6.6.99-current-spacemit)

**Board Configuration:**
- **RAM**: 16GB LPDDR4
- **eMMC**: 128GB (will transfer to this later)
- **Cooling**: 30mm active fan installed

## Pre-Boot Checklist

Before powering on, verify:

- [x] microSD card inserted (with Armbian burned)
- [x] Ethernet cable connected to switch/router
- [x] Fan connected to board
- [x] Antennas attached (if using WiFi later)
- [x] Power supply ready (USB-C)
- [x] No HDMI connected (headless setup via SSH)

## First Boot Process

### Power On

1. **Insert microSD card** into the slot (with burned Armbian image)
2. **Connect Ethernet cable** to eth0 port
3. **Connect USB-C power** to PinePower supply
4. **Board powers on automatically** (no power button)

### What to Expect

**LED Indicators:**
- **Observed behavior**: LEDs blink alternating between red and green during boot
- **This is normal**: Indicates boot process is active
- **When stable**: LEDs should settle once boot completes

**Boot Timeline:**
- **0-10 seconds**: Initial bootloader (U-Boot)
- **10-60 seconds**: Kernel loading
- **60-120 seconds**: First boot initialization
- **~2-3 minutes**: System ready, SSH available

**First boot is slower** because Armbian performs initial setup:
- Resizing filesystem to use full SD card
- Generating SSH host keys
- Initializing system services
- Creating swap space (if configured)

## Finding the IP Address

The Banana Pi F3 will request an IP via DHCP. Several methods to find it:

### Method 1: Check Router/Switch DHCP Leases

**On your router's web interface:**
1. Navigate to DHCP client list
2. Look for hostname: **bananapif3** or **armbian**
3. Note the assigned IP address

**Common router interfaces:**
- http://192.168.1.1 (most common)
- http://192.168.0.1 (alternative)
- http://10.0.0.1 (some ISP routers)

### Method 2: Network Scan (nmap)

```bash
# Scan your local network (adjust range to your subnet)
sudo nmap -sn 192.168.1.0/24

# Look for entry with MAC from Banana Pi
# Or filter by open port 22 (SSH)
sudo nmap -p 22 --open 192.168.1.0/24
```

### Method 3: arp-scan

```bash
# Install arp-scan (if not present)
sudo apt install arp-scan

# Scan local network
sudo arp-scan --localnet

# Look for Banana Pi MAC address or recent addition
```

### Method 4: Check DHCP Server Logs

```bash
# On your router or DHCP server
tail -f /var/log/syslog | grep DHCP
# Or
journalctl -f | grep dhcp
```

### Method 5: Monitor Switch (if managed)

On TP-LINK TL-SG1048 (if managed switch):
1. Access switch management interface
2. Check connected devices / MAC address table
3. Find recently connected device on the port you used

## First SSH Connection

### Default Credentials (Armbian)

**Warning**: These credentials are temporary and **must be changed on first login**.

- **Username**: `root`
- **Password**: `1234`

### Connecting via SSH

```bash
# Replace with the actual IP address you found
ssh root@192.168.1.XXX

# Example:
ssh root@192.168.1.157
```

**First connection warning:**
```
The authenticity of host '192.168.1.157 (192.168.1.157)' can't be established.
ED25519 key fingerprint is SHA256:yvpxxflTLwyETdEF2d/4D9WlpmWvIgDTDvt8gJR4PUo.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

Type `yes` and press Enter.

### Troubleshooting: "Too many authentication failures"

If you see this error:
```
Received disconnect from 192.168.1.157 port 22:2: Too many authentication failures
Disconnected from 192.168.1.157 port 22
```

**Cause**: You have multiple SSH keys in your ssh-agent, and SSH tries them all before password auth.

**Solution**: Disable SSH key authentication for this first connection:

```bash
# Use password authentication only (disable key auth)
ssh -o PubkeyAuthentication=no root@192.168.1.157

# Alternative: Disable all SSH keys for this connection
ssh -o IdentitiesOnly=yes -o IdentityFile=/dev/null root@192.168.1.157
```

After entering `yes` for the fingerprint, you'll be prompted for the password: `1234`

### Initial Login Sequence

**Actual first login experience:**

```
Welcome to Armbian!

Documentation: https://docs.armbian.com | Community support: https://forum.armbian.com

IP address: 192.168.1.157

Create root password: *********
Repeat root password: *********
```

Armbian will immediately require you to:

1. **Change root password**
   - Enter new strong password
   - Confirm the password
   - This replaces the default `1234` password

2. **Create new user account**
   ```
   Please provide a username (eg. your forename): poddingue
   ```
   - Recommend: `poddingue` (matching existing setup)
   - Username should be lowercase, no spaces

3. **Set password for new user**
   ```
   Create password for poddingue:
   Repeat password for poddingue:
   ```

4. **Choose locale and timezone**
   - **Locale**: en_US.UTF-8 (or your preference)
   - **Timezone**: Europe/Paris (or your location)
   - Example: US locale with France timezone is fine for international setups

5. **Choose default shell**
   ```
   Please choose your default shell:
   1) bash
   2) zsh
   ```
   - Recommend: `1` (bash) for consistency with scripts

6. **Optional user details**
   - Real name, room number, phone numbers
   - Can skip these (just press Enter)

## Welcome Screen

After completing the setup wizard, you'll see the Armbian welcome screen:

```
   _             _    _
  /_\  _ _ _ __ | |__(_)__ _ _ _
 / _ \| '_| '  \| '_ \ / _` | ' \
/_/ \_\_| |_|_|_|_.__/_\__,_|_||_|

v25.11.1 for BananaPi BPI-F3 running Armbian Linux 6.6.99-current-spacemit

Packages:     Debian stable (trixie)
IPv4:         (LAN) 192.168.1.157 (WAN) 82.65.177.146
IPv6:         2a01:e0a:5ed:6230:fcfe:feff:fe34:e9ba (WAN) 2a01:e0a:5ed:6230:deee:4eb5:9495:9846

Performance:

Load:         6%                Uptime:       8 minutes
Memory usage: 2% of 15.51G
CPU temp:     29°C              Usage of /:   2% of 58G

Tips:

This Week in Armbian Development https://tinyurl.com/2s37dfk8

Commands:

Configuration : armbian-config
Monitoring    : htop

root@bananapif3:~#
```

**Key observations from this screen:**
- ✅ Armbian v25.11.1 confirmed
- ✅ Kernel 6.6.99-current-spacemit running
- ✅ Debian Trixie stable
- ✅ 15.51GB RAM available (out of 16GB - some reserved for system)
- ✅ 58GB available on SD card (64GB total, some for boot partition)
- ✅ CPU temp at 29°C (excellent - active cooling working)
- ✅ Memory usage at 2% (minimal install = low overhead)
- ✅ IPv4 and IPv6 connectivity established
- ✅ System load at 6% (idle state)

## Initial System Information

After login, check system details:

```bash
# Check Armbian version
cat /etc/armbian-release

# Expected output:
# BOARD=bananapif3
# VERSION=25.11.1
# LINUXFAMILY=spacemit
# BRANCH=current
# ARCH=riscv64
# IMAGE_TYPE=stable
# BOARD_TYPE=conf
# INITRD_ARCH=riscv64
# KERNEL_IMAGE_TYPE=Image
```

```bash
# Verify architecture
uname -m
# Output: riscv64

# Check kernel version
uname -r
# Output: 6.6.99-current-spacemit

# Check OS
cat /etc/os-release
# Debian GNU/Linux 13 (trixie)
```

```bash
# Check memory
free -h
# Should show ~16GB total

# Check storage
df -h
# Shows SD card partitions
```

```bash
# Check network
ip addr show
# Shows eth0 with your IP

# Test internet connectivity
ping -c 4 8.8.8.8
```

## Essential First Steps

### 1. Update System Time

```bash
# Check current time
date

# Set timezone (example: Europe/Paris)
sudo timedatectl set-timezone Europe/Paris

# Or list all timezones
timedatectl list-timezones | grep -i paris

# Enable NTP for automatic time sync
sudo timedatectl set-ntp true
```

### 2. Update Package Database

```bash
# Update package lists
sudo apt update

# Check for available upgrades (don't upgrade yet)
apt list --upgradable
```

**Note**: Don't do full upgrade yet - we'll do that in step 7 (system-preparation.md)

### 3. Set Hostname (Optional)

```bash
# Current hostname
hostnamectl

# Change if desired (example: bananapi-f3-runner)
sudo hostnamectl set-hostname bananapi-f3-runner

# Edit /etc/hosts to match
sudo nano /etc/hosts
# Change: 127.0.1.1 armbian
# To:     127.0.1.1 bananapi-f3-runner
```

### 4. Configure Network (If Needed)

For static IP instead of DHCP:

```bash
# Edit network configuration
sudo nano /etc/network/interfaces

# Or use NetworkManager (if installed)
sudo nmtui
```

**For now**: DHCP is fine. We can set static IP later if needed.

## Verifying SSH Access

### Test SSH with New User

```bash
# From your computer, SSH as new user
ssh poddingue@192.168.1.XXX

# Should work with password you created
```

### Recommended: Set Up SSH Keys

For password-less login (essential for automation and Ansible):

#### Step 1: Generate SSH Key

On your **local machine** (not the Banana Pi):

```bash
# Generate a new ED25519 key (most secure and efficient)
ssh-keygen -t ed25519 -C "bananapi-f3-runner" -f ~/.ssh/bananapi-f3

# You'll be prompted:
# Enter passphrase (empty for no passphrase): [optional but recommended]
# Enter same passphrase again: [confirm]
```

This creates:
- `~/.ssh/bananapi-f3` (private key - keep secret!)
- `~/.ssh/bananapi-f3.pub` (public key - safe to share)

#### Step 2: Copy Public Key to Banana Pi

**Important**: Due to multiple keys in ssh-agent, use this exact command:

```bash
# Copy the key with PubkeyAuthentication disabled
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/bananapi-f3.pub poddingue@192.168.1.157
```

Enter your password when prompted (the one you created for user `poddingue`).

Expected output:
```
Number of key(s) added: 1

Now try logging into the machine...
```

#### Step 3: Test Key-Based Login

```bash
# Test with IdentitiesOnly to use only this specific key
ssh -o IdentitiesOnly=yes -i ~/.ssh/bananapi-f3 poddingue@192.168.1.157

# Should connect without password (may ask for key passphrase if you set one)
```

#### Step 4: Add SSH Config for Convenience

Add configuration to `~/.ssh/config`:

```bash
cat >> ~/.ssh/config << 'EOF'

Host bananapi-f3
    HostName 192.168.1.157
    User poddingue
    IdentityFile ~/.ssh/bananapi-f3
    IdentitiesOnly yes

EOF
```

Now you can simply use:

```bash
ssh bananapi-f3
# Connects directly without specifying IP, user, or key file
```

#### Why IdentitiesOnly=yes?

If you have multiple SSH keys in your ssh-agent, SSH will try them all before attempting password authentication. The server may disconnect after too many failed attempts. Using `IdentitiesOnly=yes` forces SSH to use only the specified key file.

## System Resource Check

```bash
# CPU information
lscpu

# Expected output:
# Architecture:        riscv64
# CPU(s):              8
# Model name:          Spacemit(R) X60
# Thread(s) per core:  1
# Core(s) per socket:  8
```

```bash
# Check disk space
df -h /
# Should show ~1.5GB used, plenty free on 64GB card

# Check memory usage
free -h
# Minimal install should use ~200-300MB
```

```bash
# Check running services
systemctl list-units --type=service --state=running
```

## Important Configuration Notes

### Root Login via SSH

By default, Armbian allows root login via SSH. This will be disabled later for security.

**Current state**: Root login allowed (temporary)
**Future state**: Disable root SSH (step 6: ssh-hardening.md)

### Firewall Status

```bash
# Check if firewall is active
sudo ufw status

# Usually inactive on fresh install
# We'll configure in step 6 (ssh-hardening.md)
```

### Network Configuration

```bash
# Check network interface names
ip link show

# Expected:
# eth0: Gigabit Ethernet (connected)
# eth1: Second Gigabit Ethernet (unused)
# wlan0: WiFi (if configured)
```

## Current Network Setup

**For our GitHub runner:**
- **Interface**: eth0 (primary Gigabit Ethernet)
- **IP Assignment**: DHCP (from router)
- **DNS**: Provided by DHCP
- **Switch**: TP-LINK TL-SG1048 (48-port)
- **Port Speed**: 1000 Mbps (Gigabit)

**Verify connection:**
```bash
# Check link status
ethtool eth0 | grep Speed
# Should show: Speed: 1000Mb/s

# Check connectivity
ping -c 4 google.com
```

## Troubleshooting

### Can't Find IP Address

```bash
# Connect HDMI and keyboard temporarily
# Login at console: root / [password-you-set]
# Check IP with: ip addr show eth0
```

### Can't SSH - Connection Refused

```bash
# Check if SSH service is running
sudo systemctl status sshd
# Or
sudo systemctl status ssh

# Start if stopped
sudo systemctl start ssh
```

### Wrong Password on First Login

- Default is `1234` (if not changed yet)
- If changed but forgotten, need console access (HDMI + keyboard)
- Can reset root password from console

### Network Not Working

```bash
# Check if eth0 has IP
ip addr show eth0

# Check if cable is connected
ethtool eth0 | grep "Link detected"
# Should show: Link detected: yes

# Restart networking
sudo systemctl restart networking
```

### Slow Boot

- First boot takes 2-3 minutes (normal)
- Filesystem resize happens on first boot
- Subsequent boots faster (30-60 seconds)

## Post-Boot Checklist

After successful first boot:

- [x] System booted successfully (LEDs blinking red/green)
- [x] Found IP address via DHCP (192.168.1.157)
- [x] SSH connection established (with PubkeyAuthentication=no workaround)
- [x] Root password changed
- [x] New user created (poddingue)
- [x] Locale configured (en_US.UTF-8)
- [x] Timezone configured (Europe/Paris)
- [x] Network connectivity verified (ping 8.8.8.8 working)
- [x] System information checked (riscv64, 6.6.99-current-spacemit)
- [x] SSH keys generated and installed
- [x] SSH config created for easy access
- [x] Password-less SSH login working

## What We Have Now

**Running System:**
- ✅ Armbian Debian Trixie minimal
- ✅ Kernel 6.6.99-current-spacemit
- ✅ RISC-V64 architecture confirmed
- ✅ Network configured (DHCP)
- ✅ SSH access working
- ✅ User account created

**Still on SD Card:**
- Current boot: microSD (64GB)
- Next step: Transfer to eMMC (128GB, faster)

## Next Steps

Now that the system is booted and accessible:

1. ✅ **First boot complete**
2. ✅ **SSH access configured**
3. ✅ **Basic system setup done**
4. ➡️ **Next**: [Transfer to eMMC](05-emmc-transfer.md)
5. **Then**: SSH hardening and security

## Reference Information

**Network Details (for this setup):**
- **IP Address**: 192.168.1.XXX (DHCP assigned)
- **Gateway**: 192.168.1.1 (typical)
- **DNS**: From DHCP
- **Hostname**: bananapif3 (or custom)

**User Accounts:**
- `root`: System administrator (SSH access limited later)
- `poddingue`: Regular user (will run GitHub runner)

**SSH Access:**
- Port: 22 (default)
- Password auth: Enabled (will add keys later)
- Root login: Enabled (will disable later)

---

**Completion Status**: System booted and accessible via SSH
**Time Required**: ~5-10 minutes (boot + initial config)
**Next Guide**: [05-emmc-transfer.md](05-emmc-transfer.md)
