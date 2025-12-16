# Manual Setup Guide for Banana Pi F3 GitHub Actions Runner

This guide provides step-by-step instructions for manually setting up a Banana Pi F3 as a GitHub Actions self-hosted runner.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial System Setup](#initial-system-setup)
3. [Install Required Packages](#install-required-packages)
4. [Configure Docker](#configure-docker)
5. [Build GitHub Act Runner](#build-github-act-runner)
6. [Configure the Runner](#configure-the-runner)
7. [Set Up Systemd Service](#set-up-systemd-service)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

- Banana Pi F3 with Armbian installed (Debian Trixie recommended)
- SSH access to the device
- Sudo privileges
- GitHub repository with admin access
- GitHub Personal Access Token (PAT)

### Create GitHub PAT

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
   - `admin:org` (if using organization runner)
4. Generate and save the token securely

## Initial System Setup

### 1. Update System

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

### 2. Set Hostname (Optional)

```bash
sudo hostnamectl set-hostname bananapi-f3-runner
```

### 3. Configure Timezone

```bash
sudo timedatectl set-timezone YOUR_TIMEZONE
# Example: sudo timedatectl set-timezone Europe/Paris
```

### 4. Create Runner User (if not using existing)

```bash
# Skip this if you're using your existing user account
sudo useradd -m -s /bin/bash runner
sudo usermod -aG sudo runner
sudo passwd runner
```

## Install Required Packages

### 1. Install Core Build Tools

```bash
sudo apt install -y build-essential gcc g++ make cmake \
    autoconf automake libtool pkg-config git git-lfs
```

### 2. Install Go

```bash
# Add Go repository (if not available)
sudo add-apt-repository ppa:longsleep/golang-backports -y || true
sudo apt update

# Install Go
sudo apt install -y golang-1.24 golang-1.24-go golang-1.24-src
```

Verify Go installation:

```bash
go version
# Expected: go version go1.24.4 linux/riscv64
```

### 3. Install Docker

```bash
# Install Docker packages
sudo apt install -y docker.io docker-cli docker-compose-plugin \
    docker-buildx-plugin containerd runc

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
# Or run: newgrp docker
```

Verify Docker installation:

```bash
docker --version
docker compose version
docker buildx version
```

### 4. Install Packaging Tools

#### Debian Packaging

```bash
sudo apt install -y debhelper dh-make dpkg-dev lintian \
    devscripts libdistro-info-perl fakeroot quilt reprepro
```

#### RPM Packaging

```bash
sudo apt install -y rpm rpm-common rpm2cpio rpmbuild rpmlint \
    python3-rpm createrepo-c
```

### 5. Install GitHub CLI

```bash
# GitHub CLI should be in Debian repos
sudo apt install -y gh

# Or install from GitHub releases if needed
# curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
#     sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
#     sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
# sudo apt update
# sudo apt install -y gh
```

### 6. Install Python and pip

**Important**: On Debian 13 (Trixie), Python 3.13 is pre-installed but pip is not.

```bash
# Install pip and virtual environment support
sudo apt install -y python3-pip python3-venv

# Verify installation
python3 --version   # Python 3.13.5
pip3 --version      # pip 25.1.1
```

### 7. Install Utilities

```bash
sudo apt install -y curl wget jq htop tmux vim nano \
    net-tools iputils-ping dnsutils ca-certificates openssl
```

## Configure Docker

### 1. Configure Docker Daemon

Create `/etc/docker/daemon.json`:

```bash
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "features": {
    "buildkit": true
  }
}
EOF
```

### 2. Restart Docker

```bash
sudo systemctl restart docker
```

### 3. Test Docker

```bash
docker run --rm hello-world
docker run --rm riscv64/alpine:latest uname -m
# Expected: riscv64
```

## Build GitHub Act Runner

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/ChristopherHX/github-act-runner.git
cd github-act-runner
```

### 2. Build Binary

```bash
go build -o github-act-runner
```

This will take several minutes. The binary will be created in the current directory.

### 3. Verify Build

```bash
./github-act-runner --version
ls -lh github-act-runner
# Binary should be ~25MB
```

## Configure the Runner

### 1. Create Working Directory

```bash
mkdir -p ~/github-act-runner-test
cd ~/github-act-runner-test

# Copy the built binary
cp ~/github-act-runner/github-act-runner .
chmod +x github-act-runner
```

### 2. Register Runner

You have two options: interactive configuration or using environment variables.

#### Option A: Interactive Configuration

```bash
./github-act-runner configure
```

Follow the prompts:
- Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO`
- Runner name: `bananapi-f3-runner` (or your choice)
- Labels: Leave default (self-hosted, linux, riscv64) or add custom
- Work folder: `_work` (default)

#### Option B: Environment Variables

```bash
export GITHUB_REPOSITORY="https://github.com/YOUR_USERNAME/YOUR_REPO"
export GITHUB_PAT="ghp_YOUR_PERSONAL_ACCESS_TOKEN"
export RUNNER_NAME="bananapi-f3-runner"

./github-act-runner configure \
    --url "$GITHUB_REPOSITORY" \
    --token "$GITHUB_PAT" \
    --name "$RUNNER_NAME" \
    --labels "self-hosted,linux,riscv64" \
    --work "_work"
```

### 3. Test Runner

```bash
./github-act-runner run
```

Press Ctrl+C to stop. If it connects successfully, proceed to set up the systemd service.

## Set Up Systemd Service

### 1. Create Systemd Unit File

```bash
sudo tee /etc/systemd/system/github-runner.service > /dev/null <<EOF
[Unit]
Description=GitHub Actions Runner (github-act-runner)
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/github-act-runner-test
ExecStart=$HOME/github-act-runner-test/github-act-runner run
Restart=always
RestartSec=5
KillMode=process
KillSignal=SIGINT
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target
EOF
```

### 2. Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable github-runner
sudo systemctl start github-runner
```

### 3. Check Service Status

```bash
sudo systemctl status github-runner
```

### 4. View Logs

```bash
# Follow logs in real-time
sudo journalctl -u github-runner -f

# View recent logs
sudo journalctl -u github-runner -n 100

# View logs since boot
sudo journalctl -u github-runner -b
```

## Verification

### 1. Check Runner in GitHub

1. Go to your repository
2. Navigate to Settings → Actions → Runners
3. Verify your runner appears as "Online" with green dot
4. Check labels include: `self-hosted`, `linux`, `riscv64`

### 2. Test with a Simple Workflow

Create `.github/workflows/test-runner.yml`:

```yaml
name: Test RISC-V64 Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: [self-hosted, riscv64]
    steps:
      - name: Check architecture
        run: |
          uname -m
          cat /proc/cpuinfo | grep -i "model name" || echo "RISC-V CPU"

      - name: Check Docker
        run: docker --version

      - name: Check Go
        run: go version

      - name: Test Docker build
        run: |
          echo 'FROM alpine:latest' > Dockerfile
          echo 'RUN echo "Hello from RISC-V64"' >> Dockerfile
          docker build -t test .
          docker run --rm test
```

### 3. Monitor System Resources

```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
htop

# Check Docker resources
docker system df
```

## Troubleshooting

### Python pip Not Found (Debian Trixie)

On Debian 13 (Trixie), Python 3.13 is installed by default but **pip is not**. If you see:

```bash
$ pip3 --version
-bash: pip3: command not found
```

**Solution:**

```bash
sudo apt update
sudo apt install python3-pip
```

Verify installation:

```bash
pip3 --version
# Expected: pip 25.1.1 from /usr/lib/python3/dist-packages/pip (python 3.13)
```

**Alternative methods** (if `python3-pip` package is unavailable):

```bash
# Method 1: Use ensurepip
python3 -m ensurepip --default-pip --upgrade

# Method 2: Bootstrap with get-pip.py
curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
```

**Best practice**: Use virtual environments for Python packages:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install <packages>
```

### Runner Not Connecting

**Check network connectivity:**

```bash
ping github.com
curl -I https://api.github.com
```

**Check runner logs:**

```bash
sudo journalctl -u github-runner -n 100 --no-pager
```

**Verify settings:**

```bash
cat ~/github-act-runner-test/settings.json | jq .
```

### Docker Permission Errors

**Add user to docker group:**

```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Restart Docker:**

```bash
sudo systemctl restart docker
sudo systemctl restart github-runner
```

### Build Failures Due to Disk Space

**Clean Docker resources:**

```bash
docker system prune -af --volumes
```

**Check disk usage:**

```bash
ncdu /home/$USER/github-act-runner-test/_work
```

**Configure automatic cleanup:**

Add to crontab:

```bash
crontab -e

# Add this line to run cleanup daily at 2 AM
0 2 * * * docker system prune -af --volumes > /dev/null 2>&1
```

### Service Won't Start

**Check for port conflicts:**

```bash
sudo netstat -tlnp | grep github-act-runner
```

**Verify file permissions:**

```bash
ls -la ~/github-act-runner-test/github-act-runner
# Should be executable (755 or similar)
chmod +x ~/github-act-runner-test/github-act-runner
```

**Check systemd unit file:**

```bash
sudo systemctl cat github-runner
sudo systemctl daemon-reload
```

### Memory Issues During Builds

**Check available memory:**

```bash
free -h
```

**Configure swap (if needed):**

```bash
# Check current swap
swapon --show

# Add swap file (8GB)
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Runner Stuck or Unresponsive

**Restart the service:**

```bash
sudo systemctl restart github-runner
```

**Force kill if needed:**

```bash
sudo systemctl stop github-runner
pkill -9 github-act-runner
sudo systemctl start github-runner
```

**Clear workspace:**

```bash
sudo systemctl stop github-runner
rm -rf ~/github-act-runner-test/_work/*
sudo systemctl start github-runner
```

## Maintenance Tasks

### Update Runner

```bash
cd ~/github-act-runner
git pull
go build -o github-act-runner
cp github-act-runner ~/github-act-runner-test/
sudo systemctl restart github-runner
```

### Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

### Monitor Logs

```bash
# Set up log rotation if not already configured
sudo tee /etc/logrotate.d/github-runner > /dev/null <<'EOF'
/var/log/github-runner.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF
```

## Security Hardening

### 1. Configure Firewall

```bash
sudo apt install -y ufw

# Allow SSH (adjust port if needed)
sudo ufw allow 22/tcp

# Allow Docker (if needed from external)
# sudo ufw allow 2375/tcp

# Enable firewall
sudo ufw enable
```

### 2. Disable Password SSH

Edit `/etc/ssh/sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config

# Set these values:
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

### 3. Set Up Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Next Steps

- Review [SECURITY.md](docs/SECURITY.md) for security best practices
- Set up monitoring (optional)
- Configure backup strategy for runner configuration
- Document your specific workflows and build requirements

## Additional Resources

- [GitHub Act Runner Documentation](https://github.com/ChristopherHX/github-act-runner)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Armbian Documentation](https://docs.armbian.com/)

---

**Last Updated**: 2025-11-30
