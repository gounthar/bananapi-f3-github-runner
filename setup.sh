#!/bin/bash
#
# Setup script for Banana Pi F3 GitHub Actions Runner
# This script configures environment variables and runs the Ansible playbook
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

#------------------------------------------------------------------------------
# Dependency checks
#------------------------------------------------------------------------------
check_dependencies() {
    local missing=()

    echo -e "${BLUE}Checking dependencies...${NC}"

    # Check for Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        missing+=("ansible")
        echo -e "${RED}  [MISSING] ansible-playbook${NC}"
        echo "    Install on Debian/Ubuntu: sudo apt install ansible"
    else
        echo -e "${GREEN}  [OK] ansible-playbook${NC}"
    fi

    # Check for SSH
    if ! command -v ssh &> /dev/null; then
        missing+=("ssh")
        echo -e "${RED}  [MISSING] ssh${NC}"
        echo "    Install on Debian/Ubuntu: sudo apt install openssh-client"
    else
        echo -e "${GREEN}  [OK] ssh${NC}"
    fi

    # Check for curl (for GitHub API validation)
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
        echo -e "${RED}  [MISSING] curl${NC}"
        echo "    Install on Debian/Ubuntu: sudo apt install curl"
    else
        echo -e "${GREEN}  [OK] curl${NC}"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        echo "Please install them and run this script again."
        exit 1
    fi

    echo ""
}

#------------------------------------------------------------------------------
# Load existing configuration if present
#------------------------------------------------------------------------------
load_existing_config() {
    if [ -f "$ENV_FILE" ]; then
        echo -e "${BLUE}Loading existing configuration from .env...${NC}"
        set -a
        source "$ENV_FILE"
        set +a
    fi
}

#------------------------------------------------------------------------------
# Prompt for configuration
#------------------------------------------------------------------------------
prompt_config() {
    echo -e "${BLUE}=== Banana Pi F3 GitHub Runner Setup ===${NC}"
    echo ""

    # GitHub Repository
    echo -e "${YELLOW}GitHub Configuration${NC}"
    read -p "GitHub Repository (e.g., username/repo) [${GITHUB_REPOSITORY:-gounthar/docker-for-riscv64}]: " input
    GITHUB_REPOSITORY="${input:-${GITHUB_REPOSITORY:-gounthar/docker-for-riscv64}}"

    if [ -z "$GITHUB_REPOSITORY" ]; then
        echo -e "${RED}Error: GitHub repository is required${NC}"
        exit 1
    fi

    # GitHub PAT
    echo ""
    echo "GitHub Personal Access Token (PAT)"
    echo "  Required scopes: repo, workflow"
    echo "  Create at: https://github.com/settings/tokens"
    read -sp "GitHub PAT [hidden]: " input
    echo ""
    if [ -n "$input" ]; then
        GITHUB_PAT="$input"
    fi

    if [ -z "$GITHUB_PAT" ]; then
        echo -e "${RED}Error: GitHub PAT is required${NC}"
        exit 1
    fi

    # Runner Name
    echo ""
    echo -e "${YELLOW}Runner Configuration${NC}"
    read -p "Runner Name (unique identifier) [${RUNNER_NAME:-bananapi-f3-runner}]: " input
    RUNNER_NAME="${input:-${RUNNER_NAME:-bananapi-f3-runner}}"

    # Banana Pi IP Address
    echo ""
    echo -e "${YELLOW}Network Configuration${NC}"
    read -p "Banana Pi F3 IP Address [${BANANAPI_IP:-192.168.1.185}]: " input
    BANANAPI_IP="${input:-${BANANAPI_IP:-192.168.1.185}}"

    # SSH User
    read -p "SSH Username [${SSH_USER:-poddingue}]: " input
    SSH_USER="${input:-${SSH_USER:-poddingue}}"

    # SSH Key Path
    local default_key="${SSH_KEY_PATH:-${HOME}/.ssh/bananapi-f3}"
    read -p "SSH Private Key Path [${default_key}]: " input
    SSH_KEY_PATH="${input:-${default_key}}"
    # Expand ~ to $HOME if present
    SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"

    # Runner working directory
    read -p "Runner Working Directory [${RUNNER_WORKDIR:-/home/${SSH_USER}/github-act-runner}]: " input
    RUNNER_WORKDIR="${input:-${RUNNER_WORKDIR:-/home/${SSH_USER}/github-act-runner}}"

    # Runner user (usually same as SSH user)
    RUNNER_USER="${SSH_USER}"

    echo ""
}

