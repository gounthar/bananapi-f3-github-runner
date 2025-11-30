# System Architecture

## Overview

This document describes the technical architecture of the Banana Pi F3 GitHub Actions runner setup.

## Hardware Architecture

```
┌─────────────────────────────────────────────┐
│         Banana Pi F3 (RISC-V64)            │
├─────────────────────────────────────────────┤
│  CPU: SpacemiT K1 (8 cores)                │
│  Arch: RV64GC                               │
│  RAM: 16GB                                  │
│  Storage: 128GB eMMC                        │
│  Network: Gigabit Ethernet                  │
└─────────────────────────────────────────────┘
```

## Software Stack

```
┌──────────────────────────────────────────────────┐
│         GitHub Actions Workflows                 │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│      GitHub Act Runner (Go binary)               │
│  - ChristopherHX/github-act-runner              │
│  - Version: 0.8.x-dev                           │
│  - Protocol: GitHub Actions v2                  │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│         Systemd Service Layer                    │
│  - Auto-restart on failure                      │
│  - Graceful shutdown handling                   │
│  - Log management via journald                  │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│            Docker Engine                         │
│  - Version: 29.1.1                              │
│  - Buildx plugin                                │
│  - Compose plugin                               │
│  - BuildKit enabled                             │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│         Armbian Linux (Debian Trixie)           │
│  - Kernel: 6.6.99-current-spacemit              │
│  - Architecture: riscv64                        │
└──────────────────────────────────────────────────┘
```

## Component Interaction

### Workflow Execution Flow

```
1. GitHub API → 2. Runner Poll → 3. Job Received
                      │
                      ▼
4. Prepare Workspace → 5. Execute Steps → 6. Cleanup
                      │
                      ▼
              7. Report Results
```

### Docker Build Flow

```
Workflow Step
     │
     ▼
Docker Build Command
     │
     ▼
BuildKit (buildx)
     │
     ├── Pull Base Image
     ├── Execute RUN commands
     ├── Apply filesystem layers
     └── Tag and export
```

## Directory Structure

```
/home/poddingue/github-act-runner-test/
├── github-act-runner              # Main binary
├── settings.json                  # Runner configuration
├── sessions.json                  # Active sessions
├── _work/                         # Workspace for jobs
│   ├── _actions/                  # Cached actions
│   ├── _temp/                     # Temporary files
│   └── <repo-name>/               # Cloned repositories
└── src/                           # Source code (if built locally)
```

## Network Architecture

