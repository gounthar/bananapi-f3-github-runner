# System Preparation for Automation

**Date**: 2025-11-30
**Status**: ✅ Completed

This guide documents the final system preparation steps before running Ansible automation for GitHub runner installation.

## Why System Preparation?

Before running automated deployment:

**Prerequisites for Ansible:**
- ✅ Python 3.x installed (Ansible runs on Python)
- ✅ pip installed (for Python package management)
- ✅ Git installed (for cloning repositories)
- ✅ Build tools (gcc, make for compiling Go and Docker components)
- ✅ System packages updated (security and stability)
- ✅ Sudo access configured (Ansible needs privilege escalation)

**Prerequisites for GitHub Runner:**
- ✅ Network connectivity to GitHub
- ✅ Sufficient disk space (10GB+ free recommended)
- ✅ Development tools (for building github-act-runner from source)
- ✅ Stable system time (NTP synchronized)

## Prerequisites

Before system preparation:

- [x] System running on eMMC (step 5 complete)
- [x] SSH hardened (step 6 complete)
- [x] SSH access working with key authentication
- [x] Internet connectivity verified
- [x] Sufficient disk space available

## Initial System State Assessment

### Step 1: Check Current System

**Check OS and kernel version:**

```bash
# Check OS release
cat /etc/os-release

# Check kernel version
uname -a
```

**Actual output:**
```
PRETTY_NAME="Armbian 25.11.1 trixie"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
ID=debian
ARMBIAN_PRETTY_NAME="Armbian 25.11.1 trixie"

Linux bananapif3 6.6.99-current-spacemit #2 SMP PREEMPT_DYNAMIC Thu Apr 10 14:00:52 UTC 2025 riscv64 GNU/Linux
```

✅ **Status**: Debian 13 (Trixie), Kernel 6.6.99, RISC-V64

### Step 2: Check Python Installation

**Ansible requires Python 3.x:**

```bash
# Check Python version
python3 --version

# Check pip (might not be installed yet)
pip3 --version || echo "pip3 not installed"
```

**Actual output:**
```
Python 3.13.5
pip3 not installed
```

✅ **Python 3.13.5 installed** (excellent, very modern!)
❌ **pip3 not installed** (needed for package management)

### Step 3: Check Disk Space

**Ensure sufficient space for updates and builds:**

```bash
# Check available disk space
df -h /
```

**Actual output:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk2p1  113G  1.2G  107G   2% /
```

✅ **107GB available** - Plenty of space for runner and builds!

### Step 4: Check for Package Updates

```bash
# Check for available updates
apt list --upgradable 2>/dev/null | head -20
```

**Actual result:**
```
Listing...
```

✅ **No packages to upgrade** - System is already up to date!

## System Update and Package Installation

### Step 1: Update Package Lists

```bash
# Update package lists from repositories
sudo apt update
```

**Actual output summary:**
- Fetched 415 kB in 3s (155 kB/s)
- 1 package can be upgraded (armbian-config)

### Step 2: Upgrade System Packages

```bash
# Upgrade all installed packages
sudo apt upgrade -y
```

**Actual upgrade:**
```
Upgrading:
  armbian-config (25.11.0 → 26.2.0-trunk.13.1124.115722)

Summary:
  Upgrading: 1, Installing: 0, Removing: 0
  Download size: 157 kB
```

✅ **System upgraded** - Only armbian-config needed updating

**Note**: eMMC is much faster than SD card for package operations!

### Step 3: Install Essential Tools

**Install Python, Git, and build tools:**

```bash
# Install essential packages for Ansible and development
# Note: software-properties-common is Ubuntu-specific, not needed on Debian
sudo apt install -y \
    python3-pip \
    python3-venv \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    build-essential
```

**What each package provides:**

**Python ecosystem:**
- `python3-pip` - Python package installer (pip)
- `python3-venv` - Virtual environment support

**Version control:**
- `git` - For cloning repositories (github-act-runner, etc.)

**Security and certificates:**
- `ca-certificates` - SSL/TLS certificates for HTTPS
- `gnupg` - GPG keys for package verification

**System utilities:**
- `lsb-release` - Linux Standard Base release info
- `apt-transport-https` - HTTPS support for APT

**Development tools:**
- `build-essential` - gcc, g++, make, libc-dev (essential for compiling)

**Note**: We intentionally skipped `software-properties-common` - it's Ubuntu-specific for managing PPAs and not needed on Debian/Armbian.

**Installation result:**
```
Installation complete!
```

### Step 4: Verify Installations

```bash
# Verify what was successfully installed
python3 --version
pip3 --version
git --version

