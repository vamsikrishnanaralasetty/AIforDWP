# AVD End-to-End Provisioning — POOL-FIN-01
**Date:** 2026-08-13  
**Engineer:** traininguser29@zippyops.in  
**Subscription:** 59b76132-b5e4-47a8-806b-9e477da77802 (labs29)  
**Tenant:** zippyops.in (fa8443c6-5a39-4df5-a018-9c876455adf9)  
**Resource group:** dwp-lab-rg — Central US  

---

## Environment summary

| Parameter | Value |
|---|---|
| Host pool | POOL-FIN-01 |
| Type | Pooled, BreadthFirst, max 5 sessions |
| Application group | POOL-FIN-01-DAG (Desktop) |
| Workspace | FinBridge-Workspace |
| Session host | fin-sh-01 |
| Image | win11-24h2-avd (26100.9168.260809) |
| VM size | Standard_B2ms |
| Security | TrustedLaunch — Secure Boot + vTPM |
| Identity | Entra ID joined only (no on-premises AD) |
| Network | dwp-p27-winVNET / dwp-p27-winSubnet (10.0.0.0/24) |
| Private IP | 10.0.0.5 (no public IP) |
| AVD agent | 1.0.15008.300 |
| End-user account | p27@zippyops.in |

---

## Pre-flight checks

### 1. Verify Azure CLI authentication

```powershell
az account show --output json
```

Confirmed: signed in as `traininguser29@zippyops.in`, subscription `labs29` active.

### 2. Confirm role on subscription

```powershell
az role assignment list --assignee traininguser29@zippyops.in `
  --subscription 59b76132-b5e4-47a8-806b-9e477da77802 `
  --output table
```

Result: **Owner** at subscription scope — role assignments permitted.

### 3. Confirm resource group

```powershell
az group show --name dwp-lab-rg --output json
```

Resource group `dwp-lab-rg` exists in `centralus`, `provisioningState: Succeeded`.

### 4. Register AVD resource provider

```powershell
az provider register --namespace Microsoft.DesktopVirtualization --wait
az provider show --namespace Microsoft.DesktopVirtualization `
  --query "registrationState" -o tsv
```

Result: `Registered`

### 5. Install desktopvirtualization CLI extension

```powershell
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true
az extension add --name desktopvirtualization
```

Extension v1.0.0 confirmed installed.

---

## Step 1 — Create host pool

```powershell
az desktopvirtualization hostpool create `
  --name POOL-FIN-01 `
  --resource-group dwp-lab-rg `
  --location centralus `
  --host-pool-type Pooled `
  --load-balancer-type BreadthFirst `
  --max-session-limit 5 `
  --preferred-app-group-type Desktop `
  --output json
```

**Verified output:**
- `hostPoolType`: Pooled
- `loadBalancerType`: BreadthFirst
- `maxSessionLimit`: 5
- `id`: `.../hostpools/POOL-FIN-01`

---

## Step 2 — Create Desktop application group

```powershell
az desktopvirtualization applicationgroup create `
  --name "POOL-FIN-01-DAG" `
  --resource-group dwp-lab-rg `
  --location centralus `
  --application-group-type Desktop `
  --host-pool-arm-path "/subscriptions/59b76132-b5e4-47a8-806b-9e477da77802/resourcegroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostpools/POOL-FIN-01" `
  --output json
```

**Verified output:**
- `applicationGroupType`: Desktop
- `hostPoolArmPath`: links to POOL-FIN-01

---

## Step 3 — Create workspace and register application group

```powershell
az desktopvirtualization workspace create `
  --name "FinBridge-Workspace" `
  --resource-group dwp-lab-rg `
  --location centralus `
  --application-group-references "/subscriptions/59b76132-b5e4-47a8-806b-9e477da77802/resourcegroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG" `
  --output json
```

**Verified output:**
- `applicationGroupReferences` array contains `POOL-FIN-01-DAG`

---

## Step 4 — Generate host pool registration token

Token used during session host DSC registration. Valid for a fixed window (set expiry to several hours ahead of provisioning time).

```powershell
az desktopvirtualization hostpool update `
  --name POOL-FIN-01 `
  --resource-group dwp-lab-rg `
  --registration-info "expiration-time=<YYYY-MM-DDTHH:MM:SSZ>" "registration-token-operation=Update" `
  --query "registrationInfo.token" `
  --output tsv
