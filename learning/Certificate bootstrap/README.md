# Public DNS and TLS Runbook

This runbook documents the manual bootstrap process for a public custom domain
and a Let's Encrypt TLS certificate used by Azure Application Gateway.

> Do not commit certificates, PFX files, private keys, passwords, API tokens,
> email addresses, or real domain names to Git.

## Architecture and responsibility

```text
Cloudflare Registrar + DNS (DNS only)
    <YOUR_DOMAIN_NAME> → Application Gateway public IP
                                  │
                                  │ TLS certificate from Key Vault
                                  ▼
                         Application Gateway + WAF
                                  │
                                  ▼
                       App Service private endpoint
```

Cloudflare is only the domain registrar and public DNS host in this design.
Application Gateway is the public web entry point, Azure WAF is the WAF, and
Key Vault stores the TLS certificate.

## Prerequisites

- A registered domain managed in Cloudflare.
- A static Application Gateway public IP address.
- Azure Key Vault configured with RBAC authorization.
- Application Gateway and Key Vault private networking already configured.


## 1. Create the public DNS A record

In Cloudflare, open:

```text
Websites → <YOUR_DOMAIN_NAME> → DNS → Records → Add record
```

Create this record:

```text
Type:           A
Name:           @
IPv4 address:   <PUBLIC_IP>
Proxy status:   DNS only (grey cloud)
TTL:            Auto
```

`@` means the root domain itself. For example, in the `example.com` zone,
`@` means `example.com`.

Keep the cloud **grey**. Orange-cloud proxy mode would put Cloudflare CDN/WAF
in front of Azure and would prevent this project from demonstrating Azure
Application Gateway, Azure WAF, and Azure TLS termination directly.

Verify resolution:

```bash
nslookup <YOUR_DOMAIN_NAME>
```

The answer must contain `<PUBLIC_IP>`. Then verify that the current HTTP
listener reaches the application:

```text
http://<YOUR_DOMAIN_NAME>
```

## 2. Install Certbot

Certbot is a client for Let's Encrypt, the certificate authority that issues
free, domain-validated TLS certificates.

```bash
brew install certbot
```

## 3. Request a Let's Encrypt certificate with DNS validation

Use DNS-01 validation. It proves ownership by creating a temporary public DNS
TXT record. It does not require changing Application Gateway routing.

```bash
certbot certonly \
  --manual \
  --preferred-challenges dns \
  --email <YOUR_EMAIL> \
  --agree-tos \
  --no-eff-email \
  -d <YOUR_DOMAIN_NAME>
```

Certbot pauses and displays a record similar to:

```text
Name:  _acme-challenge.<YOUR_DOMAIN_NAME>
Value: <LONG_ONE_TIME_VALIDATION_VALUE>
```

Do not press Enter in Certbot yet.

## 4. Create the ACME TXT record in Cloudflare

In Cloudflare DNS, add:

```text
Type:    TXT
Name:    _acme-challenge
Content: <LONG_ONE_TIME_VALIDATION_VALUE>
TTL:     Auto
```

Cloudflare automatically appends the domain name, so enter only
`_acme-challenge` in the **Name** field.

Verify that public DNS returns the value:

```bash
nslookup -type=TXT _acme-challenge.<YOUR_DOMAIN_NAME>
```

When the value matches exactly, return to Certbot and press Enter. A successful
request creates a certificate directory similar to:

```text
/etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/
```

The TXT record can be removed after successful issuance. A future manual
renewal creates a new one-time TXT value.

## 5. Understand Certbot output files

Certbot creates these related files:

| File | Purpose | Secret? |
|---|---|---|
| `cert.pem` | Public certificate for the domain | No |
| `chain.pem` | Let's Encrypt intermediate certificates | No |
| `fullchain.pem` | `cert.pem` plus `chain.pem` | No |
| `privkey.pem` | Private key paired with the certificate | **Yes** |

The browser receives the public certificate and intermediate chain. It never
receives the private key. The server uses the private key to prove that it owns
the certificate during the TLS handshake.

Safely inspect the public certificate metadata:

```bash
openssl x509 \
  -in /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/fullchain.pem \
  -noout \
  -subject \
  -issuer \
  -dates \
  -ext subjectAltName
```

## 6. Create an Azure-compatible PFX package

Azure Key Vault and Application Gateway use a PFX package containing the
domain certificate, trust chain, and private key.

