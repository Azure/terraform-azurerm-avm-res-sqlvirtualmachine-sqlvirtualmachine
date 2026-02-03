# Microsoft Entra Authentication, Key Vault Integration and SQL Assessment Example

This example demonstrates how to configure:
1. **Microsoft Entra authentication** (formerly Azure AD authentication) - Available from SQL Server 2022
2. **Azure Key Vault integration** - Enables SQL Server to access keys and secrets from Azure Key Vault
3. **SQL best practices assessment** - Automated assessment to identify issues and recommendations

## Prerequisites

- SQL Server 2022 or later is required for Microsoft Entra authentication
- A user-assigned managed identity with appropriate permissions to query Microsoft Graph API
- Azure Key Vault with appropriate access policies for the managed identity
- The VM must have access to Azure services

## Important Limitation

> **Note**: Azure AD/Entra authentication **cannot be enabled during initial SQL VM provisioning**.
> It must be enabled in a second apply after the SQL VM is created. This is a limitation of the Azure API.
>
> To enable Entra authentication:
> 1. First, apply without `azure_ad_authentication_settings`
> 2. Then, uncomment the `azure_ad_authentication_settings` block and apply again

## Features Demonstrated

### Microsoft Entra VM Sign-in (AADLoginForWindows Extension)
- Installs the `AADLoginForWindows` VM extension to enable Entra ID sign-in to the VM
- Allows users to RDP to the VM using their Entra ID credentials
- Requires SystemAssigned managed identity on the VM
- Reference: [Microsoft Entra sign-in for Windows VMs](https://learn.microsoft.com/en-us/entra/identity/devices/howto-vm-sign-in-azure-ad-windows)

### Microsoft Entra SQL Server Authentication
- Uses a user-assigned managed identity for SQL Server Entra ID authentication
- Enables SQL connections with Entra ID credentials
- Configured via `server_configurations_management_settings.azure_ad_authentication_settings`
- **Must be enabled after initial provisioning** (see limitation above)

### Azure Key Vault Integration
- Creates an Azure Key Vault with access policies for the managed identity and service principal
- Creates an Azure AD application and service principal for SQL Server to access Key Vault
- Service principal password is write-only and not stored in Terraform state
- Configured via `key_vault_credential_settings`
- Supports TDE (Transparent Data Encryption) with customer-managed keys

### SQL Best Practices Assessment
- Enables automated SQL Assessment scans
- Configures weekly scheduled assessments on Sundays at 2:00 AM
- Runs an immediate assessment on deployment
- Configured via `assessment_settings`

### Additional Security Features
- Least privilege mode enabled for SQL IaaS Agent
- Automatic upgrade enabled for SQL IaaS Agent
- Private connectivity configured (no public endpoint)
