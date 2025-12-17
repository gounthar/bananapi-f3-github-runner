# Runner Reliability Fixes

## Background

Investigation on 2025-12-17 revealed that GitHub Actions workflows were hanging on one of the two RISC-V runners (bananapif3-2). The root cause was identified as:

1. **Runner service not auto-starting after reboot** - After a machine hang/reboot, the `github-runner` service did not start automatically
2. **Potential sudo password prompts** - Although NOPASSWD was configured, ensuring consistent passwordless sudo is critical for CI/CD reliability

## Required Ansible Tasks

### 1. Configure Passwordless Sudo for Runner User

The runner user needs `NOPASSWD: ALL` to execute CI/CD commands without hanging on password prompts.

```yaml
- name: Configure passwordless sudo for runner user
  copy:
    content: |
      # Allow {{ runner_user }} passwordless sudo for CI/CD operations
      # Required for: apt-get installs, docker commands, service management
      # See docs/RUNNER-RELIABILITY-FIXES.md for rationale
      {{ runner_user }} ALL=(ALL) NOPASSWD: ALL
    dest: /etc/sudoers.d/{{ runner_user }}-nopasswd
    mode: '0440'
    validate: 'visudo -cf %s'
```

**Important:** Using a drop-in file in `/etc/sudoers.d/` is preferred over editing `/etc/sudoers` directly.

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

Add a verification task to confirm the service is properly configured:

```yaml
- name: Verify runner service is enabled
  command: systemctl is-enabled github-runner
  register: runner_enabled
  changed_when: false
  failed_when: runner_enabled.stdout != 'enabled'

- name: Verify runner service is active
  command: systemctl is-active github-runner
  register: runner_active
  changed_when: false
  failed_when: runner_active.stdout != 'active'
```

## Verification Commands

After applying the playbook, verify on each runner:

```bash
# Check passwordless sudo works
sudo -n apt-get update

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
| Sudo NOPASSWD | ALL |

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