```bash
openssl pkcs12 -export \
  -out ~/Desktop/<YOUR_DOMAIN_NAME>.pfx \
  -inkey /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/privkey.pem \
  -in /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/cert.pem \
  -certfile /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/chain.pem \
  -name <YOUR_DOMAIN_NAME>
```

Enter and securely store the export password when OpenSSL requests it. The PFX
contains the private key; do not commit or share it.

If Azure cannot import a PFX produced by a newer OpenSSL version, recreate it
with Azure-compatible legacy encryption:

```bash
openssl pkcs12 -export -legacy \
  -out ~/Desktop/<YOUR_DOMAIN_NAME>.pfx \
  -inkey /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/privkey.pem \
  -in /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/cert.pem \
  -certfile /etc/letsencrypt/live/<YOUR_DOMAIN_NAME>/chain.pem \
  -name <YOUR_DOMAIN_NAME>
```

Validate the PFX before importing it:

```bash
openssl pkcs12 -in ~/Desktop/<YOUR_DOMAIN_NAME>.pfx -info -noout
```

Expected signs of a valid package include `Certificate bag` entries and one
`Shrouded Keybag` entry.

If the command returns `Permission denied`, do not make the file public. Make
your local user the owner and restrict it to that user:

```bash
sudo chown "$USER":"$(id -gn)" ~/Desktop/<YOUR_DOMAIN_NAME>.pfx
chmod 600 ~/Desktop/<YOUR_DOMAIN_NAME>.pfx
```

## 7. Import the certificate into Key Vault

If Key Vault public network access is disabled, temporarily allow access from
only the current administrator public IP:

```text
Key Vault → Networking
→ Enable public access from selected networks and IP addresses
→ Add current client IP
→ Apply
```

Do not enable unrestricted public access from all networks.

Import the PFX through the Portal:

```text
Key Vault → Certificates → Generate/Import
```

Use:

```text
Method:           Import
Certificate name: <TLS_CERTIFICATE_NAME>
File:             ~/Desktop/<YOUR_DOMAIN_NAME>.pfx
Password:         <PFX_EXPORT_PASSWORD>
```

Example safe certificate name:

```text
tls-example-com
```

Import it as a **certificate**, not as an ordinary secret. Key Vault creates a
certificate object and a backing secret with the same name. Application Gateway
will retrieve the backing secret.

Verify that the certificate is enabled and that its subject, issuer, and expiry
date are correct.

## 8. Give Application Gateway access to Key Vault

Application Gateway requires a **user-assigned managed identity** to retrieve
its Key Vault certificate.

Create it manually:

```text
Managed Identities → Create
Name:            <GATEWAY_IDENTITY_NAME>
Region:          same region as Application Gateway
Isolation scope: Regional
Resource:        None / empty
```

Then grant only the required Key Vault role:

```text
Key Vault → Access control (IAM) → Add role assignment
Role: Key Vault Secrets User
Member type: Managed identity
Member: <GATEWAY_IDENTITY_NAME>
```

Attach it to Application Gateway:

```bash
az network application-gateway identity assign \
  --resource-group <RESOURCE_GROUP> \
  --gateway-name <APPLICATION_GATEWAY_NAME> \
  --identity "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<GATEWAY_IDENTITY_NAME>"
```

Verify the attachment:

```bash
az network application-gateway identity show \
  --resource-group <RESOURCE_GROUP> \
  --gateway-name <APPLICATION_GATEWAY_NAME> \
  --output json
```

## 9. Terraform ownership

Terraform can manage all of the following:

```text
User-assigned identity
Key Vault Secrets User role assignment
Identity attached to Application Gateway
HTTPS listener and HTTP-to-HTTPS redirect
```

If the identity and role were created manually, import them before running
`terraform apply`. Obtain their resource IDs from Azure CLI or Azure Resource
Graph Explorer, then use the appropriate Terraform import addresses.

Do not store the PFX file or its password in Terraform source code, `.tfvars`,
or Git. The certificate is an external bootstrap dependency.

## 10. Deployment order from zero

The HTTPS listener must not be created until the certificate exists in Key
Vault. A clean deployment has three stages:

```text
1. Foundation Terraform
   VNet, Key Vault, private endpoints, Gateway identity, RBAC, Gateway.

2. Certificate bootstrap
   Issue or renew Let's Encrypt certificate and import the PFX into Key Vault.

3. HTTPS Terraform
   Create HTTPS listener, create HTTP-to-HTTPS redirect, validate HTTPS, and
   then disable App Service public access.
```

In a future Azure DevOps pipeline, stage 2 should be automated with secure
certificate handling. Until then, this runbook is the manual bootstrap process.
