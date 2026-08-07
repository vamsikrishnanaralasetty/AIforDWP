Resolved.

Cause: Post-migration DNS client configuration divergence caused affected endpoints to use an automatic DNS path that did not reliably support AD resource discovery for startup Group Policy processing.

Action: Captured known-good DNS posture from DESKTOP-FB029, corrected DNS client configuration on affected devices, ensured consistent resolver path, flushed and re-registered DNS client state, then re-ran policy processing and reboot validation.

Preventive: Standardize DNS client configuration governance and manual exception handling, and enforce mandatory post-DNS-change endpoint parity checks with startup policy validation.

User confirmed working.