```

Store the returned JWT in a variable for use in the DSC extension settings:

```powershell
$REG_TOKEN = "<token output from above>"
```

> **Note:** Tokens expire. Generate immediately before VM creation/extension install. Do not reuse across separate provisioning runs.

---

## Step 5 — Create session host VM

### Network
Existing VNet reused: `dwp-p27-winVNET` / subnet `dwp-p27-winSubnet` (10.0.0.0/24).

### VM creation

```powershell
az vm create `
  --name fin-sh-01 `
  --resource-group dwp-lab-rg `
  --location centralus `
  --image "MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest" `
  --size Standard_B2ms `
  --vnet-name dwp-p27-winVNET `
  --subnet dwp-p27-winSubnet `
  --public-ip-address '""' `
  --security-type TrustedLaunch `
  --enable-secure-boot true `
  --enable-vtpm true `
  --admin-username avdadmin `
  --admin-password "<strong-password>" `
  --license-type Windows_Client `
  --output json
```

> **Security note:** No public IP is assigned. All user access routes through the AVD gateway. Admin password is set for break-glass local access only.

### Verify VM security configuration

```powershell
az vm show --name fin-sh-01 --resource-group dwp-lab-rg `
  --query "{securityType:securityProfile.securityType, secureBoot:securityProfile.uefiSettings.secureBootEnabled, vTPM:securityProfile.uefiSettings.vTpmEnabled, size:hardwareProfile.vmSize, image:storageProfile.imageReference}" `
  --output json
```

**Expected output:**
```json
{
  "securityType": "TrustedLaunch",
  "secureBoot": true,
  "vTPM": true,
  "size": "Standard_B2ms",
  "image": { "sku": "win11-24h2-avd", "exactVersion": "26100.9168.260809" }
}
```

---

## Step 6 — Assign system-managed identity to VM

Required for the Entra ID join extension to discover the tenant. Without this, `AADLoginForWindows` fails with `0x801c002d` (tenant ID query failure).

```powershell
az vm identity assign `
  --name fin-sh-01 `
  --resource-group dwp-lab-rg `
  --identities "[system]" `
  --output json
```

Confirm `systemAssignedIdentity` GUID is returned before proceeding.

---

## Step 7 — Install AVD DSC extension (agent registration + Entra ID join flag)

Prepare the settings file to avoid PowerShell JSON quoting issues:

```powershell
$settings = ConvertTo-Json -Depth 5 @{
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip"
    configurationFunction = "Configuration.ps1\AddSessionHost"
    properties = @{
        hostPoolName                           = "POOL-FIN-01"
        registrationInfoToken                  = $REG_TOKEN
        aadJoin                                = $true
        mdmId                                  = ""
        sessionHostConfigurationLastUpdateTime = ""
        useAgentDownloadEndpoint               = $true
    }
}
Set-Content -Path "$env:TEMP\avd-dsc-settings.json" -Value $settings -Encoding utf8
```

Install the extension:

```powershell
az vm extension set `
  --name DSC `
  --publisher Microsoft.Powershell `
  --version 2.73 `
  --vm-name fin-sh-01 `
  --resource-group dwp-lab-rg `
  --settings "$env:TEMP\avd-dsc-settings.json" `
  --output json
```

**Expected:** `provisioningState: Succeeded`

> This extension downloads and installs the AVD agent and bootloader, then registers the VM with POOL-FIN-01 using the token. `aadJoin: true` instructs the agent to skip legacy AD domain join.

---

## Step 8 — Entra ID join (AADLoginForWindows extension)

Prepare settings file:

```powershell
$aadSettings = '{"mdmId":""}' | ConvertFrom-Json | ConvertTo-Json
Set-Content -Path "$env:TEMP\aad-settings.json" -Value $aadSettings -Encoding utf8
```

Install the extension:

```powershell
az vm extension set `
  --name AADLoginForWindows `
  --publisher Microsoft.Azure.ActiveDirectory `
  --vm-name fin-sh-01 `
  --resource-group dwp-lab-rg `
  --settings "$env:TEMP\aad-settings.json" `
  --output json
```

**Expected:** `provisioningState: Succeeded`

> `mdmId` is left empty — no Intune/MDM enrollment. For Intune-managed devices use `mdmId: 0000000a-0000-0000-c000-000000000000`.

### Troubleshooting note — error 0x801c002d
If this extension fails with `DsrCmdAzureHelper::GetTenantId failed 0x801c002d`, the VM is missing its system-assigned managed identity. Complete Step 6 first, then retry. The managed identity gives the extension the Azure credential context needed to locate the Entra ID tenant endpoint.

---

## Step 9 — Verify session host status

```powershell
az rest --method GET `
  --url "https://management.azure.com/subscriptions/59b76132-b5e4-47a8-806b-9e477da77802/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts/fin-sh-01?api-version=2022-09-09" `
  --query "{status:properties.status, agent:properties.agentVersion, heartbeat:properties.lastHeartBeat, checks:properties.sessionHostHealthCheckResults[].{name:healthCheckName, result:healthCheckResult}}" `
  --output json
```

