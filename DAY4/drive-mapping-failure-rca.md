# Drive Mapping Failure Incident RCA

## Executive Summary
Finance users on DESKTOP-FB devices experienced failure to map network drive S: at user logon after an overnight migration from a GPO logon script to an Intune PowerShell script. The issue was resolved at 09:15 AM after applying the identified remediation approach and validating user logon behavior. Post-fix verification confirmed Finance users can log in and S: maps successfully, with no additional issues reported.

## Incident Description
At approximately 08:00 AM, Finance users reported that drive S: was not mapped during sign-in on DESKTOP-FB devices. The incident followed an overnight change that migrated drive mapping delivery from a GPO logon script (user context) to an Intune PowerShell script. The outage pattern aligned to the new delivery method and user-logon timing.

## Scope of Impact
- Affected users: Finance users.
- Affected devices: DESKTOP-FB* endpoints.
- Symptom: Drive S: not mapped at user logon.
- Start time: ~08:00 AM.
- Resolution time: 09:15 AM.

## Business Impact
- Finance users experienced login-session disruption due to missing access path via drive S:.
- Productivity was reduced during the incident window while users were unable to access expected mapped-drive resources through normal workflow.
- Service desk and engineering effort increased during triage and remediation.

## Timeline
- Overnight: Drive mapping migrated from GPO logon script to Intune PowerShell script.
- ~08:00 AM: Incident observed; Finance users report S: not mapped at logon on DESKTOP-FB devices.
- Triage window: Hypotheses ranked with primary weighting on change timing and logon execution model differences.
- Investigation focus: Script execution context, targeting, and logon-timing behavior under Intune delivery.
- Remediation applied: Suggested resolution implemented on affected scope.
- 09:15 AM: Incident confirmed resolved.
- Post-resolution validation: Finance users log in successfully and S: maps on DESKTOP-FB devices; no further issues reported.

## Investigation Activities
1. Confirmed scope pattern (Finance users on DESKTOP-FB devices) and symptom consistency at user logon.
2. Correlated incident start time to overnight migration from GPO user logon script to Intune PowerShell script.
3. Re-ranked hypotheses using timing clue as primary discriminator.
4. Focused elimination sequence on execution context compatibility, assignment targeting, and sign-in timing behavior.
5. Applied corrective resolution aligned to the surviving hypothesis path.
6. Performed post-change verification across affected user/device cohort.

## Supporting Evidence
- Temporal correlation evidence: Issue began after the overnight migration change.
- Scope consistency evidence: Impact restricted to Finance users on DESKTOP-FB devices with the same symptom.
- Behavioral evidence: Symptom occurred specifically at user logon, consistent with script delivery/context differences.
- Remediation confirmation evidence: After applying the suggested fix, users could log in and S: mapped successfully.
- Stability evidence: No additional issues reported after 09:15 AM resolution.

## Root Cause Analysis
### Root Cause Statement
The incident was caused by a post-migration mismatch between the original GPO logon script execution model (user-context logon behavior) and the new Intune PowerShell script delivery behavior, resulting in S: not mapping during user sign-in on affected DESKTOP-FB devices.

### Why This Fits the Observed Pattern
- The symptom was strictly logon-time and user-session dependent.
- The incident started immediately after the migration that changed how and when the mapping logic executed.
- Resolution through migration-path correction restored normal S: mapping for the affected scope.

## Resolution Applied
1. Applied the recommended remediation for the migrated Intune drive-mapping script path.
2. Corrected delivery behavior to align with user-logon mapping requirements.
3. Re-applied policy/script behavior to affected DESKTOP-FB endpoints.
4. Validated successful mapping outcome during Finance user logon.

## Validation Performed
- Verified Finance users can log in normally on DESKTOP-FB devices.
- Verified drive S: maps successfully at user sign-in.
- Verified no ongoing or repeat issues were reported after 09:15 AM.

## 5 Why Analysis
1. Why was drive S: missing at logon?
- The mapping action did not complete successfully during the user sign-in flow.

2. Why did mapping not complete during sign-in?
- The migration changed the execution model from GPO user logon behavior to Intune PowerShell delivery behavior.

3. Why did the new model fail for this use case?
- The delivered behavior did not fully match the user-logon mapping requirements for Finance users on DESKTOP-FB endpoints.

4. Why was this mismatch not prevented before rollout?
- The migration did not sufficiently validate equivalent user-logon outcome across the full in-scope Finance cohort before production exposure.

5. Why was pre-production validation insufficient?
- Change controls emphasized migration completion over explicit user-logon functional parity checks for mapped-drive outcomes.

## Preventive Actions
1. Add mandatory pre-cutover and post-cutover parity validation for user-logon outcomes when migrating from GPO logon scripts to Intune delivery.
2. Require explicit execution-context verification (user vs system) for all mapped-drive automation.
3. Introduce pilot deployment gates on representative Finance users and DESKTOP-FB devices before full rollout.
4. Add rollback criteria tied to sign-in functional checks (for example mapped drive availability within the first logon cycle).
5. Standardize post-change monitoring checklist for mapped-drive incidents during the first business hour after migration.

## Lessons Learned
- For logon-dependent functions, delivery mechanism changes must be validated on end-user outcome, not only deployment success state.
- Timing and scope clues can rapidly narrow hypotheses when a change window is clearly defined.
- User-session behavior should be treated as a first-class acceptance criterion in script migration plans.

## Closure Statement
Incident closed. The drive mapping failure affecting Finance users on DESKTOP-FB devices was resolved at 09:15 AM after applying the recommended remediation to the migrated script delivery path. Validation confirmed successful S: mapping at logon and no further issues reported.