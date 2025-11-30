# Banana Pi F3 GitHub Actions Runner Setup

**Complete documentation and automation** for setting up a Banana Pi F3 as a self-hosted GitHub Actions runner for RISC-V64 builds - **from unboxing to production deployment**.

## Overview

This repository provides **end-to-end documentation** of the complete journey from unboxing a Banana Pi F3 to running a production GitHub Actions runner, including:

- 📦 **Hardware setup guides** - Step-by-step from unboxing to ready system
- 🤖 **Ansible playbooks** - Fully automated installation
- ⚙️ **Systemd service configuration** - Production-grade runner management
- 📋 **Complete package lists** - All tools for Debian/RPM development
- 📖 **Comprehensive documentation** - Manual setup guide as fallback
- 🔒 **Security best practices** - Hardened runner deployment
- 📝 **Session journals** - Detailed technical articles from each work session

### Documentation Structure

1. **[docs/hardware/](docs/hardware/)** - Hardware setup guides (unboxing → ready for automation)
2. **[playbooks/](playbooks/)** - Ansible automation
3. **[journal/](journal/)** - Session-based technical articles
4. **[docs/](docs/)** - Architecture, security, troubleshooting

## Hardware Specifications

- **Device**: Banana Pi F3
- **Architecture**: RISC-V64 (riscv64)
- **OS**: Armbian 25.8.2 (Debian Trixie/13)
- **Kernel**: 6.6.99-current-spacemit
- **RAM**: 16 GB
- **Storage**: 128 GB eMMC (113GB usable)
- **Current Usage**: ~51GB used, 57GB available

## What This Runner Does

This runner is used for:
- Building native RISC-V64 Docker Engine binaries
- Building native RISC-V64 Docker CLI binaries
- Building native RISC-V64 Docker Compose binaries
- Building native RISC-V64 Tini binaries
- Building native RISC-V64 Docker Buildx plugin
- Building native RISC-V64 cagent (multi-agent AI runtime)
- Creating Debian (.deb) packages for RISC-V64
- Creating RPM packages for RISC-V64
- Running on repository: https://github.com/gounthar/docker-for-riscv64

## Getting Started

### Two Paths Available

**Path 1: Complete Journey (Hardware → Production)**
- Start from scratch with a new Banana Pi F3
- Follow the [Hardware Setup Guides](docs/hardware/)
- Great for first-time setup or documentation

