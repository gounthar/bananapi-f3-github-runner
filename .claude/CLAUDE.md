# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides **complete documentation and automation** for setting up a Banana Pi F3 (RISC-V64) as a GitHub Actions self-hosted runner - from unboxing to production deployment.

The runner is used for building native RISC-V64 Docker components (Engine, CLI, Compose, Buildx, Tini, cagent) and creating Debian/RPM packages.

**Scope**: End-to-end documentation from hardware unboxing through production runner deployment
**Target hardware**: Banana Pi F3 with Armbian 25.8.2 (Debian Trixie/13), RISC-V64 architecture
**Target repository**: https://github.com/gounthar/docker-for-riscv64

## Documentation Philosophy

This project documents **every step of the journey**:
1. Unboxing the Banana Pi F3
2. Downloading and verifying Armbian images
3. Burning the image to SD card
4. Initial boot and configuration
5. Transferring Armbian from SD card to eMMC
6. Network configuration and SSH access
7. System hardening and security setup
8. Automated runner installation (via Ansible)
9. Testing and validation
10. Production deployment and monitoring

All sessions and workflows are documented using the **session-journalist agent** to produce comprehensive technical articles suitable for blog publication. This creates a complete knowledge base for replicating the setup.

## Ansible Automation

This project uses Ansible for automated deployment. The main components:

### Running the Setup

```bash
# Configure secrets first
cp .env.example .env
nano .env  # Add GITHUB_REPOSITORY, GITHUB_PAT, and other secrets

# Run the full setup playbook
ansible-playbook -i inventory.yml playbooks/setup-runner.yml
```

### Inventory Configuration

The `inventory.yml` file defines the target host and configuration variables. All sensitive data comes from environment variables (loaded from `.env` file):
- `BANANAPI_IP`: Default 192.168.1.185
- `SSH_USER`: Default poddingue
- `GITHUB_REPOSITORY`: Required (e.g., gounthar/docker-for-riscv64)
- `GITHUB_PAT`: Required GitHub Personal Access Token
- `RUNNER_NAME`: Default bananapi-f3-runner
- `GO_VERSION`: Default 1.24.4

### Role Structure

The setup is divided into Ansible roles in `roles/`:

1. **common**: System setup, user configuration, basic packages
2. **docker**: Docker Engine installation from RISC-V64 APT repo
3. **build-tools**: Go, gcc, git, Node.js, packaging tools (debhelper, rpm, etc.)
4. **github-runner**: github-act-runner installation and configuration

### Docker Installation (RISC-V64 Specific)

This project uses a **custom RISC-V64 Docker APT repository**:
- URL: https://gounthar.github.io/docker-for-riscv64
- GPG key: https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/gpg-public-key.asc
- Packages: docker.io, docker-cli, docker-compose-plugin, docker-buildx-plugin, containerd, runc, tini, cagent

The Docker role (`roles/docker/tasks/main.yml`):
1. Adds the RISC-V64 Docker APT repo
2. Installs Docker packages from that repo
3. Configures Docker daemon (BuildKit enabled, log rotation)
4. Adds the runner user to the docker group

### GitHub Runner Setup

The runner uses **ChristopherHX/github-act-runner** (not the official GitHub runner):
- Source: https://github.com/ChristopherHX/github-act-runner
- Built from source using Go 1.24.4
- Configured with labels: `self-hosted`, `linux`, `riscv64`
- Runs as a systemd service (`/etc/systemd/system/github-runner.service`)

The github-runner role (`roles/github-runner/tasks/main.yml`):
1. Creates working directory (`runner_workdir`, default `/home/poddingue/github-act-runner-test`)
2. Clones the runner repository
3. Builds the Go binary
4. Configures the runner with GitHub PAT
5. Creates systemd service from `templates/github-runner.service.j2`
6. Enables and starts the service

## Systemd Service Management

The runner runs as a systemd service:

```bash
# Check service status
sudo systemctl status github-runner

# View logs
sudo journalctl -u github-runner -f

# Restart service
sudo systemctl restart github-runner

# View recent logs (last 100 lines)
sudo journalctl -u github-runner -n 100
```

Service configuration:
- Type: simple (foreground process)
- User: poddingue (non-root)
- Auto-restart: yes (5s delay)
- Graceful shutdown: SIGINT, 5min timeout
- Dependencies: network.target, docker.service
- Environment: Explicit PATH set to ensure Node.js and other build tools are available

## Updating the Runner

### Automatic Updates (Recommended)

The runner is configured with automatic weekly updates by default. A cron job runs every Sunday at 3 AM to:
1. Validate the `runner_version` format for security
2. Check for new commits in the github-act-runner repository
3. Pull and rebuild if updates are available (with configurable build flags)
4. Backup the old binary before updating
5. Restart the service with the new binary
6. Roll back to backup if the new binary fails to start
7. Send webhook notifications on success, warning, or error (if configured)

View update logs:
```bash
cat /var/log/github-runner-update.log
```

#### Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `RUNNER_AUTO_UPDATE` | Enable/disable auto-updates | `true` |
| `RUNNER_BUILD_FLAGS` | Custom `go build` flags (e.g., `-ldflags="-s -w"`) | (empty) |
| `RUNNER_UPDATE_WEBHOOK` | Webhook URL for notifications | (empty) |

Example `.env` configuration:
```bash
RUNNER_AUTO_UPDATE=true
RUNNER_BUILD_FLAGS=-ldflags="-s -w"
RUNNER_UPDATE_WEBHOOK=https://hooks.slack.com/services/...
```

#### Webhook Notification Format

When `RUNNER_UPDATE_WEBHOOK` is set, the update script sends JSON POST requests:
```json
{
    "status": "success|warning|error",
    "runner": "bananapi-f3-runner",
    "host": "bananapi-f3",
    "message": "Updated from abc123 to def456",
    "timestamp": "2025-12-02T09:00:00+00:00"
}
```

To disable automatic updates, set in `.env`:
```bash
RUNNER_AUTO_UPDATE=false
```

Then re-run the playbook to remove the cron job:
```bash
ansible-playbook -i inventory.yml playbooks/setup-runner.yml
```

### Manual Updates

To manually update the github-act-runner binary:

```bash
# Replace <RUNNER_WORKDIR> with your configured path (default: /home/poddingue/github-act-runner-test)
cd <RUNNER_WORKDIR>/src
git pull
go build -o github-act-runner
cp github-act-runner ../
sudo systemctl restart github-runner
```

Or run the update script directly (path depends on `runner_workdir` variable in Ansible):
```bash
# Default path:
/home/poddingue/github-act-runner-test/update-runner.sh

# Or with custom runner_workdir:
<RUNNER_WORKDIR>/update-runner.sh
```

