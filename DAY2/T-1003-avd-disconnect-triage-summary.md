# Triage Summary — T-1003

## Summary
User's Azure Virtual Desktop session disconnects after approximately 10 minutes then reconnects automatically.

## Impact
- Who: Single user (name/team/role not provided: to-verify)
- How many: 1 confirmed; whether other AVD users are affected is unknown (to-verify)
- Business urgency: Medium-High — repeated disconnections disrupt active work and may cause data loss or session state issues; full business impact not stated (to-verify)

## Known Facts
- User is connecting via Azure Virtual Desktop (AVD)
- Sessions disconnect after approximately 10 minutes
- Session reconnects after the disconnection
- Ticket reference: T-1003

## Missing Information to Gather
- User name, team, and contact details (to-verify)
- Device type and OS being used to connect (DWP laptop, personal device, thin client) (to-verify)
- Network connection type (home Wi-Fi, corporate LAN, mobile hotspot, etc.) (to-verify)
- Whether the issue happens consistently every ~10 minutes or is intermittent (to-verify)
- Whether other users on the same AVD host pool or same network are experiencing the same behaviour (to-verify)
- Any error message or code displayed at the point of disconnection (to-verify)
- AVD client name and version in use (to-verify)
- Whether the ~10-minute timing aligns with any known session/idle timeout policy (to-verify)
- When the issue started and whether anything changed beforehand (updates, network change, policy change) (to-verify)
- Whether the reconnection is automatic or requires manual action (to-verify)

## Likely Category
Remote Access / AVD — Session Timeout or Network Stability Issue (to-verify; could be idle/session timeout policy, network instability, AVD host pool configuration, or client-side keep-alive setting)

## First Diagnostic Step
Check whether the ~10-minute disconnect aligns with a configured session idle or disconnect timeout policy on the AVD host pool, and establish whether the issue is isolated to this user or affects multiple users on the same pool or network.
