# Triage Summary — T-1007

## Summary
OneDrive has been stuck on "processing changes" since a migration and files are missing locally.

## Impact
- Who: Single user (name, team, and role not provided: to-verify)
- How many: 1 confirmed; whether other migrated users are affected is unknown (to-verify)
- Business urgency: High — locally missing files may block access to working documents; data loss cannot be ruled out until investigated (to-verify)

## Known Facts
- OneDrive has been stuck in a "processing changes" state
- Files are missing locally on the device
- The issue began following a migration
- Ticket reference: T-1007

## Missing Information to Gather
- User name, team, and contact details (to-verify)
- Type of migration performed (tenant-to-tenant, on-premises to SharePoint Online, OneDrive re-provisioning, etc.) (to-verify)
- Date the migration completed (to-verify)
- Whether the files are visible in OneDrive via a web browser (to-verify)
- Number and type of files reported missing (to-verify)
- OneDrive client version installed on the device (to-verify)
- Whether the OneDrive account shown in the client matches the post-migration account (to-verify)
- Whether the device has been restarted and OneDrive re-signed in since the migration (to-verify)
- Available local disk space on the device (to-verify)
- Whether other users migrated at the same time are experiencing the same issue (to-verify)

## Likely Category
Cloud Storage / File Sync — OneDrive Sync Failure Post-Migration (to-verify; likely account mismatch, sync state corruption, or files not yet fully migrated to the new tenant/location)

## First Diagnostic Step
Check whether the missing files are accessible via OneDrive on the web using the user's post-migration account credentials, to determine whether the files exist in the cloud and the issue is sync-only, or whether the files were not successfully migrated.