# Check if essential build tools are present
gcc --version | head -1
make --version | head -1
```

**Actual verification output:**
```
Python 3.13.5
pip 25.1.1 from /usr/lib/python3/dist-packages/pip (python 3.13)
git version 2.47.3
gcc (Debian 14.2.0-19) 14.2.0
GNU Make 4.4.1
```

✅ **All essential tools installed successfully!**

**Package versions (as of 2025-11-30):**
- Python: 3.13.5 (latest stable)
- pip: 25.1.1 (latest)
- Git: 2.47.3 (very recent)
- GCC: 14.2.0 (modern compiler)
- Make: 4.4.1 (standard)

### Step 5: Check Installed Packages

```bash
# List installed packages we care about
dpkg -l | grep -E "(python3-pip|python3-venv|git|curl|wget|build-essential)" | awk '{print $2, $3}'
```

**Installed packages:**
- curl 8.14.1-2+deb13u2 (already installed)
- wget 1.25.0-2 (already installed)
- python3-pip, python3-venv, git, build-essential (newly installed)

### Step 6: Check Disk Space After Installation

```bash
# Check disk usage after installations
df -h /
```

**Actual result:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk2p1  113G  1.7G  106G   2% /
```

**Disk usage change:**
- Before: 1.2G used
- After: 1.7G used
- **Increase: 500MB** (Python, Git, build tools)
- **Available: 106GB** (still plenty!)

## System Readiness Verification

### Verify Sudo Access

**Ansible needs sudo for privilege escalation:**

```bash
# Check sudo permissions
sudo -l
```

**Actual output:**
```
User poddingue may run the following commands on bananapif3:
    (ALL : ALL) ALL
```

✅ **Full sudo access** - User can run all commands

### Verify System Resources

```bash
# Check system resources
echo "=== System Resources ==="
free -h
df -h /
uptime
```

**Actual output:**
```
=== System Resources ===
               total        used        free      shared  buff/cache   available
Mem:            15Gi       391Mi        14Gi       9.1Mi       866Mi        15Gi
Swap:          7.8Gi          0B       7.8Gi

Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk2p1  113G  1.7G  106G   2% /

 22:50:38 up 26 min,  1 user,  load average: 0.49, 0.27, 0.10
```

**Resource Status:**
- ✅ Memory: 15GB total, 391MB used (2.5% usage)
- ✅ Swap: 7.8GB available (none used - system has plenty of RAM)
- ✅ Disk: 106GB free
- ✅ Load: 0.49 (very light, healthy)
- ✅ Uptime: 26 minutes (stable since eMMC boot)

### Verify Network Connectivity

**Test connectivity to GitHub (needed for runner registration):**

```bash
# Verify network connectivity
echo "=== Network Connectivity ==="
ping -c 3 github.com
```

**Actual output:**
```
PING github.com (140.82.121.3) 56(84) bytes of data.
64 bytes from lb-140-82-121-3-fra.github.com (140.82.121.3): icmp_seq=1 ttl=58 time=13.6 ms
64 bytes from lb-140-82-121-3-fra.github.com (140.82.121.3): icmp_seq=2 ttl=58 time=14.5 ms
64 bytes from lb-140-82-121-3-fra.github.com (140.82.121.3): icmp_seq=3 ttl=58 time=15.4 ms

--- github.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 13.639/14.503/15.364/0.704 ms
```

✅ **GitHub connectivity excellent:**
- 0% packet loss
- Average latency: 14.5ms
- Connected to Frankfurt server (geographically close)

### Verify Hostname and IP

```bash
# Check hostname
echo "=== Hostname ==="
hostname
hostname -I
```

**Actual output:**
```
bananapif3
192.168.1.157 2a01:e0a:5ed:6230:e584:6dd:ad16:35ee 2a01:e0a:5ed:6230:fcfe:feff:fe34:e9ba
```

✅ **Network configuration:**
- Hostname: bananapif3
- IPv4: 192.168.1.157 (DHCP)
- IPv6: Dual addresses (global + link-local)

