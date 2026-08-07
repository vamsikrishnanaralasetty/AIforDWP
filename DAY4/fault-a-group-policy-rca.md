# Fault A - Group Policy Startup Failure RCA

## 1. Executive Summary
A Group Policy processing failure at startup affected most Windows 11 endpoints in the Floor 3 Finance OU following overnight DNS migration activities. The incident was resolved at 08:15 AM after correcting DNS client configuration alignment across affected devices and validating Active Directory name resolution and policy processing. Service has remained stable, all previously affected devices now process Group Policy successfully, and no further incidents have been reported.

## 2. Incident Description
During morning operations, three of four Windows 11 endpoints in the Floor 3 Finance OU were unable to process Group Policy at startup. One peer endpoint, DESKTOP-FB029, remained unaffected. Initial triage identified a strong correlation with the overnight DNS migration and the fact that the unaffected machine had been manually configured prior to migration. This pattern drove a DNS-path-focused investigation.

## 3. Business Impact
- Users on affected endpoints experienced startup policy processing failures, increasing login friction and introducing potential policy compliance drift.
- Risk exposure included delayed application of security and configuration baselines at machine startup.
- Floor 3 Finance operations faced elevated support demand during early business hours.
- Impact remained contained to a small endpoint subset and was remediated within the same business morning.

## 4. Scope of Impact
- Affected population: 3 of 4 Windows 11 devices in Floor 3 Finance OU.
- Unaffected population: DESKTOP-FB029 in the same OU.
- Platform: Windows 11 domain-joined clients.
- Functional symptom: Group Policy processing failure during startup.
- Geographic/organizational scope: Floor 3 Finance endpoint cohort.

## 5. Timeline
- Overnight (pre-incident): DNS migration activities completed.
- Morning detection window: Startup Group Policy failures reported from Floor 3 Finance endpoints.
- Triage phase: Scope confirmed as 3 affected, 1 unaffected (DESKTOP-FB029).
- Hypothesis refinement: Investigation weighted toward DNS client/resolver divergence due to manual configuration outlier.
- Remediation execution: DNS client settings corrected on affected devices and DNS/GP refresh actions completed.
- 08:15 AM: Incident resolved.
- Post-resolution: Validation completed across all previously affected endpoints.
- Ongoing observation: No further incidents reported.

## 6. Investigation Activities
1. Established scope boundaries and validated that all impacted machines were in the same OU.
2. Identified outlier behavior (DESKTOP-FB029 unaffected) and correlated to pre-migration manual DNS configuration.
3. Compared hypotheses against timing, change window, and selective impact pattern.
4. Prioritized DNS path divergence hypotheses over OU-targeting or broad site-level hypotheses.
5. Performed comparative checks of DNS client posture between affected systems and known-good outlier.
6. Validated AD-dependent DNS resolution paths required by startup Group Policy.
7. Executed corrective DNS client standardization and forced policy/name-resolution refresh.

## 7. Supporting Evidence
- Scope evidence: 3/4 devices impacted within same OU; one unaffected peer in same OU.
- Change evidence: Incident onset immediately followed DNS migration activities.
- Outlier evidence: Unaffected endpoint (DESKTOP-FB029) had manual pre-migration configuration.
- Correlation evidence: Restoring DNS alignment on affected endpoints restored startup GP processing.
- Stability evidence: After remediation, all previously affected devices validated healthy and no recurrence observed.

## 8. Root Cause Analysis
Primary technical cause:
- A DNS client configuration divergence existed after DNS migration. Affected endpoints followed an automatic post-migration DNS configuration path that did not reliably support AD resource discovery required for startup Group Policy processing.

Why this explains the observed scope:
- The unaffected machine (DESKTOP-FB029) used manual pre-migration DNS configuration and did not traverse the failing resolver path.
- The selective 3-of-4 impact in the same OU is consistent with client configuration divergence, not OU-level targeting defects.

Contributing factors:
- Overnight change timing reduced immediate cross-device configuration parity visibility.
- Presence of one pre-existing manual exception masked baseline inconsistency until startup policy behavior diverged.

## 9. Resolution Applied
1. Captured known-good DNS posture from DESKTOP-FB029.
2. Compared and corrected DNS client configuration on all affected endpoints.
3. Ensured intended DNS resolver path was consistently applied across the Floor 3 Finance cohort.
4. Flushed and re-registered DNS client state on affected machines.
5. Re-ran policy processing and reboot validation to confirm startup behavior.

## 10. Validation Performed
- Confirmed all previously affected devices completed Group Policy processing successfully.
- Confirmed no further startup policy failures after corrective actions.
- Confirmed incident status as resolved at 08:15 AM.
- Confirmed post-remediation operational stability via absence of new incident reports.

## 11. 5 Why Analysis
1. Why did startup Group Policy fail on three machines?
- They could not consistently complete AD-dependent discovery during startup policy processing.

2. Why could AD-dependent discovery fail?
- DNS resolution path used by those endpoints was misaligned after migration.

3. Why was DNS resolution path misaligned on only those endpoints?
- Those devices consumed an automatic post-migration DNS client configuration that differed from the known-good manual configuration on DESKTOP-FB029.

4. Why did this divergence persist into production startup processing?
- Configuration parity controls did not immediately detect and reconcile manual exception vs migrated baseline differences.

5. Why were parity controls insufficient at that moment?
- Change execution emphasized migration completion but lacked a strict immediate post-change endpoint parity validation gate for all in-scope clients.

## 12. Preventive Actions
1. Standardize DNS client configuration governance for domain-joined endpoints, including controlled handling of manual exceptions.
2. Add mandatory post-DNS-change endpoint parity checks (sampled and full-cohort where feasible).
3. Implement a startup Group Policy synthetic validation checklist after DNS/infrastructure migrations.
4. Add an operational guardrail to compare resolver settings across OU peers and flag drift.
5. Improve change templates with explicit AD SRV resolution validation criteria and rollback triggers.
6. Document approved emergency manual configuration procedure and required reconciliation timeline.

## 13. Lessons Learned
- Outlier analysis is high-value: one unaffected peer with known config differences can quickly focus investigation.
- Scope + timing + exception posture provides stronger signal than generic symptom-led troubleshooting.
- DNS migrations affecting AD-integrated services require immediate endpoint-level parity checks, not only server-side completion checks.
- RCA quality improves when hypotheses are re-ranked as new discriminating evidence emerges.

## 14. Closure Statement
Incident is closed. Root cause was identified as post-migration DNS client configuration divergence affecting startup Group Policy dependency resolution on three Floor 3 Finance Windows 11 endpoints. Corrective actions were implemented and validated. Issue resolved at 08:15 AM, all previously affected devices are healthy, and no additional incidents have been reported.