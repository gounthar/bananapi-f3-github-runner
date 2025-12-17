# Runner Reliability Fixes

## Background

Investigation on 2025-12-17 revealed that GitHub Actions workflows were hanging on one of the two RISC-V runners (bananapif3-2). The root cause was identified as:

1. **Runner service not auto-starting after reboot** - After a machine hang/reboot, the `github-runner` service did not start automatically
2. **Potential sudo password prompts** - Although NOPASSWD was configured, ensuring consistent passwordless sudo is critical for CI/CD reliability

## Required Ansible Tasks

### 1. Configure Passwordless Sudo for Runner User

The runner user needs passwordless sudo for specific commands to execute CI/CD operations without hanging on password prompts.

```yaml
- name: Configure passwordless sudo for runner user
  copy:
    content: |
      # Allow {{ runner_user }} passwordless sudo for CI/CD operations
      # Scoped to specific commands for security (not ALL)
      # See docs/RUNNER-RELIABILITY-FIXES.md for security considerations
      {{ runner_user }} ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/bin/dpkg, /usr/bin/systemctl, /usr/bin/docker, /usr/bin/tee, /usr/bin/mkdir, /usr/bin/chmod, /usr/bin/chown
    dest: /etc/sudoers.d/{{ runner_user }}-nopasswd
    mode: '0440'
    validate: 'visudo -cf %s'
```

**Important:** Using a drop-in file in `/etc/sudoers.d/` is preferred over editing `/etc/sudoers` directly.

**Security Note:** Sudo permissions are scoped to specific commands rather than `ALL` to minimize attack surface. See [Security Considerations](#security-considerations) below.

### 2. Enable and Start GitHub Runner Service

Ensure the service starts automatically on boot and is currently running.

```yaml
- name: Enable GitHub runner service
  systemd:
    name: github-runner
    enabled: yes
    state: started
    daemon_reload: yes
  become: true
```

### 3. Verify Service Configuration

Add verification tasks using the systemd module with retry logic to handle transient states:

```yaml
- name: Verify runner service is enabled for auto-start
  systemd:
    name: github-runner
  register: runner_service_status
  failed_when: runner_service_status.status.UnitFileState != 'enabled'

- name: Verify runner service is currently active
  systemd:
    name: github-runner
  register: runner_service_active
  until: runner_service_active.status.ActiveState == 'active'
  retries: 3
  delay: 5
  failed_when: runner_service_active.status.ActiveState != 'active'
```

**Note:** The retry logic (3 attempts, 5 second delay) handles transient states during service startup.

## Verification Commands

After applying the playbook, verify on each runner:

```bash
# Check passwordless sudo works (doesn't modify system state)
sudo -n true

# Check service status
systemctl status github-runner
systemctl is-enabled github-runner

# Check sudo configuration
sudo -l | grep NOPASSWD
```

## Current Runner Configuration

Both runners should have identical configuration:

| Setting | Expected Value |
|---------|----------------|
| Hostname | bananapif3-1, bananapif3-2 |
| Runner User | poddingue |
| Service Name | github-runner |
| Service Enabled | yes |
| Sudo NOPASSWD | Scoped (apt-get, apt, dpkg, systemctl, docker, tee, mkdir, chmod, chown) |

## Diagnostic Workflow

A diagnostic workflow exists at `.github/workflows/runner-diagnostics.yml` in the docker-for-riscv64 repository. Run it to compare runner configurations:

```bash
gh workflow run runner-diagnostics.yml
```

This runs on both runners simultaneously and collects:
- OS information
- Disk space and memory
- APT lock status
- Installed packages
- Sudo configuration
- Network connectivity

## Security Considerations

### Why Scoped Sudo Instead of NOPASSWD: ALL

Granting `NOPASSWD: ALL` to the runner user would create a significant security risk:

1. **Compromised workflows**: If a malicious workflow runs on the runner, it could gain full root access
2. **Supply chain attacks**: Dependencies pulled during CI/CD could execute arbitrary commands as root
3. **Lateral movement**: An attacker gaining access to the runner user could escalate to full system control

### Current Scoped Permissions

The following commands are allowed without password:

| Command | Purpose |
|---------|---------|
| `/usr/bin/apt-get` | Install build dependencies |
| `/usr/bin/apt` | Package management |
| `/usr/bin/dpkg` | Debian package operations |
| `/usr/bin/systemctl` | Service management (restart runner) |
| `/usr/bin/docker` | Container operations (backup for non-group access) |
| `/usr/bin/tee` | Write to protected files |
| `/usr/bin/mkdir` | Create directories |
| `/usr/bin/chmod` | Change file permissions |
| `/usr/bin/chown` | Change file ownership |

### If Workflows Require Additional Commands

If a workflow needs a command not in this list, you have two options:

1. **Add the specific command** to the sudoers file (preferred)
2. **Use NOPASSWD: ALL** only if you understand and accept the risks

To add a command, edit `roles/github-runner/tasks/main.yml` and add it to the comma-separated list.

### Additional Mitigations

Even with scoped sudo, consider these additional security measures:

- **Network segmentation**: Isolate runners from production systems
- **Repository restrictions**: Limit which repositories can use the runner
- **Workflow approval**: Require approval for workflows from external contributors
- **Regular updates**: Keep the runner and system packages up to date