**Note**: IPv6 support provides better connectivity to modern services.

### Verify Time Synchronization

**Accurate time is critical for API authentication:**

```bash
# Verify timezone and NTP
echo "=== Timezone ==="
timedatectl
```

**Actual output:**
```
               Local time: Sun 2025-11-30 22:50:40 CET
           Universal time: Sun 2025-11-30 21:50:40 UTC
                 RTC time: Sun 2025-11-30 21:50:40
                Time zone: Europe/Paris (CET, +0100)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

✅ **Time synchronization perfect:**
- Timezone: Europe/Paris (CET, correct)
- NTP: Active and synchronized
- System clock: Synced with NTP servers
- RTC: UTC (best practice)

**Why this matters:**
- GitHub API tokens have time-based expiration
- Docker builds use timestamps
- Log correlation requires accurate time
- SSL/TLS certificates validate against system time

## System Readiness Summary

### What We Installed

**System packages:**
- armbian-config (upgraded to 26.2.0)

**Python ecosystem:**
- python3-pip (25.1.1)
- python3-venv (virtual environment support)

**Development tools:**
- git (2.47.3)
- gcc (14.2.0)
- make (4.4.1)
- build-essential (meta-package)

**System utilities:**
- ca-certificates (SSL/TLS support)
- gnupg (GPG key management)
- lsb-release (system info)
- apt-transport-https (HTTPS APT repos)

**Already present:**
- Python 3.13.5
- curl 8.14.1
- wget 1.25.0

### System Status: Ready for Ansible

**✅ All Prerequisites Met:**

**Software:**
- [x] Python 3.13.5 installed
- [x] pip 25.1.1 installed
- [x] Git 2.47.3 installed
- [x] GCC 14.2.0 installed (for compiling Go/Docker)
- [x] Make 4.4.1 installed
- [x] Build tools complete

**System Configuration:**
- [x] Sudo access: Full (ALL:ALL)
- [x] System packages: Up to date
- [x] Disk space: 106GB available
- [x] Memory: 15GB available
- [x] SSH: Hardened and working

**Network:**
- [x] GitHub connectivity: Excellent (14ms)
- [x] IPv4: 192.168.1.157
- [x] IPv6: Enabled (dual stack)
- [x] DNS: Working

**Time:**
- [x] Timezone: Europe/Paris (CET)
- [x] NTP: Active and synchronized
- [x] System clock: Accurate

**Security:**
- [x] SSH: Key-based only, root disabled
- [x] User: poddingue with full sudo
- [x] Firewall: Not configured (can be added via Ansible)

## Pre-Ansible Checklist

Before running the Ansible playbook:

- [x] System updated to latest packages
- [x] Python 3.x installed (3.13.5)
- [x] pip installed (25.1.1)
- [x] Git installed (2.47.3)
- [x] Build tools installed (gcc 14.2.0, make 4.4.1)
- [x] Sudo access configured
- [x] SSH hardened (step 6)
- [x] eMMC boot verified (step 5)
- [x] Network connectivity confirmed
- [x] Time synchronized via NTP
- [x] Hostname set: bananapif3
- [x] At least 10GB free space (have 106GB!)

**System is 100% ready for Ansible automation!** ✅

## What Ansible Will Do

**The Ansible playbook will now:**

1. **Install Docker** from RISC-V64 custom repository
2. **Install Go** (for building github-act-runner)
3. **Build github-act-runner** from source
4. **Configure runner** with GitHub PAT
5. **Create systemd service** for the runner
6. **Start runner** and verify it's registered

**All prerequisites are now in place!**

## Next Steps: Running Ansible

### From Your Local Machine

**Navigate to the repository:**

```bash
cd /path/to/bananapi-f3-github-runner
```

**Configure secrets:**

```bash
# Copy example environment file
cp .env.example .env

# Edit with your secrets
nano .env
```

**Required secrets in `.env`:**
```bash
GITHUB_REPOSITORY=gounthar/docker-for-riscv64
GITHUB_PAT=ghp_your_personal_access_token_here
RUNNER_NAME=bananapi-f3-runner
```

**Run the Ansible playbook:**

```bash
# Run full setup
ansible-playbook -i inventory.yml playbooks/setup-runner.yml