Or re-run the Ansible playbook (will rebuild if binary doesn't exist).

## Template Files

Jinja2 templates in `templates/` and `roles/*/templates/`:
- `github-runner.service.j2`: Systemd service unit file
- `update-runner.sh.j2`: Weekly auto-update script for github-act-runner
- `daemon.json.j2`: Docker daemon configuration
- `settings.json.j2`: Runner settings (if used)

Variables are defined in `inventory.yml` and loaded from `.env` environment file.

## Manual Setup Alternative

If Ansible isn't available, follow the step-by-step guide in `MANUAL_SETUP.md`. This covers:
1. System update and package installation
2. Go installation (1.24.4)
3. Docker installation from RISC-V64 repo
4. Building github-act-runner from source
5. Runner configuration
6. Systemd service setup

## Security Notes

- **Never commit `.env`**: Contains GitHub PAT and sensitive tokens
- **Runner user**: Runs as non-root (`poddingue`) but has docker group access (security trade-off)
- **Docker socket**: Access to docker.sock is equivalent to root (required for builds)
- **Secrets in Ansible**: Use `no_log: true` for sensitive tasks
- **Firewall**: Configure UFW to restrict access (SSH only recommended)

## Disk Space Management

Builds can consume significant disk space (10-20GB temporarily). Monitor and clean:

```bash
# Check disk usage
df -h

# Clean Docker resources
docker system prune -af --volumes

# Clean runner workspace
cd /home/poddingue/github-act-runner-test/_work
rm -rf *
```

Current hardware: 128GB eMMC, ~113GB usable, keeping ~20GB free recommended.

## Performance Characteristics

Build times on Banana Pi F3 (16GB RAM, 8-core RISC-V64):
- Docker Engine: 35-40 minutes
- Docker CLI: 15-20 minutes
- Docker Compose: 10-15 minutes
- Debian/RPM packages: 2-3 minutes

Resource usage:
- Idle: ~600MB RAM, ~1% CPU
- During build: ~11GB RAM peak, 100% CPU
- Disk: 10-20GB temporary space per build

## Architecture Documentation

See `docs/ARCHITECTURE.md` for detailed information on:
- Software stack layers
- Workflow execution flow
- Docker build flow
- Directory structure
- Network architecture
- Security boundaries
- Resource management

## Repository Structure

```
.
├── playbooks/          # Ansible playbooks
│   └── setup-runner.yml
├── roles/              # Ansible roles
│   ├── common/
│   ├── docker/
│   ├── build-tools/
│   └── github-runner/
├── templates/          # Jinja2 templates (if any at root)
├── docs/               # Documentation
│   ├── hardware/       # Hardware setup guides
│   │   ├── 01-unboxing.md
│   │   ├── 02-armbian-download.md
│   │   ├── 03-sd-card-setup.md
│   │   ├── 04-first-boot.md
│   │   └── 05-emmc-transfer.md
│   ├── ARCHITECTURE.md
│   ├── SECURITY.md
│   └── TROUBLESHOOTING.md
├── journal/            # Session documentation (created by session-journalist)
│   └── session_*.adoc  # Technical articles from each work session
├── .env.example        # Environment variable template
├── .env                # Actual secrets (NEVER commit)
├── inventory.yml       # Ansible inventory
├── MANUAL_SETUP.md     # Manual setup guide
└── README.md           # Project overview
```

## Documentation Workflow

### Creating Documentation

When documenting new procedures or workflows:

1. **Work through the actual process** on real hardware (Banana Pi F3)
2. **Document as you go** - capture commands, outputs, issues, solutions
3. **Use CONTEXT.md** to track progress and important findings
4. **Take screenshots** where helpful (store in `docs/images/`)
5. **At session end**, the session-journalist agent automatically creates a technical article in `journal/`

### Documentation Structure

- **docs/hardware/**: Step-by-step hardware setup guides (numbered for sequence)
- **docs/**: High-level architecture, security, troubleshooting
- **journal/**: Session-based technical articles (AsciiDoc format)
- **MANUAL_SETUP.md**: Consolidated manual setup guide
- **README.md**: Project overview and quick start

### Session Journalist Integration

At the end of each work session, the session-journalist agent:
- Reads the conversation history and CONTEXT.md
- Extracts technical procedures, commands, and solutions
- Generates a detailed technical article (1500-3000 words)
- Saves to `journal/session_YYYY-MM-DD_HHMM.adoc`
- Writes in authentic technical voice (using style-replicator agent)
- Suitable for direct blog publication

### Documentation Best Practices

- **Be specific**: Include exact commands, file paths, versions
- **Explain why**: Not just what to do, but why it's done this way
- **Document failures**: Failed attempts and solutions are valuable
- **Include outputs**: Show expected command outputs
- **Cross-reference**: Link between related documentation files
- **Keep CONTEXT.md clean**: Remove secrets before committing (claude-config-sync handles this)

## Hardware Setup Commands

Common commands for initial hardware setup (documented in `docs/hardware/`):

### Downloading Armbian Images

```bash
# Download from Armbian website
wget https://www.armbian.com/banana-pi-f3/

# Verify checksum
sha256sum Armbian_*.img.xz
```

### Burning Image to SD Card

```bash
# Find SD card device (be careful!)
lsblk

# Burn image (replace /dev/sdX with actual device)
xzcat Armbian_*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
sync
```

### First Boot and SSH Access

```bash
# Default credentials (change immediately):
# User: root
# Password: 1234

# SSH to device
ssh root@<ip-address>

# Follow prompts to create new user and set passwords
```

### Transferring to eMMC

```bash
# On the Banana Pi F3, run:
sudo nand-sata-install

# Select option to install to eMMC
# Follow prompts to transfer system
# Power off, remove SD card, power on
```

### System Information Commands

```bash
# Check architecture
uname -m  # Should show: riscv64

# Check OS version
cat /etc/os-release

# Check kernel version
uname -r

# Check CPU info
cat /proc/cpuinfo

# Check memory
free -h

# Check disk space
df -h

# Check eMMC/SD status
lsblk
```

## Common Workflows

### Documenting Hardware Setup Steps

When creating new hardware documentation:

1. Create file in `docs/hardware/` with numbered prefix (e.g., `06-new-step.md`)
2. Include command examples with actual outputs
3. Document any issues encountered and solutions
4. Add screenshots to `docs/images/` if helpful
5. Update README.md to reference the new guide

### Adding a New Package

If adding packages to install:
1. Add to appropriate role's task file (`roles/*/tasks/main.yml`)
2. For Debian packages: add to apt task list
3. Test by running the specific role or full playbook

### Modifying Docker Configuration

1. Edit `roles/docker/templates/daemon.json.j2`
2. Re-run playbook or manually update `/etc/docker/daemon.json`
3. Restart Docker: `sudo systemctl restart docker`
4. Restart runner: `sudo systemctl restart github-runner`

### Changing Runner Configuration

1. Update variables in `inventory.yml` or `.env`
2. Re-run playbook, or manually:
   - Edit `/etc/systemd/system/github-runner.service`
   - `sudo systemctl daemon-reload`
   - `sudo systemctl restart github-runner`

## Testing

After deployment or changes:

1. Check service status: `sudo systemctl status github-runner`
2. Verify runner appears in GitHub: Settings → Actions → Runners
3. Run test workflow (see README.md for example)
4. Monitor first build: `sudo journalctl -u github-runner -f`

## Related Projects

- **github-act-runner**: https://github.com/ChristopherHX/github-act-runner
- **RISC-V64 Docker packages**: https://github.com/gounthar/docker-for-riscv64
- **Armbian for Banana Pi F3**: https://www.armbian.com/

## Key Takeaways for Development

- This is infrastructure-as-code using Ansible, not application code
- All secrets MUST be in `.env` (gitignored), never hardcoded
- The runner is a Go binary built from source, not a standard GitHub runner
- Docker packages come from a custom RISC-V64 repository, not standard Debian repos
- The systemd service runs continuously in the background, polling for jobs
- Most operations require sudo/root on the target device
- Always test changes on the actual Banana Pi F3 hardware (RISC-V64 architecture)
