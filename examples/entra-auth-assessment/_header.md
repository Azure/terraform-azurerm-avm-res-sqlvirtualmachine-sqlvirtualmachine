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

## Features Demonstrated

### Microsoft Entra Authentication
- Uses a user-assigned managed identity for Entra ID authentication
- Enables Windows authentication with Entra ID credentials
- Configured via `server_configurations_management_settings.azure_ad_authentication_settings`

### Azure Key Vault Integration
- Creates an Azure Key Vault with access policies for the managed identity
- Enables SQL Server credential for Key Vault access
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
