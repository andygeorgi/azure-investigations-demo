# Azure Monitor Workspace — Issues & Investigations Demo

A Terraform project that provisions a complete **Azure Monitor Workspace (AMW)** environment, wires it to a subscription as the default workspace, and deploys one or more demo scenarios for **Issues & Investigations (preview)**. Each scenario creates a fault condition, triggers an alert, and walks through the full investigation and AI-assisted remediation flow.

---

## TL;DR

Deploys in minutes. Small, pay-as-you-go footprint.

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars → set enabled_scenarios, alert_email, and scenario-specific values
terraform init && terraform apply
```

---

## Architecture

```
Subscription
└── Resource Group  (var.resource_group_name)
    ├── module: amw-subscription-association
    │   ├── Azure Monitor Workspace          (var.amw_name)
    │   ├── Subscription AMW association     (Microsoft.Monitor/settings/default)  [AzAPI]
    │   └── RBAC role assignment             (optional)
    ├── Shared Log Analytics Workspace       (var.law_name)
    └── scenario modules (selected by var.enabled_scenarios)
        ├── availability-url-failure (implemented)
        ├── vm-connectivity-loss (implemented)
        └── appgw-backend-unhealthy (implemented)
```

The **Azure Monitor Workspace** acts as the subscription-level default, which unlocks the **Issues & Investigations** blade in the Azure Portal.

---

## Scenarios

Select scenarios with `enabled_scenarios` in `terraform.tfvars`. Each scenario deploys its own fault condition, alert and investigation workflow.

| Scenario | Status | Description |
|----------|--------|-------------|
| [Availability URL Failure](scenarios/availability-url-failure/README.md) | Implemented (default) | Web test probes a URL; trigger by pointing at an invalid endpoint |
| [VM Connectivity Loss](scenarios/vm-connectivity-loss/README.md) | Implemented | NSG deny rule blocks VM egress; Connection Monitor detects the failure |
| [App Gateway Backend Unhealthy](scenarios/appgw-backend-unhealthy/README.md) | Implemented | Application Gateway backend health degradation via NSG misconfiguration |

---

## Repository Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
├── .gitignore
├── README.md
├── assets/
│   └── screenshots/
│       ├── availability-url-failure/
│       ├── vm-connectivity-loss/
│       └── appgw-backend-unhealthy/
├── scenarios/
│   ├── availability-url-failure/        # Scenario-specific docs
│   ├── vm-connectivity-loss/            # Scenario-specific docs
│   └── appgw-backend-unhealthy/         # Scenario-specific docs
├── tools/
│   ├── install-prerequisites.ps1        # Windows prerequisite installer (winget)
│   └── install-prerequisites.sh         # Linux / macOS prerequisite installer
└── modules/
    ├── amw-subscription-association/    # AMW + preview API subscription wiring
    ├── availability-monitoring/         # LAW + APPI + Web Test + Alert stack
    ├── vm-connectivity-monitoring/      # VM + AMA + connectivity alert + remediation
    └── appgw-backend-monitoring/        # App Gateway + backend VM + health alert
```

---

## What gets deployed

### Baseline (always)

| # | Resource | Purpose |
|---|----------|---------|
| 1 | Azure Monitor Workspace | Subscription-level default, unlocks Issues & Investigations |
| 2 | Subscription → AMW association (preview API) | Wires the AMW to the subscription via AzAPI |
| 3 | RBAC role assignment *(optional)* | Grants the deploying principal access to the AMW |
| 4 | Shared Log Analytics Workspace | Central log destination for all scenarios |

Scenario-specific resources are documented in each scenario README under `scenarios/`.

### Availability URL Failure

| # | Resource | Purpose |
|---|----------|---------|
| 5 | Application Insights (workspace-mode) | Linked to shared LAW |
| 6 | Classic ping web test | Probes target URL every 5 min from 2 US regions |
| 7 | Action Group (email) | Sends alert notification |
| 8 | Metric Alert (≥ 1 location failed) | Fires when availability drops |

### VM Connectivity Loss

