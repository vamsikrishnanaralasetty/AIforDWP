# Fault A - Known Error Record

## Symptom
Group Policy processing failed during startup on affected endpoints. In the documented scope, the failure presented on three Windows 11 devices in the Floor 3 Finance OU while one peer remained unaffected.

## Cause
Post-migration DNS client configuration divergence caused affected endpoints to use an automatic DNS path that did not reliably support Active Directory resource discovery required for startup Group Policy processing. The unaffected endpoint, DESKTOP-FB029, was manually configured before migration and did not use the failing path.

## Scope
Affected population was 3 of 4 Windows 11 devices in the Floor 3 Finance OU. DESKTOP-FB029 in the same OU was unaffected, and the incident started after overnight DNS migration activities.

## Workaround
Use the known-good DNS client posture from DESKTOP-FB029 to temporarily align affected devices so startup policy processing can complete. Then flush and re-register DNS client state and re-run policy processing.

## Permanent Fix
Correct DNS client configuration on affected endpoints and standardize the intended resolver path across the Floor 3 Finance cohort. Enforce post-change DNS parity checks and startup policy validation after DNS/infrastructure changes.

## How to Spot It
Spot this condition when startup Group Policy failures appear immediately after DNS migration, affecting some OU peers while a manually configured peer (DESKTOP-FB029) remains unaffected. DNS details that were relevant in analysis were divergence between automatic/DHCP client DNS settings and manual pre-migration DNS settings, with AD SRV resolution checks (_ldap._tcp.dc._msdcs.<domain>, _kerberos._tcp.<domain>) used during investigation. Event IDs referenced in analysis validation were Group Policy Operational 8000/5312 as success indicators and absence of Group Policy 1058/1030, DNS Client 1014, and Netlogon 5719 as failure indicators.