#------------------------------------------------------------------------------
# Validate GitHub PAT
#------------------------------------------------------------------------------
validate_github_pat() {
    echo -e "${BLUE}Validating GitHub credentials...${NC}"

    # Test PAT authentication
    local response
    response=$(curl -s -w "\n%{http_code}" -H "Authorization: token ${GITHUB_PAT}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}")

    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        local repo_name
        repo_name=$(echo "$body" | grep -o '"full_name": *"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}  [OK] PAT is valid${NC}"
        echo -e "${GREEN}  [OK] Repository found: ${repo_name}${NC}"
    elif [ "$http_code" = "401" ]; then
        echo -e "${RED}  [FAIL] Invalid GitHub PAT (401 Unauthorized)${NC}"
        echo "  Please check your token and try again."
        exit 1
    elif [ "$http_code" = "404" ]; then
        echo -e "${RED}  [FAIL] Repository not found (404)${NC}"
        echo "  Either the repository doesn't exist or the PAT lacks access."
        exit 1
    else
        echo -e "${RED}  [FAIL] Unexpected response: HTTP ${http_code}${NC}"
        exit 1
    fi

    # Check PAT scopes
    local scopes
    scopes=$(curl -sI -H "Authorization: token ${GITHUB_PAT}" \
        "https://api.github.com/user" | grep -i "x-oauth-scopes:" | cut -d: -f2-)

    echo -e "  PAT scopes:${scopes}"

    # Verify both required scopes are present
    if ! (echo "$scopes" | grep -qw "repo" && echo "$scopes" | grep -qw "workflow"); then
        echo -e "${RED}  [FAIL] PAT is missing required scopes ('repo', 'workflow').${NC}"
        echo "  Please create a new token with these scopes at:"
        echo "  https://github.com/settings/tokens"
        exit 1
    fi
    echo -e "${GREEN}  [OK] Required scopes present${NC}"

    echo ""
}

#------------------------------------------------------------------------------
# Setup SSH key (create if missing, copy to target)
#------------------------------------------------------------------------------
setup_ssh_key() {
    echo -e "${BLUE}Checking SSH key...${NC}"

    # Check if private key exists
    if [ -f "$SSH_KEY_PATH" ]; then
        echo -e "${GREEN}  [OK] SSH key found: ${SSH_KEY_PATH}${NC}"
    else
        echo -e "${YELLOW}  [!] SSH key not found: ${SSH_KEY_PATH}${NC}"
        echo ""
        read -p "Would you like to create a new SSH key pair? [Y/n]: " create_key

        if [[ ! "$create_key" =~ ^[Nn] ]]; then
            echo ""
            echo -e "${BLUE}Creating SSH key pair...${NC}"

            # Create .ssh directory if it doesn't exist
            mkdir -p "$(dirname "$SSH_KEY_PATH")"
            chmod 700 "$(dirname "$SSH_KEY_PATH")"

            # Generate ed25519 key (more secure and shorter than RSA)
            ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -C "bananapi-f3-runner@$(hostname)"

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}  [OK] SSH key pair created${NC}"
                echo "  Private key: ${SSH_KEY_PATH}"
                echo "  Public key:  ${SSH_KEY_PATH}.pub"
            else
                echo -e "${RED}  [FAIL] Failed to create SSH key${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Cannot proceed without SSH key.${NC}"
            echo "Please create a key manually or specify an existing key path."
            exit 1
        fi
    fi

    # Check if public key needs to be copied to target
    echo ""
    echo -e "${BLUE}Checking if public key is installed on target...${NC}"

    # Try to connect without password to see if key is already authorized
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
        -o PasswordAuthentication=no -o BatchMode=yes \
        "${SSH_USER}@${BANANAPI_IP}" "exit 0" 2>/dev/null; then
        echo -e "${GREEN}  [OK] Public key already authorized on ${BANANAPI_IP}${NC}"
    else
        echo -e "${YELLOW}  [!] Public key not yet authorized on target${NC}"
        echo ""
        echo "To copy your public key to the Banana Pi F3, run:"
        echo ""
        echo -e "${BLUE}  ssh-copy-id -o IdentitiesOnly=yes -i ${SSH_KEY_PATH}.pub ${SSH_USER}@${BANANAPI_IP}${NC}"
        echo ""
        read -p "Would you like to run ssh-copy-id now? [Y/n]: " copy_key

        if [[ ! "$copy_key" =~ ^[Nn] ]]; then
            echo ""
            echo -e "${BLUE}Copying public key to ${BANANAPI_IP}...${NC}"
            echo "(You may be prompted for the password on the Banana Pi F3)"
            echo ""

            ssh-copy-id -o IdentitiesOnly=yes -i "${SSH_KEY_PATH}.pub" "${SSH_USER}@${BANANAPI_IP}"

            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}  [OK] Public key copied successfully${NC}"
            else
                echo ""
                echo -e "${RED}  [FAIL] Failed to copy public key${NC}"
                echo "Please copy it manually and run this script again."
                exit 1
            fi
        else
            echo ""
            echo -e "${YELLOW}Please copy the key manually before continuing.${NC}"
            read -p "Press Enter when ready, or Ctrl+C to abort..."
        fi
    fi

    echo ""
}

