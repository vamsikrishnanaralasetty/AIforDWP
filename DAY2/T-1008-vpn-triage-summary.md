# Triage Summary — T-1008

## Summary
VPN connects successfully but no internal resources are reachable following a Windows 11 upgrade.

## Impact
- Who: Single user (name, team, and role not provided: to-verify)
- How many: 1 confirmed; whether other users who upgraded are affected is unknown (to-verify)
- Business urgency: High — user cannot access internal systems or resources, blocking role-dependent work (to-verify)

## Known Facts
- VPN connection is established successfully
- No internal resources are reachable after connecting to VPN
- Issue began after a Windows 11 upgrade
- Ticket reference: T-1008

## Missing Information to Gather
- User name, team, and contact details (to-verify)
- VPN client name and version in use (to-verify)
- Device make, model, asset number, and Windows 11 build version (to-verify)
- Which internal resources are unreachable (intranet, shared drives, internal apps, DNS resolution) (to-verify)
- Whether the VPN worked correctly before the Windows 11 upgrade (to-verify)
- Whether DNS resolution is working correctly on the VPN connection (to-verify)
- Whether the Windows 11 upgrade included a network driver or adapter update (to-verify)
- Whether the VPN client was reinstalled or reconfigured after the upgrade (to-verify)
- Whether the user is connecting from home, office, or another network (to-verify)
- Whether other users on the same VPN are able to reach internal resources (to-verify)

## Likely Category
Remote Access / Networking — VPN Split-Tunnel or Routing Issue Post-Windows 11 Upgrade (to-verify; likely a network adapter driver change, routing table issue, or DNS configuration problem introduced by the upgrade)

## First Diagnostic Step
While connected to VPN, test basic internal network reachability (e.g., attempt to reach an internal resource by IP address as well as by name) to determine whether the issue is DNS resolution, routing, or a broader connectivity failure, and check whether the VPN adapter is correctly listed and active in network settings.
