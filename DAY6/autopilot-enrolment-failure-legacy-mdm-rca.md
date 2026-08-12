# Autopilot Enrolment Failure RCA (DWP)

## Incident Summary
- Incident type: Windows Autopilot enrolment failure during MDM registration
- Affected device state: Azure AD joined device attempting Autopilot-managed Intune enrolment
- Observation source: MDM diagnostic export provided from failed device
- Outcome at point of analysis: Autopilot enrolment failed before policy delivery completed
- Confirmed root cause: Existing legacy manual MDM enrolment from 2023-11-04 blocked new Autopilot enrolment

## Executive Summary
The device failed Autopilot enrolment because it already had an active or residual MDM enrolment from a prior legacy manual enrolment. Autopilot could not create a clean Intune-managed enrolment channel over that conflicting existing management relationship. The export explicitly records the failure state, the pre-existing MDM enrolment, zero successful profile applications, and no licensing or network defect. This makes the stale legacy enrolment the primary root cause, with access-denied behaviour during profile processing acting as a downstream symptom rather than a separate primary cause.

## Supporting Evidence

### Raw Scope Facts From Export
- `EnrollmentState : Failed`
- `ErrorCode : 0x80180014`
- `ErrorDescription : The device is already enrolled in MDM.`
- `MDMEnrolled : Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource : Legacy manual MDM enrolment`
- `ProfilesApplied : 0 of 4`
- `LastError : 0x80070005 (Access denied)`
- `AzureADJoined : Yes`
- `IntuneP1License : Yes`
- `AutopilotLicense : Yes`
- `Network : All endpoints reachable, no proxy`

### Evidence Interpretation
1. Autopilot enrolment did not succeed.
- Evidence: `EnrollmentState : Failed`

2. The failure occurred in the presence of an existing MDM relationship.
- Evidence: `MDMEnrolled : Yes`
- Evidence: `ErrorDescription : The device is already enrolled in MDM.`
- Evidence: `EnrolmentSource : Legacy manual MDM enrolment`

3. The conflicting enrolment was not newly created by this Autopilot run.
- Evidence: `previous enrolment from 2023-11-04`

4. Policy and profile delivery never began successfully.
- Evidence: `ProfilesApplied : 0 of 4`

5. Access-denied behaviour occurred after or during the failed enrolment workflow.
- Evidence: `LastError : 0x80070005 (Access denied)`
- Interpretation: Consistent with the device not being able to establish or reuse the required management context because the older enrolment already owned it.

6. Azure AD join, licensing, and network prerequisites were not the blocking factors.
- Evidence: `AzureADJoined : Yes`
- Evidence: `IntuneP1License : Yes`
- Evidence: `AutopilotLicense : Yes`
- Evidence: `Network : All endpoints reachable, no proxy`

## Timeline

Note: The export does not include precise timestamps for each sub-step, so the sequence below is a reconstruction of the control flow rather than a clock-time event timeline.

1. The device was manually enrolled into MDM on 2023-11-04.
2. That legacy enrolment remained present on the device and/or in the management records.
3. The device was later Azure AD joined and entered an Autopilot enrolment attempt.
4. Autopilot attempted to establish Intune MDM enrolment.
5. The enrolment process detected an existing MDM enrolment and failed.
6. The failure surfaced as `0x80180014` with the explicit description that the device was already enrolled in MDM.
7. No assigned profiles were successfully applied (`0 of 4`).
8. A secondary `0x80070005 (Access denied)` error was recorded during the failed process.
9. Network and licensing checks remained healthy throughout the scope evidence provided.

## Problem Statement
The device could not complete Windows Autopilot enrolment into Intune because a previous legacy manual MDM enrolment already existed and conflicted with the new management workflow.

## Root Cause Analysis (5 Whys)

### Why 1
Why did Autopilot enrolment fail?
- Because the device was already enrolled in MDM.
- Evidence: `ErrorDescription : The device is already enrolled in MDM.`
- Evidence: `EnrollmentState : Failed`

### Why 2
Why was the device already enrolled in MDM?
- Because a previous manual MDM enrolment from 2023-11-04 still existed.
- Evidence: `MDMEnrolled : Yes (previous enrolment from 2023-11-04)`
- Evidence: `EnrolmentSource : Legacy manual MDM enrolment`

### Why 3
Why did that previous enrolment block Autopilot?
- Because Autopilot requires a clean, non-conflicting management relationship to establish Intune enrolment and apply assigned profiles.
- Evidence: `ProfilesApplied : 0 of 4`
- Evidence: Failure occurred before meaningful policy application began.

