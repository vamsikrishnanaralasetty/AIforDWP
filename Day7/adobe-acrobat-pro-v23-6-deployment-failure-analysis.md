# Adobe Acrobat Pro v23.6 Deployment Failure Analysis

## Version Header

- Title: Adobe Acrobat Pro v23.6 Deployment Failure Analysis
- Version: 1.0
- Date: 11/08/2026
- Author: vamsi
- Status: Draft

---

## Incident Summary

### Observation
- The Intune-driven install for Adobe Acrobat Pro v23.6 started at 10:01:00 and failed with MSI return code 1603 at 10:01:44.
- Detection then ran and returned Not detected.
- A retry was scheduled for 60 minutes later and executed at 11:01:47.
- The retry also failed with return code 1603.

### Conclusion
- The deployment failure is repeatable and deterministic within the observed two attempts.
- Based on the provided logs only, the immediate failure point is the MSI installation stage, with detection confirming the app is not present after failure.

---

## Scope Facts

- Application Name: Adobe Acrobat Pro v23.6
- Deployment Method: Intune Win32 app package (.intunewin)
- Install Context: SYSTEM
- Install Command: msiexec /i AcrobatPro.msi /quiet
- Detection Method: Registry check
  - Key checked: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
  - Result: Value not found, Not detected
- Retry Behaviour: Automatic retry every 60 minutes after failure

### Timeline of Events

1. 10:01:00 - AgentExecutor starts install for Adobe Acrobat Pro v23.6.
2. 10:01:01 - AppInstaller confirms SYSTEM context.
3. 10:01:02 - Package identified as AdobeAcrobatPro.intunewin.
4. 10:01:03 - Install command launched: msiexec /i AcrobatPro.msi /quiet.
5. 10:01:44 - Return code 1603 logged; install marked failed.
6. 10:01:45 - Detection rule executes registry check.
7. 10:01:45 - Detection key HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 checked; value not found.
8. 10:01:46 - Detection result Not detected.
9. 10:01:47 - App install result marked Failed; retry scheduled in 60 minutes.
10. 11:01:47 - Retry attempt 1 starts.
11. 11:01:48 - Install command launched again.
12. 11:02:31 - Return code 1603 on retry.
13. 11:02:32 - Retry 1 failed; next retry scheduled in 60 minutes.

---

## Evidence Collected

| Timestamp | Log Entry | What it proves |
|---|---|---|
| 2024-03-15 10:01:00 | AgentExecutor Starting app install: Adobe Acrobat Pro v23.6 | Deployment attempt started for the stated app. |
| 2024-03-15 10:01:01 | AppInstaller Install context: SYSTEM | Installer is running in SYSTEM context, not user context. |
| 2024-03-15 10:01:02 | AppInstaller Package: AdobeAcrobatPro.intunewin | Intune package object was selected and processed. |
| 2024-03-15 10:01:03 | AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet | Exact command line used by deployment engine. |
| 2024-03-15 10:01:44 | AppInstaller Return code: 1603 | MSI execution failed with fatal error code 1603. |
| 2024-03-15 10:01:44 | AppInstaller Install failed. Return code 1603. | Deployment engine interpreted return code as failure. |
| 2024-03-15 10:01:45 | DetectionRule Running detection: registry check | Post-install detection workflow executed. |
| 2024-03-15 10:01:45 | DetectionRule Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 | Detection targets a Reader-branded registry path. |
| 2024-03-15 10:01:45 | DetectionRule Value: not found | Expected detection value was absent at check time. |
| 2024-03-15 10:01:46 | DetectionRule Detection result: Not detected | Intune did not detect app installation state as success. |
| 2024-03-15 10:01:47 | AgentExecutor App install result: Failed | Overall app result for attempt 1 is Failed. |
| 2024-03-15 10:01:47 | AgentExecutor Retry scheduled: 60 minutes | Retry policy is active and interval is 60 minutes. |
| 2024-03-15 11:01:47 | AgentExecutor Retry attempt 1: Adobe Acrobat Pro v23.6 | Retry execution began as scheduled. |
| 2024-03-15 11:01:48 | AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet | Retry uses the same install command. |
| 2024-03-15 11:02:31 | AppInstaller Return code: 1603 | Same MSI failure repeated on retry. |
| 2024-03-15 11:02:32 | AgentExecutor Retry 1 failed. Next retry: 60 minutes | Failure persists and automated retry loop continues. |

