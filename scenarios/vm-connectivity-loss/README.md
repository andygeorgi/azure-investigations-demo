# Scenario: VM Connectivity Loss

Status: **Implemented**.

## Goal

Demonstrate an infrastructure incident where a network misconfiguration (NSG deny rule) blocks the VM's outbound HTTPS connectivity to Azure Monitor, triggering an alert. Then walk through the full **Issues & Investigations (preview)** workflow — from detection to AI-assisted root-cause analysis to manual remediation.

## Terraform selector

```hcl
enabled_scenarios = ["vm-connectivity-loss"]
```

## What gets deployed

When selected, module `vm-connectivity-monitoring` creates:

| # | Resource | Purpose |
|---|----------|---------|
| 1 | Linux VM + VNet + Subnet + NSG | Demo infrastructure |
| 2 | Azure Monitor Agent (VM extension) | Sends monitoring data |
| 3 | Network Watcher Agent (VM extension) | Required for Connection Monitor |
| 4 | Data Collection Rule + association | Routes Heartbeat data to shared LAW |
| 5 | Connection Monitor | Tests TCP/443 to `global.handler.control.monitor.azure.com` every 60s |
| 6 | Metric Alert (`ChecksFailedPercent > 0`) | Fires when connectivity checks fail |
| 7 | Action Group (email) | Sends alert notification |

## Demo Walkthrough

### Step 1 — Deploy the healthy baseline

Copy the example variables file and configure it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — set the scenario and your email, ensure the block is off:

```hcl
enabled_scenarios                  = ["vm-connectivity-loss"]
alert_email                        = "you@example.com"
vm_connectivity_block_outbound_443 = false
```

Deploy:

```bash
terraform init
terraform apply
```

After deploy, wait **~5–10 minutes** for the Connection Monitor to run a few successful test cycles.

To check the status, go to **Azure Portal → Network Watcher → Connection monitors** → click `amw-iidemo-vm-cm`. Once you see test results with **0% checks failed**, the baseline is healthy.

Verify the baseline is healthy:

![Connection Monitor — healthy baseline](../../assets/screenshots/vm-connectivity-loss/01-connection-monitor-healthy.png)

### Step 2 — Trigger the incident

Set the block variable to `true`:

```hcl
vm_connectivity_block_outbound_443 = true
```

Apply:

```bash
terraform apply
```

This adds an NSG outbound deny rule (`deny-outbound-https`, priority 200) blocking all TCP/443 egress from the VM, breaking the Connection Monitor's probe to Azure Monitor.

![NSG deny rule applied](../../assets/screenshots/vm-connectivity-loss/03-nsg-deny-rule.png)

### Step 3 — Observe the failure

Within **~5–10 minutes**, the Connection Monitor begins reporting failed checks:

![Connection Monitor — checks failing](../../assets/screenshots/vm-connectivity-loss/04-connection-monitor-failing.png)

The metric alert fires and you receive an email notification.

To view the alert details, either:
- Click the **View in Azure Monitor** link in the notification email, or
- Go to **Azure Portal → Monitor → Alerts**, filter by resource group `amw-iidemo-rg`, and click the fired alert

![Alert fired](../../assets/screenshots/vm-connectivity-loss/05-alert-fired.png)

The alert detail page shows severity, description, affected scope and timestamps:

![Alert detail](../../assets/screenshots/vm-connectivity-loss/06-alert-detail.png)

### Step 4 — Investigate with Issues & Investigations (preview)

From the fired alert detail page, click **Investigate (preview)** to open the Issues & Investigations blade:

![Investigate preview](../../assets/screenshots/vm-connectivity-loss/07-investigate-preview.png)

Drill into **Issues (preview)** to view the issue context, affected resources and correlated signals:

![Issue detail](../../assets/screenshots/vm-connectivity-loss/08-issue-detail.png)

### Step 5 — AI-assisted root-cause analysis

Use the context-specific Copilot chat in the Investigation/Issue view. Ask a question like:

> *"What is causing this VM connectivity failure and how can I fix it?"*

The Observability Agent identifies the root cause (NSG deny rule) and provides the exact remediation steps:

![AI chat remediation suggestion](../../assets/screenshots/vm-connectivity-loss/09-ai-chat-remediation.png)

### Step 6 — Apply the fix (human in the loop)

Following the AI's recommendation, add an NSG allow rule with a higher priority (lower number) than the deny rule to restore Azure Monitor connectivity. Execute the remediation command in the Azure Portal Cloud Shell:

![Remediation execution in Cloud Shell](../../assets/screenshots/vm-connectivity-loss/10-nsg-allow-rule-added.png)

### Step 7 — Confirm recovery

After **~5–10 minutes**, the Connection Monitor reports healthy checks again:

![Connection Monitor — recovered](../../assets/screenshots/vm-connectivity-loss/11-connection-monitor-recovered.png)

The metric alert auto-resolves:

![Alert resolved](../../assets/screenshots/vm-connectivity-loss/12-alert-resolved.png)

## Key takeaways

- **Issues & Investigations (preview)** provides contextual correlation of alerts, affected resources and activity signals in a single view.
- The **Observability Agent** correctly identifies the NSG deny rule as the root cause and provides actionable remediation steps.
- Remediation is **human-in-the-loop** — the AI advises, the operator approves and executes.
- The full cycle — detect → investigate → diagnose → fix → verify — is demonstrated end to end.

## Notes

- This scenario reuses the shared Log Analytics Workspace defined by `law_name` in root config.
- The NSG deny rule priority is set to 200, allowing a higher-priority allow rule to be inserted for remediation without deleting the deny rule.
- This scenario is infrastructure-only and does not require application code.
