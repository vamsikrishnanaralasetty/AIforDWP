# Fault A - End-User Communications (Three Audiences)

## Audience 1 - Non-technical Executive
Service is stable and the issue is resolved. This morning, 3 of 4 Floor 3 Finance Windows 11 devices had startup policy failures after overnight migration work; DESKTOP-FB029 was unaffected because it had manual pre-migration settings. We corrected settings on affected devices, refreshed them, and confirmed successful policy processing on all impacted devices by 08:15 AM, with no further incidents reported. Required action: continue normal operations and report any startup issue immediately to the Service Desk.

## Audience 2 - Affected End-User Team
After overnight migration work, three of four Floor 3 Finance Windows 11 devices could not load startup policy settings, while DESKTOP-FB029 stayed unaffected because it had manual settings from before the migration. The issue was fixed at 08:15 AM by correcting and refreshing settings on affected devices, and all impacted devices now process startup policy successfully with no further incidents reported. If this happens again, restart once and report it immediately. Support contact: IT Service Desk via your standard support channel.

## Audience 3 - Engineer-to-Engineer Internal Note
- Root cause: Post-migration DNS client configuration divergence; affected endpoints used an automatic DNS path that did not reliably support AD resource discovery required for startup Group Policy processing.
- Evidence: 3 of 4 Floor 3 Finance Windows 11 devices affected; DESKTOP-FB029 in same OU unaffected; incident started after overnight DNS migration; unaffected outlier had manual pre-migration configuration.
- Exact corrective action: Captured known-good DNS posture from DESKTOP-FB029; compared and corrected DNS client configuration on affected endpoints; ensured consistent intended resolver path; flushed and re-registered DNS client state; re-ran policy processing and reboot validation.
- Configuration details: Affected systems were aligned to the known-good DNS client baseline used by DESKTOP-FB029 and standardized across the Floor 3 Finance cohort.
- Validation performed: Incident resolved at 08:15 AM; all previously affected devices process Group Policy successfully; no further startup policy failures or additional incidents reported.
- Preventive action: Standardize DNS client governance and manual-exception handling; add mandatory post-DNS-change endpoint parity checks; run startup policy synthetic validation after DNS/infrastructure changes; add OU peer resolver drift guardrails; strengthen change templates with AD SRV validation and rollback triggers.
