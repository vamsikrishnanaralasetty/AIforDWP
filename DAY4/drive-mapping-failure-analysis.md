# Drive Mapping Failure Analysis

## Scope Facts
- Symptom: Finance network drive S: not mapped at user logon.
- Who: All Finance users on DESKTOP-FB* devices.
- Since: ~08:00 this morning.
- Change: Drive mapping migrated overnight from GPO logon script to Intune PowerShell script.

## Ranked Hypotheses (Most Probable First)

1. Script execution context mismatch after migration (GPO USER context to unsuitable Intune run context).
- Why it fits: The timing aligns exactly with the overnight migration, and S: mapping is user-session dependent at logon.
- Fastest check: Verify Intune script run context and confirm script logic is compatible with interactive user context.

2. Intune assignment or filter targeting error for Finance on DESKTOP-FB*.
- Why it fits: Immediate post-change failure across the specific cohort strongly matches mis-targeted script deployment.
- Fastest check: Validate assignment scope and filter evaluation for a known affected Finance user/device.

3. Logon-time execution race (script runs before user/network state is ready).
- Why it fits: Intune execution timing can differ from GPO logon sequence, causing mapping failure at sign-in.
- Fastest check: Compare sign-in timeline to script execution time in Intune Management Extension logs.

4. Script logic regression introduced during migration.
- Why it fits: New deployment package may contain path or mapping logic errors that appear immediately after cutover.
- Fastest check: Run the deployed script manually in affected user context and capture errors.

5. Share/UNC access dependency exposed by the new delivery method.
- Why it fits: Method change can expose access assumptions not visible in the prior GPO flow.
- Fastest check: From an affected user session, test direct access to the target UNC path used for S:.

## Note
- This is a hypothesis ranking only and does not commit to a single root cause.

## Addendum - Event Details, Surviving Hypothesis, and Resolution

### Event Details
- Evidence source provided for this incident thread: Intune Management Extension log from an affected Finance device during the incident window.
- Event detail status: No actual log lines, timestamps, event IDs, or execution result codes were supplied in the evidence block; therefore, no event-cited elimination could be completed yet.
- Required evidence to finalize elimination: timestamped script assignment, execution context, run result/exit code, and any mapping or access error text from the same incident window.

### Surviving Hypothesis (Current State)
- Current surviving hypothesis from scope-plus-timing analysis: script execution context mismatch after migration from GPO logon script (user context) to Intune PowerShell execution path.
- Why it currently survives: the symptom is user-logon drive mapping failure, and the defining overnight change replaced a known user-context method with a different deployment mechanism.
- Confidence note: this remains provisional until supported or contradicted by actual timestamped Intune event data.

### Resolution
1. Confirm Intune PowerShell script run context is user-context compatible for logon drive mapping.
2. Validate script assignment and filter scope for Finance users on DESKTOP-FB* devices.
3. Update script logic to run idempotently in user session (remove incorrect stale S: mapping, then map expected target).
4. Add short retry/backoff for logon timing where network or share readiness can lag initial sign-in.
5. Pilot on one affected device and one control device, then force policy sync and test sign-out/sign-in.
6. Review Intune Management Extension execution outcome (timestamp, run state, exit code, and error text) for the pilot.
7. Roll out corrected configuration to the remaining affected cohort.
8. Validate that S: maps at user logon across sampled Finance users on DESKTOP-FB*.
