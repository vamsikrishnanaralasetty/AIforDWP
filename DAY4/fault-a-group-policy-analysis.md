# Fault A - Group Policy Processing Failure Analysis

## Incident Summary
Following overnight migration activities, Group Policy processing is failing during startup for most targeted machines in a Finance scope on Floor 3. The strongest discriminator in scope is that one machine in the same OU remains unaffected and was manually configured before the DNS migration.

## Scope Facts
- Symptom: Group Policy processing failure during startup.
- Affected: 3 of 4 Windows 11 machines in Floor 3 Finance OU.
- Unaffected: DESKTOP-FB029 in the same OU.
- Timing: Issue started following overnight migration activities.
- Recent change: DNS migration completed overnight.
- Additional clue: One machine was manually configured before migration and remains unaffected.

## Initial Ranked Hypotheses
(Weighted by timing, change proximity, and broad scope pattern)

1. Incorrect DNS client configuration on affected machines after migration.
2. New DNS servers missing or not serving required AD records for GP startup.
3. DNS replication/forwarding inconsistency across resolvers.
4. DC locator/site mapping issue surfaced by migration.
5. Client-side stale DNS/network profile state post-cutover.

## Re-Ranked Hypotheses
(Weighted primarily by the outlier clue: FB029 unaffected and manually configured)

1. Automatic DNS client configuration mismatch on the three affected machines.
2. New DNS servers missing/incorrect AD records required at startup.
3. DNS replication/forwarding inconsistency between resolvers.
4. Client-side stale DNS cache/network stack residue on affected hosts.
5. DC locator/site-subnet mapping issue.

## Reasoning for Each Hypothesis

### 1) Automatic DNS Client Configuration Mismatch on Affected Machines
- Why it fits: The 3/4 split within the same OU strongly indicates a host-level configuration path difference, not OU policy targeting differences. FB029 being manually configured before migration is highly consistent with bypassing a bad automatic DNS configuration path.
- Why the FB029 clue strengthens this: This clue directly supports a causal protection effect from manual configuration.
- Single fastest check: Compare DNS client settings across all four hosts (DHCP/manual mode, DNS server list, suffix/search list).

### 2) New DNS Servers Missing/Incorrect AD Records Required at Startup
- Why it fits: Startup Group Policy depends on DNS-based discovery of domain controllers and SYSVOL paths. Migration can leave AD DNS records incomplete or misconfigured.
- Why the FB029 clue partially strengthens this: If FB029 points to different resolvers with complete AD records, it can remain unaffected while others fail.
- Single fastest check: From affected and unaffected endpoints, query AD SRV records (for example _ldap._tcp.dc._msdcs.<domain>) and compare results.

### 3) DNS Replication/Forwarding Inconsistency Between Resolvers
- Why it fits: Migration can produce split-brain behavior where different resolvers answer differently for AD records. This can create selective impact across clients.
- Why the FB029 clue moderately strengthens this: FB029 may resolve through a healthy resolver path while affected hosts use stale/inconsistent resolvers.
- Single fastest check: Query each configured DNS server directly from one affected host and FB029, then compare SRV responses.

### 4) Client-Side Stale DNS Cache/Network Stack Residue
- Why it fits: Post-migration stale cache/profile state can break early startup dependencies for GP.
- Why the FB029 clue weakly strengthens this: It explains selective impact, but does not naturally explain why the manually configured host is persistently clean unless that host also differs in renewal/reboot timing.
- Single fastest check: On one affected machine, flush DNS and renew network settings, reboot, and validate startup GP behavior.

### 5) DC Locator/Site-Subnet Mapping Issue
- Why it fits: GP startup can fail if clients are mapped to an unreachable or wrong-site DC after infrastructure changes.
- Why the FB029 clue weakens this: Site/subnet issues usually affect clients by network placement, not by whether one host was manually configured for DNS in the same OU.
- Single fastest check: Compare dsgetdc results (selected DC and site) between an affected host and FB029.