#------------------------------------------------------------------------------
# Test SSH connectivity
#------------------------------------------------------------------------------
test_ssh_connection() {
    echo -e "${BLUE}Testing SSH connection to Banana Pi F3...${NC}"

    # SSH_KEY_PATH is set by prompt_config() and validated by setup_ssh_key()
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}  [FAIL] SSH key not found: ${SSH_KEY_PATH}${NC}"
        echo "  Please run setup_ssh_key first or check the key path."
        exit 1
    fi

    # Test actual SSH connectivity with a command
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
        "${SSH_USER}@${BANANAPI_IP}" "echo 'SSH connection successful'" 2>/dev/null; then
        echo -e "${GREEN}  [OK] SSH connection to ${BANANAPI_IP} successful${NC}"
    else
        echo -e "${RED}  [FAIL] Cannot connect to ${SSH_USER}@${BANANAPI_IP}${NC}"
        echo "  Please check the IP address and SSH configuration."
        exit 1
    fi

    echo ""
}

#------------------------------------------------------------------------------
# Save configuration to .env
#------------------------------------------------------------------------------
save_config() {
    echo -e "${BLUE}Saving configuration to .env...${NC}"

    cat > "$ENV_FILE" << EOF
# GitHub Configuration
# Repository where the runner will be registered
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}

# GitHub Personal Access Token (PAT)
# Required scopes: repo, workflow, admin:org (for org runners)
# Create at: https://github.com/settings/tokens
GITHUB_PAT=${GITHUB_PAT}

# Runner Configuration
# Name for the runner (will appear in GitHub UI)
RUNNER_NAME=${RUNNER_NAME}

# Working directory for the runner
RUNNER_WORKDIR=${RUNNER_WORKDIR}

# User account that will run the runner service
RUNNER_USER=${RUNNER_USER}

# Runner labels (comma-separated, these are automatic: self-hosted,linux,riscv64)
# Add custom labels if needed
RUNNER_LABELS=

# System Configuration
# IP address of the Banana Pi F3 (for Ansible)
BANANAPI_IP=${BANANAPI_IP}

# SSH user for Ansible connections
SSH_USER=${SSH_USER}

# SSH key path for Ansible connections
SSH_KEY_PATH=${SSH_KEY_PATH}

# Optional: Docker Hub Configuration
# Only needed if you're pulling private images
DOCKERHUB_USERNAME=
DOCKERHUB_TOKEN=

# Optional: Build Configuration
# Go version to install (if building from source)
GO_VERSION=1.24.4

# GitHub Act Runner version (tag or branch)
RUNNER_VERSION=main

# Optional: Monitoring
# Enable Prometheus metrics export (true/false)
ENABLE_METRICS=false

# Metrics port
METRICS_PORT=9090

# Optional: Cleanup Configuration
# Enable automatic workspace cleanup (true/false)
AUTO_CLEANUP=true

# Disk space threshold for cleanup (percentage)
CLEANUP_THRESHOLD=80

# Optional: Notification Configuration
# Telegram bot token for notifications
TELEGRAM_BOT_TOKEN=

# Telegram chat ID
TELEGRAM_CHAT_ID=
EOF

    # Secure file permissions - only owner can read sensitive credentials
    chmod 600 "$ENV_FILE"

    echo -e "${GREEN}  [OK] Configuration saved${NC}"
    echo ""
}

#------------------------------------------------------------------------------
# Run Ansible playbook
#------------------------------------------------------------------------------
run_ansible() {
    echo -e "${BLUE}Running Ansible playbook...${NC}"
    echo ""

    cd "$SCRIPT_DIR"

    # Export environment variables for Ansible
    set -a
    source "$ENV_FILE"
    set +a

    ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory.yml playbooks/setup-runner.yml

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=== Setup Complete ===${NC}"
        echo ""
        echo "Runner '${RUNNER_NAME}' should now be registered and running."
        echo ""
        echo "Verify at: https://github.com/${GITHUB_REPOSITORY}/settings/actions/runners"
        echo ""
        echo "Useful commands on the Banana Pi F3:"
        echo "  sudo systemctl status github-runner    # Check service status"
        echo "  sudo journalctl -u github-runner -f    # View logs"
        echo "  sudo systemctl restart github-runner   # Restart service"
    else
        echo ""
        echo -e "${RED}=== Setup Failed ===${NC}"
        echo "Please check the error messages above."
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
main() {
    echo ""
    echo "=============================================="
    echo " Banana Pi F3 GitHub Actions Runner Setup"
    echo "=============================================="
    echo ""

    check_dependencies
    load_existing_config
    prompt_config
    validate_github_pat
    setup_ssh_key
    test_ssh_connection
    save_config

    echo -e "${YELLOW}Ready to run Ansible playbook.${NC}"
    read -p "Continue? [Y/n]: " confirm

    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Aborted. Configuration saved to .env"
        echo "Run this script again or manually run:"
        echo "  source .env && ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory.yml playbooks/setup-runner.yml"
        exit 0
    fi

    run_ansible
}

# Run main function
main "$@"