| # | Resource | Purpose |
|---|----------|---------|
| 9  | Linux VM + VNet + Subnet + NSG | Demo infrastructure |
| 10 | Azure Monitor Agent + Network Watcher Agent | VM extensions for monitoring and connection testing |
| 11 | Data Collection Rule + association | Routes Heartbeat data to shared LAW |
| 12 | Connection Monitor | Tests TCP/443 to Azure Monitor endpoint every 60s |
| 13 | Metric Alert (`ChecksFailedPercent > 0`) | Fires when connectivity checks fail |
| 14 | Action Group (email) | Sends alert notification |

### App Gateway Backend Unhealthy

| # | Resource | Purpose |
|---|----------|---------|
| 15 | VNet + App Gateway subnet + Backend subnet | Network foundation with dedicated subnets |
| 16 | NSG (backend subnet) | Controls inbound traffic to backend VM |
| 17 | Public IP (Standard, static) | Frontend IP for the Application Gateway |
| 18 | Linux VM + NIC | Backend web server (Python 3 HTTP server via cloud-init) |
| 19 | Application Gateway v2 (Standard_v2) | Ingress with backend pool, health probe, listener and routing rule |
| 20 | Metric Alert (`UnhealthyHostCount > 0`) | Fires when backend hosts are unhealthy |
| 21 | Action Group (email) | Sends alert notification |

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Terraform | >= 1.3 |
| Azure CLI | Authenticated (`az login`) |
| Permissions | `Contributor` on the target subscription; `User Access Administrator` if `assign_amw_role = true` |

Helper scripts in `tools/` install Terraform and Azure CLI automatically:

```powershell
# Windows
.\tools\install-prerequisites.ps1
```

```bash
# Linux / macOS
bash tools/install-prerequisites.sh
```

---

## Variables

**Must change**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enabled_scenarios` | `list(string)` | `['availability-url-failure']` | Scenarios to deploy. Available: `availability-url-failure`, `vm-connectivity-loss`, `appgw-backend-unhealthy` |
| `alert_email` | `string` | `replace-me@example.com` | Notification email address |
| `webtest_url` | `string` | `https://www.microsoft.com` | URL probed by the web test |

**Defaults are usually fine**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `westeurope` | Azure region for all resources |
| `resource_group_name` | `string` | `amw-iidemo-rg` | Resource group name |
| `amw_name` | `string` | `amw-iidemo-amw` | Azure Monitor Workspace name |
| `law_name` | `string` | `amw-iidemo-law` | Log Analytics Workspace name |
| `appi_name` | `string` | `amw-iidemo-appi` | Application Insights name |
| `webtest_name` | `string` | `amw-iidemo-webtest` | Web test name |
| `action_group_name` | `string` | `amw-iidemo-ag` | Action Group name |
| `alert_name` | `string` | `amw-iidemo-avail-alert` | Metric alert name |
| `vm_name` | `string` | `amw-iidemo-vm` | Demo VM name |
| `vm_vnet_name` | `string` | `amw-iidemo-vnet` | VNet name for VM scenario |
| `vm_subnet_name` | `string` | `default` | Subnet name for VM scenario |
| `vm_nsg_name` | `string` | `amw-iidemo-vm-nsg` | NSG name for VM scenario |
| `vm_nic_name` | `string` | `amw-iidemo-vm-nic` | NIC name for VM scenario |
| `vm_action_group_name` | `string` | `amw-iidemo-vm-ag` | Action Group name for VM connectivity alert |
| `vm_alert_name` | `string` | `amw-iidemo-vm-connectivity-alert` | Metric alert name for connectivity loss |
| `vm_dcr_name` | `string` | `amw-iidemo-vm-dcr` | Data Collection Rule name |
| `vm_size` | `string` | `Standard_B2s` | VM size |
| `vm_admin_username` | `string` | `azureuser` | Admin username for VM connectivity scenario VM |
| `vm_connectivity_block_outbound_443` | `bool` | `false` | Toggle NSG misconfiguration to trigger connectivity loss |
| `appgw_name` | `string` | `amw-iidemo-appgw` | Application Gateway name |
| `appgw_vnet_name` | `string` | `amw-iidemo-appgw-vnet` | VNet name for App Gateway scenario |
| `appgw_subnet_name` | `string` | `appgw` | Dedicated App Gateway subnet name |
| `appgw_backend_subnet_name` | `string` | `backend` | Backend subnet name |
| `appgw_nsg_name` | `string` | `amw-iidemo-appgw-nsg` | NSG name for App Gateway backend subnet |
| `appgw_pip_name` | `string` | `amw-iidemo-appgw-pip` | Public IP name for App Gateway |
| `appgw_backend_vm_name` | `string` | `amw-iidemo-appgw-vm` | Backend VM name |
| `appgw_backend_vm_nic_name` | `string` | `amw-iidemo-appgw-vm-nic` | Backend VM NIC name |
| `appgw_action_group_name` | `string` | `amw-iidemo-appgw-ag` | Action Group name for App Gateway alert |
| `appgw_alert_name` | `string` | `amw-iidemo-appgw-health-alert` | Metric alert name for backend health |
| `appgw_vm_size` | `string` | `Standard_B2s` | Backend VM size |
| `appgw_vm_admin_username` | `string` | `azureuser` | Admin username for App Gateway backend VM |
| `appgw_block_backend_health_probe` | `bool` | `false` | Toggle NSG misconfiguration to block health-probe traffic |
| `assign_amw_role` | `bool` | `true` | Assign an RBAC role on the AMW to the deploying principal |
| `amw_role_definition_name` | `string` | `Monitoring Contributor` | Role to assign (`Contributor`, `Monitoring Contributor`, or `Issue Contributor`) |