**Expected status:** `Available`

All 7 health checks must pass:

| Health check | Expected result |
|---|---|
| DomainJoinedCheck | HealthCheckSucceeded |
| DomainTrustCheck | HealthCheckSucceeded |
| SxSStackListenerCheck | HealthCheckSucceeded |
| MetaDataServiceCheck | HealthCheckSucceeded |
| AppAttachHealthCheck | HealthCheckSucceeded |
| TURNRelayAccessHealthCheck | HealthCheckSucceeded |
| AADJoinedHealthCheck | HealthCheckSucceeded |

---

## Step 10 — Assign roles to end user (p27@zippyops.in)

### Get user object ID

```powershell
az ad user show --id p27@zippyops.in --query id --output tsv
# Returns: d8fe2571-4ff9-4ecb-b70d-c39b076b16a9
```

### Role 1 — Virtual Machine User Login (direct RDP to VM)

```powershell
az role assignment create `
  --assignee d8fe2571-4ff9-4ecb-b70d-c39b076b16a9 `
  --role "Virtual Machine User Login" `
  --scope "/subscriptions/59b76132-b5e4-47a8-806b-9e477da77802/resourceGroups/dwp-lab-rg/providers/Microsoft.Compute/virtualMachines/fin-sh-01" `
  --output json
```

### Role 2 — Desktop Virtualization User (AVD client access)

```powershell
az role assignment create `
  --assignee d8fe2571-4ff9-4ecb-b70d-c39b076b16a9 `
  --role "Desktop Virtualization User" `
  --scope "/subscriptions/59b76132-b5e4-47a8-806b-9e477da77802/resourcegroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG" `
  --output json
```

| Role | Scope | Grants |
|---|---|---|
| Virtual Machine User Login | fin-sh-01 VM | Direct RDP to the Entra ID joined VM |
| Desktop Virtualization User | POOL-FIN-01-DAG app group | Connect via AVD web/Windows client to the published desktop |

---

## Final state confirmation

```powershell
az rest --method GET `
  --url "https://management.azure.com/subscriptions/59b76132-b5e4-47a8-806b-9e477da77802/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts/fin-sh-01?api-version=2022-09-09" `
  --query "{name:name, status:properties.status, agent:properties.agentVersion, os:properties.osVersion, sessions:properties.sessions, heartbeat:properties.lastHeartBeat}" `
  --output json
```

**Confirmed output:**
```json
{
  "name": "POOL-FIN-01/fin-sh-01",
  "status": "Available",
  "agent": "1.0.15008.300",
  "os": "10.0.26100.9168",
  "sessions": 0,
  "heartbeat": "2026-08-13T06:29:53.65Z"
}
```

---

## User connection

End users connect via:  
`https://windows.cloud.microsoft/webclient/avd/`

Sign in with `p27@zippyops.in`. The **FinBridge-Workspace** feed loads and presents the **Session Desktop** resource. Clicking it routes through the AVD broker to `fin-sh-01`.

> **Pre-requisite for first sign-in:** A tenant Global Administrator or User Administrator must set the initial password for `p27@zippyops.in` via the Entra admin centre (`https://entra.microsoft.com`) or via:
> ```powershell
> az ad user update --id p27@zippyops.in --password "<TempPassword>" --force-change-password-next-sign-in true
> ```
> The subscription Owner role does not include Entra ID user management permissions.

---

## Key design decisions

| Decision | Rationale |
|---|---|
| No public IP on session host | All user traffic routes through the AVD gateway; no direct internet exposure |
| Entra ID join only (no AD) | Lab environment has no on-premises domain; Entra ID join is the cloud-native approach |
| System-assigned managed identity | Required for AADLoginForWindows extension to resolve the tenant endpoint (0x801c002d fix) |
| TrustedLaunch + Secure Boot + vTPM | Meets Windows 11 hardware security requirements; protects against boot-level attacks |
| BreadthFirst load balancing | Spreads sessions across all available hosts before filling any single host — appropriate for pooled desktops |
| win11-24h2-avd image | Latest AVD-optimised multi-session image; includes Teams optimisation and AVD-specific tuning |
| DSC extension before AADLoginForWindows | AVD agent must be installed first so the agent knows it is an Entra ID joined host (`aadJoin: true`) |