**Path 2: Automated Setup (Already Have Armbian)**
- Skip to Ansible automation if Armbian is already installed
- See [Automated Setup](#automated-setup-recommended) below

### Prerequisites

**For Hardware Setup (Path 1):**
- Banana Pi F3 board (new or reset)
- Power supply (USB-C, 5V/3A minimum)
- microSD card (16GB+, Class 10 or better)
- Ethernet cable
- Computer with SD card reader

**For Automated Setup (Path 2):**
- Banana Pi F3 with Armbian installed
- SSH access to the device
- Ansible installed on your control machine
- GitHub personal access token (for runner registration)

### Hardware Setup (Path 1)

If starting from scratch, follow these guides in order:

1. [01-unboxing.md](docs/hardware/01-unboxing.md) - Unboxing and hardware overview
2. [02-armbian-download.md](docs/hardware/02-armbian-download.md) - Download and verify Armbian
3. [03-sd-card-setup.md](docs/hardware/03-sd-card-setup.md) - Prepare SD card
4. [04-first-boot.md](docs/hardware/04-first-boot.md) - Initial boot and configuration
5. [05-emmc-transfer.md](docs/hardware/05-emmc-transfer.md) - Transfer to eMMC
6. [06-ssh-hardening.md](docs/hardware/06-ssh-hardening.md) - Secure SSH access
7. [07-system-preparation.md](docs/hardware/07-system-preparation.md) - Prepare for automation

After completing hardware setup, proceed to Automated Setup below.

### Automated Setup (Recommended)

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/bananapi-f3-github-runner.git
cd bananapi-f3-github-runner

# Copy and configure your secrets
cp .env.example .env
nano .env  # Add your GitHub token and other secrets

# Run the Ansible playbook
ansible-playbook -i inventory.yml playbooks/setup-runner.yml

# The runner will be installed and configured automatically
```

### Manual Setup

See [MANUAL_SETUP.md](MANUAL_SETUP.md) for step-by-step manual installation instructions.

## Repository Structure

```
.
├── README.md                       # This file - project overview
├── MANUAL_SETUP.md                 # Step-by-step manual setup guide
├── LICENSE                         # MIT License
├── .env.example                    # Environment variable template
├── .env                            # Actual secrets (NEVER commit)
├── .gitignore                      # Git ignore patterns
├── inventory.yml                   # Ansible inventory
├── packages.list                   # Required Debian packages
│
├── docs/                           # Documentation
│   ├── hardware/                   # Hardware setup guides (Path 1)
│   │   ├── README.md               # Hardware setup overview
│   │   ├── 01-unboxing.md          # Unboxing and hardware overview
│   │   ├── 02-armbian-download.md  # Downloading Armbian
│   │   ├── 03-sd-card-setup.md     # SD card preparation
│   │   ├── 04-first-boot.md        # Initial boot and config
│   │   ├── 05-emmc-transfer.md     # Transfer to eMMC
│   │   ├── 06-ssh-hardening.md     # SSH security
│   │   └── 07-system-preparation.md # Final prep for automation
│   ├── images/                     # Screenshots and diagrams
│   ├── ARCHITECTURE.md             # System architecture details
│   ├── SECURITY.md                 # Security considerations
│   └── TROUBLESHOOTING.md          # Common issues and solutions
│
├── journal/                        # Session documentation
│   ├── README.md                   # About session journals
│   └── session_*.adoc              # Technical articles (auto-generated)
│
├── playbooks/                      # Ansible automation
│   └── setup-runner.yml            # Main playbook for runner setup
│
├── roles/                          # Ansible roles
│   ├── common/                     # Common system configuration
│   │   └── tasks/main.yml
│   ├── docker/                     # Docker installation and config
│   │   ├── tasks/main.yml
│   │   ├── templates/daemon.json.j2
│   │   └── handlers/main.yml
│   ├── build-tools/                # Build tools installation
│   │   └── tasks/main.yml
│   └── github-runner/              # GitHub runner installation
│       ├── tasks/main.yml
│       ├── templates/github-runner.service.j2
│       └── handlers/main.yml
│
└── .claude/                        # Claude Code configuration
    ├── CLAUDE.md                   # Project guidance for Claude
    └── CONTEXT.md                  # Current progress tracking
```

## Software Installed

### Core Components

- **GitHub Act Runner**: v0.8.x-dev (ChristopherHX/github-act-runner)
  - Source: https://github.com/ChristopherHX/github-act-runner
  - Built from source with Go 1.24.4
  - Configured as systemd service

- **Docker Engine**: v29.1.1
- **Docker CLI**: v29.1.1
- **Docker Compose**: v2.x (plugin)
- **Docker Buildx**: Latest (plugin)

### Build Tools

- **Go**: 1.24.4 (golang-1.24 package)
- **Build Essential**: gcc, g++, make, etc.
- **Git**: 2.47.3
- **GitHub CLI (gh)**: 2.46.0

### Debian Packaging

- debhelper
- dh-make
- dpkg-dev
- lintian
- devscripts
- reprepro

### RPM Packaging

- rpm
- rpmbuild
- rpmlint
- createrepo_c

### Utilities

- jq
- curl
- wget
- htop
- tmux

## Configuration Files

### Systemd Service

Location: `/etc/systemd/system/github-runner.service`

```ini
[Unit]
Description=GitHub Actions Runner (github-act-runner)
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=poddingue
WorkingDirectory=/home/poddingue/github-act-runner-test
ExecStart=/home/poddingue/github-act-runner-test/github-act-runner run
Restart=always
RestartSec=5
KillMode=process
KillSignal=SIGINT
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target
```

### Runner Configuration

The runner is configured with:
- **Name**: bananapi-f3-runner
- **Labels**: self-hosted, linux, riscv64
- **Max Parallelism**: 1 (single job at a time)
- **Repository**: https://github.com/gounthar/docker-for-riscv64

## Environment Variables

Required secrets (stored in `.env` - **NEVER commit this file**):

```bash
# GitHub Configuration
GITHUB_REPOSITORY=gounthar/docker-for-riscv64
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Runner Configuration
RUNNER_NAME=bananapi-f3-runner
RUNNER_WORKDIR=/home/poddingue/github-act-runner-test
RUNNER_USER=poddingue

# Optional: Docker Hub (for private images)
DOCKERHUB_USERNAME=your_username
DOCKERHUB_TOKEN=dckr_pat_xxxxxxxxxxxxxxxxxxxxx
```

## Security Considerations

1. **SSH Access**: Use SSH keys, disable password authentication
2. **Firewall**: Configure UFW to allow only necessary ports
3. **User Permissions**: Runner runs as non-root user `poddingue`
4. **Docker Security**: User added to `docker` group (security trade-off)
5. **Secrets Management**: All tokens stored in `.env` (gitignored)
6. **Network Isolation**: Runner should be on trusted network
7. **Regular Updates**: Keep system and packages updated

See [docs/SECURITY.md](docs/SECURITY.md) for detailed security guidelines.

## Maintenance

### Updating the Runner

```bash
cd /home/poddingue/github-act-runner-test
git pull
go build -o github-act-runner
sudo systemctl restart github-runner
```

### Checking Status

```bash
# Check service status
sudo systemctl status github-runner

# View logs
sudo journalctl -u github-runner -f

# Check runner version
/home/poddingue/github-act-runner-test/github-act-runner --version
```

### Disk Space Management

The runner workspace can grow over time. Clean up periodically:

```bash
# Clean Docker resources
docker system prune -af --volumes

# Clean runner workspace
cd /home/poddingue/github-act-runner-test/_work
rm -rf *
```

## Troubleshooting

### Runner Not Starting

```bash
# Check service status
sudo systemctl status github-runner

# Check for port conflicts
sudo netstat -tlnp | grep github-act-runner

# Verify Docker is running
sudo systemctl status docker
```

### Build Failures

```bash
# Check available disk space
df -h

# Check available memory
free -h

# Review recent build logs
sudo journalctl -u github-runner -n 100
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more common issues.

## Performance Notes

### Build Times (approximate)

- Docker Engine: ~35-40 minutes
- Docker CLI: ~15-20 minutes
- Docker Compose: ~10-15 minutes
- Debian Package Build: ~2-3 minutes
- RPM Package Build: ~2-3 minutes

### Resource Usage

- **Idle**: ~600MB RAM, ~1% CPU
- **During Build**: ~11GB RAM peak, 100% CPU
- **Disk Space**: Builds can use 10-20GB temporarily

## Contributing

Contributions are welcome! Please:

1. Fork this repository
2. Create a feature branch
3. Test your changes on a Banana Pi F3
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file

## References

- [GitHub Act Runner](https://github.com/ChristopherHX/github-act-runner)
- [Armbian for Banana Pi F3](https://www.armbian.com/)
- [Docker for RISC-V64](https://github.com/gounthar/docker-for-riscv64)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)

## Support

For issues specific to:
- **This setup**: Open an issue in this repository
- **GitHub Act Runner**: https://github.com/ChristopherHX/github-act-runner/issues
- **Armbian**: https://forum.armbian.com/
- **RISC-V Docker builds**: https://github.com/gounthar/docker-for-riscv64/issues

---

**Last Updated**: 2025-11-30
**Tested On**: Banana Pi F3, Armbian 25.8.2 (Debian Trixie)