---

## Outputs

| Name | Description |
|------|-------------|
| `amw_id` | Azure Monitor Workspace resource ID |
| `selected_scenarios` | Scenarios requested for deployment |
| `amw_subscription_association_id` | Subscription-level AMW association resource ID |
| `application_insights_id` | Application Insights resource ID |
| `webtest_id` | Web test resource ID |
| `availability_alert_id` | Metric alert rule resource ID |
| `vm_id` | Demo VM resource ID for connectivity scenario |
| `shared_law_id` | Shared Log Analytics Workspace resource ID |
| `vm_connectivity_alert_id` | Connectivity metric alert rule resource ID |
| `vm_action_group_id` | Connectivity scenario Action Group resource ID |
| `appgw_id` | Application Gateway resource ID |
| `appgw_backend_vm_id` | Backend VM resource ID for App Gateway scenario |
| `appgw_health_alert_id` | Backend health metric alert rule resource ID |
| `appgw_action_group_id` | App Gateway scenario Action Group resource ID |

---

## Quick Start

Copy the example, set the minimal values, and deploy:

```bash
cp terraform.tfvars.example terraform.tfvars
```

```hcl
enabled_scenarios = ["availability-url-failure"]
alert_email       = "you@example.com"
webtest_url       = "https://your-app.example.com"
```

```bash
terraform init && terraform apply
```

Then follow the step-by-step walkthrough for your chosen scenario.

---

## Demo Walkthroughs

Each scenario README contains a full step-by-step walkthrough — from deployment through fault injection, investigation, AI-assisted diagnosis, remediation, and recovery.

- [Availability URL Failure](scenarios/availability-url-failure/README.md)
- [VM Connectivity Loss](scenarios/vm-connectivity-loss/README.md)
- [App Gateway Backend Unhealthy](scenarios/appgw-backend-unhealthy/README.md)

---

## Notes

- The subscription AMW association uses the **preview API `2025-06-03-preview`** via `azapi_resource` (`Microsoft.Monitor/settings`), which is not yet supported by the `azurerm` provider.
- Web test geo-locations use classic internal codes (`us-tx-sn1-azr`, `us-il-ch1-azr`). Update `modules/availability-monitoring/main.tf` to change regions.
- Remediation across all scenarios follows a **human-in-the-loop** pattern: the Observability Agent in Issues & Investigations diagnoses the root cause and recommends a fix; the operator approves and executes it.
- A destroy-time provisioner calls `az rest --method DELETE` to remove the subscription association before Terraform deletes the AMW, preventing orphaned ARM state.
