# Security Best Practices for Banana Pi F3 GitHub Runner

This document outlines security considerations and best practices for deploying and maintaining a self-hosted GitHub Actions runner on Banana Pi F3.

## Table of Contents

1. [Threat Model](#threat-model)
2. [Network Security](#network-security)
3. [Access Control](#access-control)
4. [Runner Security](#runner-security)
5. [Secrets Management](#secrets-management)
6. [Docker Security](#docker-security)
7. [System Hardening](#system-hardening)
8. [Monitoring and Auditing](#monitoring-and-auditing)
9. [Incident Response](#incident-response)
10. [Security Checklist](#security-checklist)

## Threat Model

### Potential Threats

1. **Malicious Workflow Execution**: Untrusted code running on the runner
2. **Privilege Escalation**: Breaking out of Docker containers
3. **Data Exfiltration**: Stealing secrets or source code
4. **Resource Abuse**: Using runner for cryptocurrency mining
5. **Network Attacks**: Compromising other devices on the network
6. **Supply Chain Attacks**: Compromised dependencies in workflows

### Security Boundaries

- The runner is **NOT** sandboxed like GitHub-hosted runners
- Docker provides limited isolation
- Runner has access to local network
- User running the service has Docker privileges (equivalent to root)

## Network Security

### Firewall Configuration

**Required Open Ports:**
- SSH (22): For administration
- Outbound HTTPS (443): For GitHub API communication

**Configure UFW:**

```bash
# Install UFW
sudo apt install -y ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (adjust port if needed)
sudo ufw allow 22/tcp comment 'SSH'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

### Network Isolation

**Recommendations:**

1. **VLAN Isolation**: Place runner on dedicated VLAN
2. **No Public Internet**: If possible, use proxy for GitHub access
3. **Internal Firewall**: Restrict access to sensitive internal resources
4. **DNS Filtering**: Use DNS filtering to prevent data exfiltration

### VPN/Proxy Configuration

For enhanced security, route GitHub API traffic through a VPN or proxy:

```bash
# Example: Configure HTTP proxy
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1
```

## Access Control

### SSH Hardening

**Disable Password Authentication:**

Edit `/etc/ssh/sshd_config`:

```
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
AllowUsers poddingue
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

**Use SSH Keys:**

```bash
# Generate ED25519 key (more secure than RSA)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to runner
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@bananapi-ip
```

**SSH Key Passphrase:**

Always use a strong passphrase for SSH keys.

### Sudo Configuration

**Limit sudo access:**

```bash
# Only allow specific commands without password
sudo visudo

# Add line:
poddingue ALL=(ALL) NOPASSWD: /bin/systemctl restart github-runner
poddingue ALL=(ALL) NOPASSWD: /bin/systemctl status github-runner
poddingue ALL=(ALL) NOPASSWD: /bin/journalctl -u github-runner *
```

### User Separation

**Best Practice:**

Create a dedicated user for the runner:

```bash
sudo useradd -m -s /bin/bash github-runner
sudo usermod -aG docker github-runner

# This user should NOT have sudo access
```

## Runner Security

### Repository Restrictions

**Only use runners for trusted repositories:**

- Use for your own repositories only
- Do NOT accept external pull requests on self-hosted runners
- Consider using GitHub-hosted runners for public PRs

### Workflow Restrictions

**In repository settings:**

1. Require approval for all outside collaborators
2. Require approval for first-time contributors
3. Disable workflows from forks

**GitHub Settings Path:**
`Repository → Settings → Actions → General → Fork pull request workflows`

### Runner Labels

**Use specific labels to control job routing:**

```yaml
runs-on: [self-hosted, riscv64, trusted]
```

Create additional labels for sensitive operations:

```bash
./github-act-runner configure --labels self-hosted,riscv64,production
```

### Ephemeral Runners

**Consider using ephemeral runners:**

- Recreate runner after each job
- Prevents state persistence between jobs
- Requires automation (Ansible playbook can help)

## Secrets Management

### Environment Variables

**Never hardcode secrets:**

```yaml
# BAD
- run: echo "MY_TOKEN=ghp_xxx123" >> config.env

# GOOD
- run: echo "MY_TOKEN=${{ secrets.MY_TOKEN }}" >> config.env
```

### .env File Security

**Protect the .env file:**

```bash
# Set restrictive permissions
chmod 600 .env
chown poddingue:poddingue .env

# Verify it's in .gitignore
grep .env .gitignore

# Audit git history for accidentally committed secrets
git log -p | grep -E 'ghp_|github_pat'
```

### GitHub Secrets

**Use GitHub Secrets for sensitive data:**

1. Repository → Settings → Secrets and variables → Actions
2. Add secrets (never echo them in workflows)
3. Use `${{ secrets.SECRET_NAME }}` in workflows

### Secret Rotation

**Rotate secrets regularly:**

- GitHub PAT: Every 90 days
- SSH keys: Every 6 months
- Docker Hub tokens: Every 90 days

## Docker Security

### Docker Socket Access

**WARNING:** The runner user has Docker access, which is equivalent to root!

**Mitigation strategies:**

1. **Use Docker in Docker (DinD)** instead of mounting socket
2. **Rootless Docker**: Run Docker daemon as non-root
3. **gVisor/Kata Containers**: Add additional isolation layer

### Image Trust

**Only use trusted images:**

```yaml
# BAD
- run: docker run random/untrusted-image

# GOOD - Use official images
- run: docker run docker.io/library/alpine:latest
```

**Scan images for vulnerabilities:**

```bash
# Install Trivy
sudo apt install -y trivy

# Scan image
trivy image alpine:latest
```

### Resource Limits

**Prevent resource exhaustion:**

```yaml
# In workflows, use resource limits
- run: |
    docker run --rm \
      --memory="2g" \
      --cpus="2" \
      --pids-limit=100 \
      alpine:latest
```

### Docker Daemon Configuration

**Security settings in `/etc/docker/daemon.json`:**

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "userns-remap": "default",
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp.json"
}
```

## System Hardening

### Automatic Security Updates

**Enable unattended upgrades:**

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Configure in `/etc/apt/apt.conf.d/50unattended-upgrades`:**

```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
```

### Disable Unnecessary Services

```bash
# List running services
systemctl list-units --type=service --state=running

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
```

### File System Security

**Mount partitions with security options:**

```bash
# In /etc/fstab
/dev/mmcblk2p1  /home  ext4  defaults,nodev,nosuid  0  2
```

**Restrict /tmp:**

```bash
sudo mount -o remount,noexec,nosuid,nodev /tmp
```

### Audit Logging

**Enable auditd:**

```bash
sudo apt install -y auditd
sudo systemctl enable auditd
sudo systemctl start auditd
```

**Monitor Docker events:**

```bash
# Add to cron for daily reports
docker events --since 24h --filter 'type=container' > /var/log/docker-events.log
```

## Monitoring and Auditing

### Log Collection

**Centralize logs:**

```bash
# Configure rsyslog to forward to central server
sudo nano /etc/rsyslog.d/50-github-runner.conf

# Add:
*.* @syslog-server.example.com:514
```

### Resource Monitoring

**Track resource usage:**

```bash
# Install monitoring tools
sudo apt install -y prometheus-node-exporter

# Monitor disk space
df -h | mail -s "Runner Disk Space Report" admin@example.com
```

### Workflow Audit

**Review workflow runs regularly:**

```bash
# List recent workflow runs
gh run list --limit 50 --json conclusion,name,createdAt

# Check for suspicious patterns
gh run list | grep -i "mining\|crypto"
```

### File Integrity Monitoring

**Monitor critical files:**

```bash
# Install AIDE
sudo apt install -y aide
sudo aideinit
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Run checks daily
sudo aide --check
```

## Incident Response

### Suspicious Activity Indicators

1. Unexpected CPU/memory usage
2. Unknown Docker containers running
3. Unusual network traffic
4. Failed login attempts
5. Modified system files

### Response Procedure

**If compromise is suspected:**

1. **Isolate**: Disconnect network immediately
   ```bash
   sudo ip link set eth0 down
   ```

2. **Stop Runner**:
   ```bash
   sudo systemctl stop github-runner
   sudo systemctl stop docker
   ```

3. **Preserve Evidence**:
   ```bash
   sudo journalctl -u github-runner > /tmp/runner-logs.txt
   sudo docker ps -a > /tmp/containers.txt
   sudo tar czf /tmp/evidence.tar.gz /var/log /tmp/*.txt
   ```

4. **Revoke Credentials**:
   - Revoke GitHub PAT immediately
   - Remove runner from GitHub repository settings
   - Rotate all SSH keys

5. **Investigate**:
   - Review logs
   - Check running processes
   - Analyze Docker images/containers

6. **Rebuild**:
   - Wipe and reinstall OS
   - Use Ansible playbook for clean setup
   - Generate new secrets

### Emergency Contacts

Document emergency contacts:

- IT Security Team
- GitHub Account Administrator
- Network Administrator

## Security Checklist

### Initial Setup

- [ ] SSH key-based authentication only
- [ ] Firewall configured (UFW enabled)
- [ ] Dedicated user for runner
- [ ] .env file with restrictive permissions
- [ ] GitHub PAT with minimal required scopes
- [ ] Docker daemon secured
- [ ] Automatic security updates enabled

### Regular Maintenance

- [ ] Review workflow runs weekly
- [ ] Monitor system resources daily
- [ ] Check for system updates weekly
- [ ] Rotate secrets quarterly
- [ ] Review and update firewall rules monthly
- [ ] Test backup restoration quarterly
- [ ] Review access logs weekly

### Before Production Use

- [ ] Network isolation implemented
- [ ] Monitoring and alerting configured
- [ ] Backup strategy in place
- [ ] Incident response plan documented
- [ ] Security audit completed
- [ ] Team trained on security procedures

## Additional Resources

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Debian Benchmark](https://www.cisecurity.org/benchmark/debian_linux)
- [Self-Hosted Runner Security](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)

---

**Remember:** Self-hosted runners should only be used for private repositories you trust. Never use them for public repositories that accept outside contributions.

**Last Updated**: 2025-11-30