---

## Differential Diagnosis

Ranked list of the 5 most likely causes, based only on provided evidence.

### 1) Deterministic MSI installation failure in current device state (primary)
- Why it fits the evidence:
  - Both attempts fail with the same MSI code 1603 using the same command.
  - Failure occurs before successful detection can occur.
- Evidence supporting it:
  - 10:01:44 return code 1603.
  - 11:02:31 return code 1603 on retry.
- Fastest validation check:
  - Run the same command with full MSI logging on an affected device and inspect the terminal failing action.
- Evidence that would contradict it:
  - A successful manual execution of the same MSI command under equivalent SYSTEM context on the same device state.

### 2) Detection rule misalignment with product identity (secondary but significant)
- Why it fits the evidence:
  - App name is Acrobat Pro, but detection path references Acrobat Reader.
  - Even if install succeeded, wrong detection could still mark Not detected and cause repeat attempts.
- Evidence supporting it:
  - 10:01:45 detection key is HKLM\\SOFTWARE\\Adobe\\Acrobat Reader\\23.0.
  - 10:01:46 detection result is Not detected.
- Fastest validation check:
  - Compare configured detection key/value against actual registry artifacts on a known-good Acrobat Pro v23.6 installation.
- Evidence that would contradict it:
  - Verified proof that Acrobat Pro v23.6 legitimately writes the exact Reader key/value used in detection.

### 3) Existing Adobe product conflict or upgrade blocking condition
- Why it fits the evidence:
  - Repeated 1603 is consistent with unresolved installer conflict states between attempts.
- Evidence supporting it:
  - Identical failure code across attempts with no parameter changes.
- Fastest validation check:
  - Enumerate installed Adobe-related products and check MSI upgrade/related product handling in verbose MSI log.
- Evidence that would contradict it:
  - MSI verbose log shows failure at a non-conflict step unrelated to product coexistence or upgrade logic.

### 4) Packaging/content execution issue inside the .intunewin payload
- Why it fits the evidence:
  - If packaged content is incomplete or internally inconsistent, command execution can repeatedly fail.
- Evidence supporting it:
  - Repeated identical failures from the same package and command.
- Fastest validation check:
  - Extract or stage package content and verify AcrobatPro.msi integrity and expected companion files.
- Evidence that would contradict it:
  - Confirmed package integrity and successful install from identical staged content on equivalent endpoint.

### 5) Device precondition failure (for example pending reboot, prerequisite missing, or system state constraint)
- Why it fits the evidence:
  - MSI 1603 is compatible with unmet preconditions.
  - Retry after 60 minutes fails again, indicating condition persisted.
- Evidence supporting it:
  - Same 1603 on both attempts without environmental correction.
- Fastest validation check:
  - Check pending reboot indicators and prerequisite state; inspect MSI verbose log for explicit prerequisite/action failure.
- Evidence that would contradict it:
  - MSI verbose log shows no prerequisite or state block and instead points to a different root mechanism.

---

## Hypothesis Elimination

### Hypothesis 1: Deterministic MSI installation failure in current device state
- Supports:
  - 10:01:44 and 11:02:31 both show return code 1603.
  - Command unchanged between attempts (10:01:03 and 11:01:48).
- Contradicts:
  - No direct contradiction in provided logs.
- Neutral:
  - Detection path/content details do not directly identify MSI internal failing action.

