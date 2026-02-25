#!/usr/bin/env bash
# install-prerequisites.sh
# Installs prerequisites for the Azure Monitor Workspace Terraform project.
# Supports: Ubuntu/Debian (apt), RHEL/Fedora/CentOS (dnf/yum), and macOS (brew).
# Run with: bash tools/install-prerequisites.sh

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step()  { echo -e "\n${CYAN}==> $*${NC}"; }
ok()    { echo -e "${GREEN}    $*${NC}"; }
warn()  { echo -e "${YELLOW}    $*${NC}"; }

# ── Detect OS ────────────────────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "$ID" in
      ubuntu|debian|linuxmint) echo "debian" ;;
      rhel|centos|fedora|rocky|almalinux) echo "rhel" ;;
      *) echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

OS=$(detect_os)
step "Detected OS family: $OS"

# ── Helper: check if a command exists ────────────────────────
has() { command -v "$1" &>/dev/null; }

# ── 1. Package manager bootstrap ─────────────────────────────
step "Updating package index"
case "$OS" in
  debian) sudo apt-get update -qq ;;
  rhel)   sudo dnf check-update -q || true ;;   # dnf returns 100 when updates exist
  macos)
    if ! has brew; then
      warn "Homebrew not found. Installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update --quiet
    ;;
  *)
    echo "Unsupported OS. Install Terraform >= 1.3 and Azure CLI manually."
    echo "  Terraform : https://developer.hashicorp.com/terraform/install"
    echo "  Azure CLI : https://learn.microsoft.com/cli/azure/install-azure-cli"
    exit 1
    ;;
esac

# ── 2. Terraform ─────────────────────────────────────────────
step "Installing Terraform (>= 1.3)"
if has terraform; then
  ok "Terraform already installed: $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])')"
else
  case "$OS" in
    debian)
      sudo apt-get install -y gnupg software-properties-common curl
      curl -fsSL https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
      sudo apt-get update -qq
      sudo apt-get install -y terraform
      ;;
    rhel)
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager --add-repo \
        https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      sudo dnf install -y terraform
      ;;
    macos)
      brew tap hashicorp/tap
      brew install hashicorp/tap/terraform
      ;;
  esac
  ok "Terraform installed: $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])')"
fi

# ── 3. Azure CLI ─────────────────────────────────────────────
step "Installing Azure CLI"
if has az; then
  ok "Azure CLI already installed: $(az version --output tsv --query '\"azure-cli\"')"
else
  case "$OS" in
    debian)
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      ;;
    rhel)
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      sudo dnf install -y \
        "https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm" \
        || true
      sudo dnf install -y azure-cli
      ;;
    macos)
      brew install azure-cli
      ;;
  esac
  ok "Azure CLI installed: $(az version --output tsv --query '\"azure-cli\"')"
fi

# ── 4. Summary ───────────────────────────────────────────────
echo ""
echo -e "${GREEN}---------------------------------------------------${NC}"
echo -e "${GREEN} All prerequisites installed.${NC}"
echo -e "${GREEN} Next steps:${NC}"
echo -e "${YELLOW}   az login${NC}"
echo -e "${YELLOW}   terraform init${NC}"
echo -e "${YELLOW}   terraform plan${NC}"
echo -e "${GREEN}---------------------------------------------------${NC}"