```
┌─────────────────────────────────────────┐
│         Internet                        │
└──────────┬──────────────────────────────┘
           │
           │ HTTPS (443)
           │
┌──────────▼──────────────────────────────┐
│   GitHub API Endpoints                  │
│  - api.github.com                       │
│  - pipelinesghubeus9.actions.           │
│    githubusercontent.com                 │
│  - broker.actions.githubusercontent.com │
└──────────┬──────────────────────────────┘
           │
           │
┌──────────▼──────────────────────────────┐
│    Local Network (192.168.1.0/24)      │
│                                         │
│  ┌────────────────────────────────┐    │
│  │  Banana Pi F3                  │    │
│  │  IP: 192.168.1.185            │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  GitHub Runner       │     │    │
│  │  │  Port: Dynamic       │     │    │
│  │  └──────────────────────┘     │    │
│  │                                │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  Docker Engine       │     │    │
│  │  │  Socket: /var/run/   │     │    │
│  │  │         docker.sock  │     │    │
│  │  └──────────────────────┘     │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Process Management

### Systemd Unit

```ini
[Service]
Type=simple                    # Foreground process
User=poddingue                 # Non-root user
Restart=always                 # Auto-restart
RestartSec=5                   # Wait 5s before restart
KillMode=process               # Kill main process only
KillSignal=SIGINT              # Graceful shutdown
TimeoutStopSec=5min            # Allow cleanup time
```

### Runner Lifecycle

1. **Start**: systemd starts the binary
2. **Initialize**: Connect to GitHub API
3. **Poll**: Listen for job requests
4. **Execute**: Run workflow steps
5. **Report**: Send results to GitHub
6. **Cleanup**: Remove workspace artifacts
7. **Repeat**: Return to polling

## Build Environment

### Package Sources

1. **Debian Trixie**: Base OS packages
2. **RISC-V64 Docker APT Repo**: https://gounthar.github.io/docker-for-riscv64
   - docker.io
   - docker-cli
   - docker-compose-plugin
   - docker-buildx-plugin
   - containerd
   - runc
   - tini
   - cagent

### Compiler Toolchain

- **Go**: 1.24.4 (for building Go projects)
- **GCC**: 13.x (for C/C++ compilation)
- **Make**: 4.3 (build automation)

### Packaging Tools

- **dpkg-buildpackage**: Debian package creation
- **rpmbuild**: RPM package creation
- **reprepro**: APT repository management
- **createrepo_c**: RPM repository management

## Resource Management

### Memory Allocation

- **System Reserved**: ~2GB
- **Docker Cache**: ~8GB (dynamic)
- **Build Workspace**: ~4GB per job
- **Available for Jobs**: ~10-12GB

### Disk Space

- **OS and Tools**: ~15GB
- **Docker Images**: ~20GB
- **Build Cache**: ~10GB
- **Workspace**: ~10GB per job
- **Reserved Free**: 20GB minimum

### CPU Usage

- **Idle**: ~1-2% per core
- **During Builds**: 100% all cores
- **Go Compilation**: High single-thread
- **Docker Builds**: Parallel layer builds

## Security Boundaries

```
┌─────────────────────────────────────────┐
│  Workflow Code (UNTRUSTED)             │
└──────────┬──────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  Docker Container (ISOLATION LAYER)     │
│  - cgroups limits                       │
│  - Namespace isolation                  │
│  - Seccomp filtering                    │
└──────────┬──────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  Runner Process (poddingue user)        │
│  - Limited file access                  │
│  - Docker socket access (⚠️ root-equiv) │
└──────────┬──────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  Operating System (Armbian/Debian)      │
│  - Kernel security features             │
│  - Firewall (UFW)                       │
│  - AppArmor/SELinux (optional)          │
└──────────────────────────────────────────┘
```

## Monitoring Points

1. **Service Status**: `systemctl status github-runner`
2. **Logs**: `journalctl -u github-runner`
3. **Resource Usage**: `htop`, `docker stats`
4. **Disk Space**: `df -h`
5. **Network**: GitHub UI → Settings → Actions → Runners

## Scaling Considerations

### Single Runner Limitations

- One job at a time (MaxParallelism=1)
- No horizontal scaling
- Hardware-limited resources

### Multi-Runner Option

To run multiple runners on the same device:

```bash
# Create separate working directories
/home/poddingue/runner-1
/home/poddingue/runner-2

# Separate systemd services
/etc/systemd/system/github-runner-1.service
/etc/systemd/system/github-runner-2.service
```

**Note**: Not recommended due to resource constraints.

## Backup Strategy

### Critical Data

1. **settings.json**: Runner configuration
2. **GitHub PAT**: In `.env` file (backup securely)
3. **SSH Keys**: For access recovery
4. **Build Artifacts**: If caching is used

### Backup Commands

```bash
# Backup runner configuration
tar czf runner-backup.tar.gz \
  /home/poddingue/github-act-runner-test/settings.json \
  /etc/systemd/system/github-runner.service

# Exclude from backup
_work/  # Temporary workspace
src/    # Can be re-cloned
```

## Disaster Recovery

### Full System Recovery

1. Flash new Armbian image
2. Run Ansible playbook from this repository
3. Restore `.env` file with secrets
4. Runner auto-registers and starts

**Recovery Time Objective (RTO)**: ~30-60 minutes

## Performance Metrics

### Typical Build Times

| Component | Build Time |
|-----------|------------|
| Docker Engine | 35-40 min |
| Docker CLI | 15-20 min |
| Docker Compose | 10-15 min |
| Debian Package | 2-3 min |
| RPM Package | 2-3 min |

### Bottlenecks

1. **CPU**: Go compilation (single-threaded)
2. **Memory**: Large Docker builds
3. **Disk I/O**: Image layers, caching
4. **Network**: Pulling base images

---

**Last Updated**: 2025-11-30
