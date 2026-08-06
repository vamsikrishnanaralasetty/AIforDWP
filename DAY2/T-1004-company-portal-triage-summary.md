# Triage Summary — T-1004

## Summary
User is unable to install a company application from Company Portal; installation fails with error 0x87D1041C.

## Impact
- Who: Single user (name, team, and role not provided: to-verify)
- How many: 1 confirmed; whether other users are seeing the same failure is unknown (to-verify)
- Business urgency: Not stated; depends on whether the app is required for the user's role (to-verify)

## Known Facts
- User is attempting to install an application via Company Portal
- Installation fails with error code 0x87D1041C (as reported in the ticket)
- Ticket reference: T-1004

## Missing Information to Gather
- User name, team, and contact details (to-verify)
- Name of the application that failed to install (to-verify)
- Device make, model, asset number, and OS build version (to-verify)
- Whether the device is Intune-enrolled and compliant (to-verify)
- Whether the user has attempted to install the app more than once (to-verify)
- Whether other apps install successfully from Company Portal on the same device (to-verify)
- Whether the device has sufficient disk space for the installation (to-verify)
- Whether the device is on the corporate network, VPN, or home/public network at time of failure (to-verify)
- Whether any other users are reporting the same error for the same app (to-verify)
- Date and time of the failed installation attempt (to-verify)

## Likely Category
Endpoint Management / Software Deployment — Company Portal / Intune App Installation Failure (to-verify; the error code is present in the ticket but its root cause — such as device compliance, sync issue, or app assignment — requires investigation to confirm)

## First Diagnostic Step
Check the device's Intune compliance and sync status in the device management portal, and confirm the application is correctly assigned to the user or device in the app deployment configuration.