### Hypothesis 2: Detection rule misalignment with product identity
- Supports:
  - App is Adobe Acrobat Pro v23.6 (10:01:00), detection checks Acrobat Reader key (10:01:45).
  - Detection result Not detected (10:01:46).
- Contradicts:
  - Initial install already failed at 10:01:44 before detection result, so detection mismatch alone cannot explain first failure.
- Neutral:
  - Logs do not show a successful install that was incorrectly marked failed purely by detection.

### Hypothesis 3: Existing Adobe product conflict or upgrade block
- Supports:
  - Repeat 1603 pattern across attempts (10:01:44, 11:02:31).
- Contradicts:
  - No explicit conflict message in provided logs.
- Neutral:
  - No inventory of existing Adobe installations is provided.

### Hypothesis 4: Packaging/content issue in .intunewin payload
- Supports:
  - Repeatable failure from same package and command (10:01:02, 10:01:03, 11:01:48, 11:02:31).
- Contradicts:
  - No explicit file missing/corruption indicator in provided logs.
- Neutral:
  - No content hash/integrity check output provided.

### Hypothesis 5: Device precondition failure
- Supports:
  - 1603 can represent precondition failure; recurring on retry suggests unresolved state.
- Contradicts:
  - No explicit precondition error string in provided logs.
- Neutral:
  - No reboot/pending state/prerequisite telemetry is provided.

---

## Surviving Hypothesis

### Surviving hypothesis
- The primary failure is a deterministic MSI execution failure (code 1603) in SYSTEM context, and there is also a probable detection-rule mismatch that can sustain false negative detection even if install later succeeds.

### Why it survives
- It is the only explanation directly proven by repeated identical installer outcomes at two timestamps with unchanged command and context.
- It aligns with the sequence: install failure first, detection non-detection second, then scheduled retry and repeat failure.

### Why others are eliminated or downgraded
- Detection mismatch is downgraded as a secondary factor for this incident stage because detection happens after the first install failure and therefore cannot be the first-cause of 1603.
- Conflict, packaging, and prerequisite hypotheses remain plausible but unproven due to missing lower-level MSI evidence.

### How it explains all observed behaviour
- Repeated 1603 explains both failed attempts.
- Not detected explains why Intune keeps treating the app as absent.
- Retry scheduling explains recurrence every 60 minutes.

---

## Proposed Resolution

Most likely fix path, based on available evidence only:

1. Preserve current assignment scope but pause further expansion until failure mechanism is identified.
2. Enable verbose MSI logging for the same install command on an affected device to capture the exact failing MSI action.
3. Validate and correct detection configuration against a known-good Acrobat Pro v23.6 registry footprint, because current detection references a Reader path.
4. Re-test deployment on a controlled pilot subset before re-enabling broad retries.

Note:
- This is a proposed fix path, not a confirmed root-cause fix.
- Success cannot be assumed until MSI-level evidence confirms the failing action and a retest passes.

---

## Next Investigation Actions

Additional data required to confirm root cause with certainty:

1. Full MSI verbose log from an affected endpoint for the failing install attempt.
2. Intune Management Extension log segment for the same timestamps to correlate command staging and execution context details.
3. Registry export from a known-good Acrobat Pro v23.6 device to verify correct detection key/value for Pro edition.
4. Local inventory of installed Adobe products on affected endpoint before install attempt.
5. Device state checks at install time (pending reboot, prerequisite/runtime presence, disk space, and policy constraints).

---

## Observation vs Conclusion Traceability

### Observations (directly logged)
- Install command executed twice under SYSTEM context.
- Both executions returned 1603.
- Detection checked Reader key and returned Not detected.
- Retry interval was 60 minutes.

### Conclusions (derived)
- Failure is deterministic across at least two attempts.
- MSI stage is the confirmed immediate failure point.
- Detection mismatch is probable secondary risk and may cause continued non-detection behavior.
