# Exercise 05 - Azure Key Vault

## Objective

Deploy an Azure Key Vault using Terraform and manually configure the application to authenticate against it using Microsoft Entra ID.

At the end of this exercise the application should be able to read a secret stored inside Azure Key Vault.

---

# Terraform Deployment

Deploy the infrastructure.

```bash
terraform init

terraform plan

terraform apply
```

Terraform creates:

- Resource Group
- App Service Plan
- App Service
- Storage Account
- SQL Server
- SQL Database
- Azure Key Vault

---

# Retrieve Terraform Outputs

The following commands provide information required during the manual configuration.

```bash
terraform output key_vault_name
```

```bash
terraform output key_vault_uri
```

```bash
terraform output key_vault_id
```

---

# Manual Configuration

## 1. Create a Secret

Azure Portal

```
Key Vault

↓

Secrets

↓

Generate / Import
```

Create:

| Name | Value |
|------|-------|
| `welcome-message` | `Welcome David from Azure Key Vault!` |

---

## 2. Register an Application

Azure Portal

```
Microsoft Entra ID

↓

App registrations

↓

New registration
```

Example name:

```
hello-world-keyvault-demo
```

After creation, copy:

- Application (Client) ID
- Directory (Tenant) ID

---

## 3. Create a Client Secret

Inside the App Registration:

```
Certificates & secrets

↓

New client secret
```

Copy the **Value** immediately.

> **Important:** Azure displays the value only once.

---

## 4. Grant the Application Access to Key Vault

Azure Portal

```
Key Vault

↓

Access Control (IAM)

↓

Add Role Assignment
```

Role:

```
Key Vault Secrets User
```

Assign access to:

```
User, group or service principal
```

Select:

```
hello-world-keyvault-demo
```

Save.

Wait a few minutes for RBAC permissions to propagate.

---

## 5. Configure the Application

Update the `.env` file.

```env
AZURE_TENANT_ID=<Tenant ID>

AZURE_CLIENT_ID=<Application Client ID>

AZURE_CLIENT_SECRET=<Client Secret Value>

KEY_VAULT_URL=<Vault URI>
```

Example:

```env
KEY_VAULT_URL=https://kv-dev-helloworld.vault.azure.net/
```

---

## 6. Install Dependencies

```bash
pip install azure-keyvault-secrets

pip install azure-identity
```

Update requirements.

```bash
pip freeze > requirements.txt
```

---

## 7. Run the Application

```bash
python app.py
```

Open:

```
http://127.0.0.1:5000/key
```

Expected output:

```
Azure Key Vault

Welcome David from Azure Key Vault!
```

---

# Validation Checklist

- [ ] Terraform deployed Key Vault.
- [ ] Secret created.
- [ ] Microsoft Entra Application created.
- [ ] Client Secret created.
- [ ] Application granted **Key Vault Secrets User** role.
- [ ] `.env` updated.
- [ ] Flask application successfully reads the secret.
- [ ] `/key` page displays the welcome message.

---

# Next Exercise

**Exercise 06 - Managed Identity**

Current authentication:

```
Flask
    │
    ▼
Client ID
Client Secret
Tenant ID
    │
    ▼
Microsoft Entra ID
    │
    ▼
Azure Key Vault
```

Next exercise:

```
Flask
    │
    ▼
Managed Identity
    │
    ▼
Microsoft Entra ID
    │
    ▼
Azure Key Vault
```

The following variables will be removed from `.env`:

- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`

The application will authenticate to Azure automatically using its Managed Identity.
