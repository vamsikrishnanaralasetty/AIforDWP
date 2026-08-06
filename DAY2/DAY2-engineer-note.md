# VPN Issue – Engineer Note (T-1008)

## Root Cause
Win11 feature upgrade removed the legacy VPN client. Intune re-deployment of the replacement client silently failed because the detection rule was scoped to the old client's install path — with that path gone post-upgrade, the rule returned "not applicable" rather than "not detected," so the deployment never triggered.

## Action Taken
1. Manually cleared stale registry entries under `HKLM\SOFTWARE\<vendor>` (residual keys left by the legacy uninstall were confusing the detection rule).
2. Force-triggered Intune sync (`IME` → **Sync** or `dsregcmd /refreshprt` + Company Portal sync).
3. New VPN client deployed successfully via Intune within ~10 min of sync.
4. Split-tunnel config profile applied as part of the same deployment baseline.

## Verification
Confirmed connectivity to all internal subnets post-deployment; no data loss; user session restored.

## Preventive Action Required
- Update the Intune detection rule for the VPN client app to check a version-agnostic indicator (e.g., service name or a registry key written by the *new* installer, not the legacy path).
- Add a post-upgrade compliance check script to the Win11 upgrade task sequence that validates VPN client presence before the device is marked compliant — this will catch the gap before a user reports it.