# Or run specific roles
ansible-playbook -i inventory.yml playbooks/setup-runner.yml --tags docker
ansible-playbook -i inventory.yml playbooks/setup-runner.yml --tags github-runner
```

**Monitor the installation:**
- Ansible will connect via SSH (using your configured key)
- Each role will run in sequence
- Tasks will show as [OK], [CHANGED], or [FAILED]
- Total time: ~20-30 minutes (depends on network and build times)

**After Ansible completes:**

```bash
# SSH to the Banana Pi F3
ssh bananapi-f3

# Check runner status
sudo systemctl status github-runner

# View runner logs
sudo journalctl -u github-runner -f
```

**Verify in GitHub:**
- Go to your repository → Settings → Actions → Runners
- You should see "bananapi-f3-runner" listed as online

## Troubleshooting

### Python Not Found

**If Ansible complains about Python:**

```bash
# Verify Python is installed
python3 --version

# Create symlink if needed
sudo ln -s /usr/bin/python3 /usr/bin/python
```

### Sudo Password Prompts

**If Ansible asks for sudo password:**

Edit `inventory.yml` and add:
```yaml
ansible_become_password: "{{ lookup('env', 'BECOME_PASSWORD') }}"
```

Or run with:
```bash
ansible-playbook -i inventory.yml playbooks/setup-runner.yml --ask-become-pass
```

### Disk Space Issues

**If running low on space:**

```bash
# Check what's using space
du -sh /* 2>/dev/null | sort -h

# Clean APT cache
sudo apt clean

# Remove old kernels (if any)
sudo apt autoremove -y
```

### Network Issues

**If GitHub connectivity fails:**

```bash
# Test DNS
nslookup github.com

# Test routing
traceroute github.com

# Check firewall (if configured)
sudo ufw status
```

## Performance Expectations

**On Banana Pi F3 (RISC-V64, 8 cores, 16GB RAM, eMMC):**

**Ansible playbook runtime:**
- Docker installation: ~5 minutes
- Go installation: ~3 minutes
- github-act-runner build: ~10-15 minutes
- Total: ~20-30 minutes

**First GitHub Actions job:**
- Docker pull (if needed): ~5-10 minutes
- Build time: Varies by workload
- Example (Docker Engine): ~35-40 minutes

**System resources during builds:**
- CPU: 100% (all 8 cores utilized)
- Memory: ~8-11GB peak usage
- Disk I/O: Much faster on eMMC vs SD card
- Temperature: Should stay under 60°C with active cooling

## Post-Setup Monitoring

**After the runner is operational:**

```bash
# Monitor runner service
sudo systemctl status github-runner

# View live logs
sudo journalctl -u github-runner -f

# Check Docker status
sudo systemctl status docker

# Monitor system resources during builds
htop

# Check temperature under load
cat /sys/class/thermal/thermal_zone0/temp
```

## Hardware Setup Complete!

**Congratulations!** 🎉

You've completed all 7 hardware setup guides:

1. ✅ Unboxing and assembly
2. ✅ Armbian image download
3. ✅ SD card preparation
4. ✅ First boot and SSH setup
5. ✅ eMMC transfer
6. ✅ SSH hardening
7. ✅ **System preparation** ← You are here!

**Your Banana Pi F3 is now:**
- Running on fast 128GB eMMC (107GB free)
- Secured with SSH key-only authentication
- Equipped with all development tools
- Connected to GitHub with excellent latency
- Time-synchronized and properly configured
- **100% ready for Ansible automation!**

## References

- **Ansible Documentation**: https://docs.ansible.com/
- **Armbian Documentation**: https://docs.armbian.com/
- **GitHub Actions**: https://docs.github.com/en/actions
- **github-act-runner**: https://github.com/ChristopherHX/github-act-runner
- **RISC-V Docker Repo**: https://github.com/gounthar/docker-for-riscv64

---

**Completion Status**: ✅ System preparation completed successfully
**Time Required**: ~15 minutes (mostly package downloads)
**Actual Results**:
- Python: 3.13.5 ✅
- pip: 25.1.1 ✅
- Git: 2.47.3 ✅
- GCC: 14.2.0 ✅
- Disk free: 106GB ✅
- Network: 14ms to GitHub ✅
- NTP: Synchronized ✅

**Next Step**: Run Ansible playbook from your local machine (see main [README.md](../../README.md))
