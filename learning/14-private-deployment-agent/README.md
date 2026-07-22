# Module 14 — Private Azure DevOps Deployment Agent

## Goal

Create a private deployment path so Azure DevOps can deploy application content without temporarily enabling public access to Key Vault, Storage, SQL Database, or App Service.

## Learning stages

1. **Deployment network** — Create a dedicated deployment VNet and subnet.
2. **VNet peering** — Peer the deployment VNet with the application VNet in both directions.
3. **Private connectivity** — Link private DNS zones to the deployment VNet and add the necessary NSG rules.
4. **Deployment VM** — Create a VM in the deployment subnet and verify that it can reach private services.
5. **Azure DevOps agent** — Install and register a self-hosted Azure DevOps agent on the VM.
6. **Private App Service deployment** — Create the App Service SCM private endpoint so the agent can deploy Flask code privately.

## Why this order?

The VM is created after the network path is ready. This means its first connectivity tests already use the intended private route:

```text
Deployment VM
  -> VNet peering
  -> private DNS resolution
  -> private endpoints
  -> Key Vault / Storage / SQL / App Service SCM
```

## Later automation

Terraform will manage the Azure infrastructure. Azure DevOps pipelines will deploy the certificate, Flask application, Blob content, SQL migrations, and Key Vault secrets.