## Notes
- This document intentionally does not declare root cause.
- The ranking is hypothesis-driven and should be refined after the fast checks above.

## Evidence Review
- Evidence set reviewed: startup Group Policy failures on three affected Floor 3 Finance OU Windows 11 endpoints, with DESKTOP-FB029 in the same OU remaining unaffected.
- Dominant weighting clue: DESKTOP-FB029 was manually configured before DNS migration and is fully unaffected.
- Timing correlation: incident begins immediately after overnight DNS migration activities.
- Assessment method: each hypothesis was tested against scope pattern (3 affected / 1 unaffected in same OU), change timing, and whether manual DNS configuration would plausibly create a protection effect.

## Supported Hypotheses
1. Automatic DNS client configuration mismatch on the three affected machines.
- Support judgement: SUPPORTED.
- Why supported: Best fit for the 3/4 split in the same OU and the manual-configuration outlier; indicates affected devices likely followed a different post-migration DNS path than FB029.

2. New DNS servers missing/incorrect AD records required at startup.
- Support judgement: PARTIALLY SUPPORTED.
- Why supported: Consistent with startup GP dependency on AD DNS records after migration, but weaker than #1 because server-side defects alone would often affect broader scope unless clients use different resolvers.

3. DNS replication/forwarding inconsistency between resolvers.
- Support judgement: PARTIALLY SUPPORTED.
- Why supported: Can explain selective failures if affected devices query inconsistent resolvers while FB029 queries a healthy resolver path.

## Contradicted Hypotheses
4. Client-side stale DNS cache/network stack residue on affected hosts.
- Contradiction judgement: WEAKLY CONTRADICTED as primary cause.
- Why contradicted: Cache residue can occur, but persistent unaffected status of a manually configured peer in the same OU is more strongly explained by deterministic DNS configuration differences.

5. DC locator/site-subnet mapping issue.
- Contradiction judgement: CONTRADICTED relative to stronger alternatives.
- Why contradicted: Site/subnet mapping issues usually align with topology boundaries and should not strongly track one host's manual DNS configuration in the same OU cohort.

## Surviving Hypothesis
- Automatic DNS client configuration mismatch on the three affected machines after DNS migration (automatic/DHCP path), while DESKTOP-FB029 remained on a manually configured, healthy DNS path.

## Root Cause
- Root cause statement: The affected machines consumed post-migration DNS client settings that did not reliably resolve Active Directory resources required during startup Group Policy processing; DESKTOP-FB029 remained unaffected because its pre-migration manual DNS configuration bypassed the faulty resolver path.

## Resolution Steps
1. Capture known-good DNS baseline from DESKTOP-FB029 (DNS servers, suffix/search list, adapter DNS mode).
2. Compare all affected endpoints against this baseline and correct DNS client configuration.
3. Correct authoritative delivery path (DHCP scope/options or policy-driven network baseline) so all Finance Floor 3 clients receive valid DNS settings.
4. Validate AD DNS record availability on configured resolvers (_ldap._tcp.dc._msdcs.<domain>, _kerberos._tcp.<domain>).
5. On affected machines run `ipconfig /flushdns` and `ipconfig /registerdns`.
6. Reboot affected endpoints to validate startup-phase GP processing.
7. Run `gpupdate /force` and confirm policy application completes.
8. Remove temporary manual workarounds once centralized configuration is verified stable.

## Validation Results
- Expected endpoint state:
- Formerly affected hosts resolve AD SRV records consistently via intended DNS resolvers.
- `nltest /dsgetdc:<domain>` returns reachable DC and expected site.
- Startup and foreground policy processing complete without prior DNS/DC discovery failures.

- Expected successful logs after remediation:
- Group Policy Operational Event ID 8000 (computer policy processing completed successfully).
- Group Policy Operational Event ID 5312 (applied GPO list present/updated).
- Absence of recurring failure indicators in startup window:
- Group Policy Event ID 1058.
- Group Policy Event ID 1030.
- DNS Client Event ID 1014 for AD/DC names.
- Netlogon Event ID 5719 during startup.