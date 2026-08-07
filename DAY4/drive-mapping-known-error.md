# Drive Mapping Known Error Record

Symptom: Finance users on DESKTOP-FB devices experience drive S: not mapped at user logon. Users can sign in but do not receive the expected mapped drive during sign-in.

Cause: Verified root cause is a post-migration mismatch between the original GPO logon script execution model (user-context logon behavior) and the new Intune PowerShell script delivery behavior. This mismatch caused S: not to map during user sign-in.

Scope: Affected users were Finance users. Affected systems were DESKTOP-FB* endpoints during the incident window that started around 08:00 AM and was resolved at 09:15 AM.

Workaround: Apply the recommended remediation path for the migrated Intune drive-mapping delivery and re-apply script/policy behavior to affected DESKTOP-FB endpoints. This restored S: mapping at user logon in the incident.

Permanent fix: Correct the migrated drive-mapping delivery behavior so it aligns with user-logon mapping requirements, then validate successful S: mapping at sign-in. Enforce pre-cutover and post-cutover parity checks, including explicit execution-context verification and pilot gates before full rollout.

How to spot it: Identify this pattern when drive S: fails at user logon for Finance users on DESKTOP-FB devices immediately after migration from a GPO logon script to an Intune PowerShell script. The verified signal set includes the user-visible error condition (S: not mapped), script type change (GPO logon script to Intune PowerShell script), and execution-context mismatch; no specific event IDs or script file names were recorded in the verified RCA.