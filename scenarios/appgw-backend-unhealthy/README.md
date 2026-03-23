# Scenario: App Gateway Backend Unhealthy

Status: **Implemented**.

## Goal

Demonstrate an infrastructure incident where an Application Gateway's backend health probe is blocked by an NSG misconfiguration, causing the backend to be marked unhealthy and triggering an alert. Then walk through the full **Issues & Investigations (preview)** workflow — from detection to AI-assisted root-cause analysis to manual remediation.

## Terraform selector

```hcl
enabled_scenarios = ["appgw-backend-unhealthy"]
```

## What gets deployed

When selected, module `appgw-backend-monitoring` creates:

| # | Resource | Purpose |
|---|----------|---------|
| 1 | VNet + App Gateway subnet + Backend subnet | Network foundation with dedicated subnets |
| 2 | NSG (backend subnet) | Controls inbound traffic to the backend VM |
| 3 | Public IP (Standard, static) | Frontend IP for the Application Gateway |
| 4 | Linux VM + NIC | Backend web server (Python 3 HTTP server via cloud-init) |
| 5 | Application Gateway v2 (Standard_v2) | Ingress layer with backend pool, health probe, HTTP listener and routing rule |
| 6 | Metric Alert (`UnhealthyHostCount > 0`) | Fires when one or more backend hosts are unhealthy |
| 7 | Action Group (email) | Sends alert notification |

### How the health probe works

The Application Gateway continuously sends HTTP GET requests to each backend on port 80 (path `/`). When the backend responds with a `200–399` status within the timeout, it is **healthy**. After three consecutive failures (≈ 90 seconds), the backend is marked **unhealthy** and the `UnhealthyHostCount` metric increments.

## Demo Walkthrough

### Step 1 — Deploy the healthy baseline

Copy the example variables file and configure it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — set the scenario and your email, ensure the health-probe block is off:

```hcl
enabled_scenarios                = ["appgw-backend-unhealthy"]
alert_email                      = "you@example.com"
appgw_block_backend_health_probe = false
```

Deploy:

```bash
terraform init
terraform apply
```

After deploy, wait **~5–10 minutes** for the Application Gateway to provision, the backend VM to boot, and the health probe to run a few successful cycles.

To verify the baseline is healthy, go to **Azure Portal → Application Gateways → `amw-iidemo-appgw` → Backend health**. You should see the backend pool with **Status: Healthy**.

> **💡 Tip:** You can also verify the backend is serving traffic by curling the Application Gateway's public IP shown in the Terraform output or in **Azure Portal → Public IP addresses → `amw-iidemo-appgw-pip`**.

![App Gateway backend healthy](../../assets/screenshots/appgw-backend-unhealthy/01-appgw-backend-healthy.png)

### Step 2 — Trigger the incident

Set the block variable to `true`:

```hcl
appgw_block_backend_health_probe = true
```

Apply:

```bash
terraform apply
```

This adds an NSG inbound deny rule (`deny-inbound-http-from-appgw`, priority 200) on the backend subnet, blocking all TCP/80 traffic from the Application Gateway subnet (`10.50.0.0/24`). The health probe can no longer reach the backend VM.

![NSG deny rule applied](../../assets/screenshots/appgw-backend-unhealthy/02-nsg-deny-rule.png)

### Step 3 — Observe the failure

Within **~2–5 minutes**, the Application Gateway marks the backend as unhealthy after three consecutive probe failures:

![App Gateway backend unhealthy](../../assets/screenshots/appgw-backend-unhealthy/03-appgw-backend-unhealthy.png)

The `UnhealthyHostCount` metric rises above zero and the metric alert fires. You receive an email notification.

To view the alert details, either:
- Click the **View in Azure Monitor** link in the notification email, or
- Go to **Azure Portal → Monitor → Alerts**, filter by resource group `amw-iidemo-rg`, and click the fired alert

![Alert fired](../../assets/screenshots/appgw-backend-unhealthy/04-alert-fired.png)

The alert detail page shows severity, description, affected scope and timestamps:

![Alert detail](../../assets/screenshots/appgw-backend-unhealthy/05-alert-detail.png)

### Step 4 — Investigate with Issues & Investigations (preview)

From the fired alert detail page, click **Investigate (preview)** to open the Issues & Investigations blade:

![Investigate preview](../../assets/screenshots/appgw-backend-unhealthy/06-investigate-preview.png)

Drill into **Issues (preview)** to view the issue context, affected resources and correlated signals. The investigation correlates the unhealthy backend with recent NSG changes in the Activity Log, showing the blast radius — the frontend listener, routing rule and backend pool are all affected:

![Issue detail](../../assets/screenshots/appgw-backend-unhealthy/07-issue-detail.png)

### Step 5 — AI-assisted root-cause analysis

Use the context-specific Copilot chat in the Investigation/Issue view. Ask a question like:

> *"Why is the Application Gateway backend unhealthy and how can I fix it?"*

The Observability Agent analyses the configuration and activity signals, identifies the NSG deny rule as the root cause, and provides the exact remediation steps — typically an `az network nsg rule create` command to add a higher-priority allow rule:

![AI chat remediation suggestion](../../assets/screenshots/appgw-backend-unhealthy/08-ai-chat-remediation.png)

### Step 6 — Apply the fix (human in the loop)

Following the AI's recommendation, add an NSG allow rule with a higher priority (lower number) than the deny rule to restore health-probe traffic. Execute the remediation command in the Azure Portal Cloud Shell:

```bash
az network nsg rule create \
  --resource-group amw-iidemo-rg \
  --nsg-name amw-iidemo-appgw-nsg \
  --name allow-appgw-health-probe \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.50.0.0/24" \
  --destination-port-ranges 80
```

![NSG allow rule added](../../assets/screenshots/appgw-backend-unhealthy/09-nsg-allow-rule-added.png)

> **💡 Alternatively**, set `appgw_block_backend_health_probe = false` in `terraform.tfvars` and run `terraform apply` to remove the deny rule entirely.

### Step 7 — Confirm recovery

After **~2–5 minutes**, the Application Gateway health probe succeeds again and the backend is marked healthy:

![App Gateway backend recovered](../../assets/screenshots/appgw-backend-unhealthy/10-appgw-backend-recovered.png)

The metric alert auto-resolves:

![Alert resolved](../../assets/screenshots/appgw-backend-unhealthy/11-alert-resolved.png)

## Key takeaways

- **Issues & Investigations (preview)** provides contextual correlation of alerts, affected resources and activity signals in a single view.
- The **Observability Agent** correctly identifies the NSG deny rule blocking health-probe traffic as the root cause, and provides actionable remediation steps.
- The investigation correlates the unhealthy backend with the specific NSG change, showing the blast radius across the Application Gateway's frontend, routing and backend components.
- Remediation is **human-in-the-loop** — the AI advises, the operator approves and executes.
- The full cycle — detect → investigate → diagnose → fix → verify — is demonstrated end to end.

## Notes

- This scenario reuses the shared Log Analytics Workspace defined by `law_name` in root config.
- The backend VM uses a Python 3 HTTP server (no package installation needed) so cloud-init works without outbound internet access.
- The NSG deny rule priority is set to 200, allowing a higher-priority allow rule (e.g. priority 100) to be inserted for remediation without deleting the deny rule.
- Application Gateway v2 (`Standard_v2`) with autoscale 1–2 is used to keep costs minimal while supporting the `UnhealthyHostCount` metric.
- This scenario is infrastructure-only and does not require application code.
