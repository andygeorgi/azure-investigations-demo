# install-prerequisites.ps1
# Installs prerequisites for the Azure Monitor Workspace Terraform project.
# Requirements: Windows 10/11 with winget available (App Installer >= 1.21).
# Run as a regular user — winget does not require elevation for most packages.
# Terraform and Azure CLI installers will prompt for UAC if needed.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Test-CommandExists([string]$Command) {
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# -------------------------------------------------------------
# 1. Winget presence check
# -------------------------------------------------------------
Write-Step "Checking winget"
if (-not (Test-CommandExists "winget")) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store and re-run."
}
Write-Host "winget found: $(winget --version)"

# -------------------------------------------------------------
# 2. Terraform
# -------------------------------------------------------------
Write-Step "Installing Terraform (>= 1.3)"
if (Test-CommandExists "terraform") {
    $tfVersion = (terraform version -json | ConvertFrom-Json).terraform_version
    Write-Host "Terraform already installed: $tfVersion"
} else {
    winget install --id Hashicorp.Terraform --accept-source-agreements --accept-package-agreements
}

# -------------------------------------------------------------
# 3. Azure CLI
# -------------------------------------------------------------
Write-Step "Installing Azure CLI"
if (Test-CommandExists "az") {
    $azVersion = (az version --output json | ConvertFrom-Json).'azure-cli'
    Write-Host "Azure CLI already installed: $azVersion"
} else {
    winget install --id Microsoft.AzureCLI --accept-source-agreements --accept-package-agreements
}

# -------------------------------------------------------------
# 4. Summary
# -------------------------------------------------------------
Write-Host ""
Write-Host "---------------------------------------------------" -ForegroundColor Green
Write-Host " All prerequisites installed." -ForegroundColor Green
Write-Host " Next steps:" -ForegroundColor Green
Write-Host "   az login" -ForegroundColor Yellow
Write-Host "   terraform init" -ForegroundColor Yellow
Write-Host "   terraform plan" -ForegroundColor Yellow
Write-Host "---------------------------------------------------" -ForegroundColor Green
