# Scenario: App Gateway Backend Unhealthy

Status: **Planned** (documentation scaffolded; Terraform resources not yet added in this repository).

## Goal

Demonstrate a richer infrastructure incident where ingress remains reachable but backend health fails.

## Planned Terraform selector

```hcl
enabled_scenarios = ["appgw-backend-unhealthy"]
```

## Planned design

- Deploy Application Gateway with backend pool and health probe
- Alert when `UnhealthyHostCount > 0`
- Route alert to Action Group

## Planned trigger options

- Break probe path or port
- Introduce NSG rule that blocks backend health probe traffic

## Planned investigate story

- Correlate unhealthy backend with recent config/network changes
- Show blast radius and affected frontend/backend path

## Planned mitigation automation

- Revert to known-good probe/NSG configuration
- Optional traffic shift to healthy standby backend
