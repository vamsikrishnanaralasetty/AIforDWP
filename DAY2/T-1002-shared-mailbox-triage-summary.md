# Triage Summary — T-1002

## Summary
Finance user is unable to open a shared mailbox following a migration.

## Impact
- Who: One Finance team user (name not provided: to-verify)
- How many: 1 confirmed; whether other Finance users or the full team are affected is unknown (to-verify)
- Business urgency: High — Finance teams typically have time-sensitive mailbox dependencies; full business impact not stated (to-verify)

## Known Facts
- User is in the Finance team
- User cannot open a shared mailbox
- A migration has recently taken place
- Ticket reference: T-1002

## Missing Information to Gather
- User name and contact details (to-verify)
- Name/address of the shared mailbox affected (to-verify)
- Type of migration performed (Exchange on-premises to Exchange Online, tenant-to-tenant, mailbox move, etc.) (to-verify)
- Date the migration completed (to-verify)
- Whether the user had access to the shared mailbox before the migration (to-verify)
- Email client in use (Outlook desktop, Outlook Web App, Outlook mobile) and version (to-verify)
- Exact error message or behaviour seen when attempting to open the mailbox (to-verify)
- Whether other users who share access to the same mailbox are also affected (to-verify)
- Whether the user's own primary mailbox is working correctly post-migration (to-verify)
- Whether permissions on the shared mailbox were verified/re-applied after migration (to-verify)

## Likely Category
Email / Messaging — Shared Mailbox Access Failure Post-Migration (to-verify; could be permissions not migrated, Outlook profile stale, Autodiscover not updated, or licensing issue)

## First Diagnostic Step
Confirm whether the shared mailbox and the user's account exist and are visible in the admin/directory tool in use, and verify that the user's mailbox access permissions to the shared mailbox are present and correctly assigned post-migration.