### Why 4
Why was the old enrolment still present at the time of Autopilot reuse?
- Because the device lifecycle process did not fully retire or remove legacy MDM enrolment before reusing the endpoint for Autopilot.
- Evidence: Legacy enrolment is explicitly still recorded in scope.
- Evidence: No evidence of licensing or network failure suggests the blocker was leftover management state, not environmental readiness.

### Why 5
Why did the lifecycle process allow a device with legacy enrolment into the Autopilot path?
- Because there was no effective pre-enrolment hygiene control to detect and clear existing manual/legacy MDM enrolments before Autopilot assignment or redeployment.
- Evidence: The device entered Autopilot with an already-known conflicting enrolment state.

### Root Cause
Primary root cause: A stale legacy manual MDM enrolment from 2023-11-04 was not removed before the device was reused for Autopilot, causing a direct enrolment conflict.

### Contributing Factors
- Device reuse process did not enforce legacy enrolment cleanup before Autopilot.
- Old enrolment state likely persisted both in management records and on the endpoint.
- Access denied (`0x80070005`) acted as a secondary symptom once the enrolment workflow encountered the ownership conflict.

## Why Alternative Causes Were Ruled Out
1. Licensing mismatch was ruled out.
- Evidence: `IntuneP1License : Yes`
- Evidence: `AutopilotLicense : Yes`

2. Network connectivity issue was ruled out.
- Evidence: `All endpoints reachable, no proxy`

3. Azure AD join failure was ruled out.
- Evidence: `AzureADJoined : Yes`

4. Policy misassignment was not the primary blocker.
- Evidence: `ProfilesApplied : 0 of 4`
- Interpretation: The device failed before normal policy application could begin.

## Impact Assessment
- Device could not complete Autopilot provisioning.
- No Intune configuration profiles were applied.
- Device would remain unusable for intended managed handover until the stale enrolment conflict was cleared.
- If repeated at scale, similar reused devices with legacy enrolment history could fail Autopilot in batches.

## Corrective Actions for This Incident

### Admin Center Actions
1. Identify the stale managed device record in Intune for the endpoint.
2. Confirm it corresponds to the prior legacy manual enrolment.
3. Retire or delete the stale device record as appropriate.
4. Preserve the valid Windows Autopilot registration unless it is duplicated or incorrect.
5. Confirm no conflicting legacy managed record remains before retrying enrolment.

### Device-Side Actions
1. Open Settings → Accounts → Access work or school.
2. Remove the old legacy work or school MDM connection.
3. Reboot the device.
4. Confirm the old management connection is no longer present.
5. Restart the Autopilot enrolment flow.

## Verification After Remediation
1. The device completes the Autopilot sign-in and enrolment flow without repeating `0x80180014`.
2. A current Intune managed device record appears with active check-in.
3. Assigned profiles begin applying successfully instead of `0 of 4`.
4. The device reports as Intune-managed with expected user association.
5. Compliance and configuration status begin evaluating normally.

## Preventive Actions

### Process Controls
1. Add a mandatory pre-Autopilot check for existing legacy or manual MDM enrolment before any reused device enters provisioning.
2. Require retirement or deletion of stale Intune managed records before redeployment.
3. Add a device-side check to confirm no old Access work or school connection remains before handing the device to the next user.

### Operational Controls
1. Maintain a reuse checklist for returned and rebuilt devices that includes legacy MDM cleanup.
2. Separate Autopilot registration validation from MDM cleanup validation so both are explicitly checked.
3. Flag devices with historical manual enrolment for review before Autopilot assignment.

### Strategic Preventive Action
1. Standardise on Autopilot-driven lifecycle management for eligible devices and stop using legacy manual MDM enrolment paths for devices that will later be reused through Autopilot.

## 5 Why Summary Table

| Why Level | Answer | Evidence |
|---|---|---|
| 1 | Autopilot failed because the device was already enrolled in MDM | `EnrollmentState : Failed`; `ErrorDescription : The device is already enrolled in MDM.` |
| 2 | The existing enrolment was a prior legacy manual MDM enrolment | `MDMEnrolled : Yes`; `EnrolmentSource : Legacy manual MDM enrolment` |
| 3 | The conflict blocked new Intune enrolment before profiles could apply | `ProfilesApplied : 0 of 4` |
| 4 | The old enrolment was not removed during device reuse | Prior enrolment from `2023-11-04` remained present |
| 5 | Reuse process lacked a mandatory legacy-enrolment cleanup gate before Autopilot | Device entered Autopilot with known conflicting management state |

## Confidence and Limitations
- Confidence: High.
- Reason: The export directly states the device was already enrolled in MDM and identifies the prior legacy manual enrolment.
- Limitation: The export does not provide timestamped event logs for each internal Autopilot step, so the timeline is reconstructed from the available state evidence rather than full chronological telemetry.
