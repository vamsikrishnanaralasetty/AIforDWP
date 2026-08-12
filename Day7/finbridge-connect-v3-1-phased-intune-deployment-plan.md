# Phased Intune Deployment Plan: FinBridge Connect v3.1

| Field | Detail |
|---|---|
| **Title** | FinBridge Connect v3.1 Phased Intune Deployment Plan |
| **Version** | 1.0 |
| **Date** | 11/08/2026 |
| **Author** | Copilot |
| **Status** | Draft |
| **Scope** | 10,000 Windows 11 endpoints |
| **Deadline** | 3 weeks from today (01/09/2026) |

---

**App:** FinBridge Connect v3.1 (.intunewin package, already in the Intune app catalog)  
**Previous version:** v3.0 remains available for rollback  
**Known constraints:** Finance requires delivery by end of Week 1; 5% of devices have 4 GB RAM and may need slower treatment  
**Detection method:** Registry version string check

---

## 1. Deployment Objective

1. Deploy FinBridge Connect v3.1 to 10,000 Win11 endpoints within 3 weeks.
2. Deliver to the Finance cohort of 500 users by the end of Week 1.
3. Reduce rollout risk by separating low-spec devices into a controlled final ring.
4. Keep v3.0 ready for immediate rollback if v3.1 creates business impact or technical instability.

---

## 2. Ring Design

1. Ring 0 - IT pilot
   - Size: 100 devices
   - Purpose: validate install command, uninstall command, detection rule, and user experience.
   - Devices: IT support and a small mix of standard hardware.

2. Ring 1 - Finance priority
   - Size: 500 users/devices
   - Purpose: meet the Week 1 business deadline.
   - Devices: Finance users only.

3. Ring 2 - Broad production wave A
   - Size: about 3,500 devices
   - Purpose: expand to standard endpoints after pilot and Finance stability.

4. Ring 3 - Broad production wave B
   - Size: about 4,900 devices
   - Purpose: finish the standard-device rollout while holding back low-spec endpoints.

5. Ring 4 - Low-spec devices
   - Size: about 500 devices
   - Purpose: separate 4 GB RAM devices and deploy only after earlier rings are stable.

---

## 3. Timeline

### Week 1: Pilot and Finance delivery

1. Day 1
   - Confirm the app is visible in the catalog.
   - Validate the install and uninstall commands on 5-10 test devices.
   - Confirm the registry detection rule returns Installed only when version = 3.1.

2. Day 2
   - Deploy Ring 0 to 100 pilot devices.
   - Review install success, failure codes, detection behavior, and launch performance.

3. Day 3
   - Go/no-go review.
   - If pilot is healthy, deploy Ring 1 to Finance.

4. Day 4-5
   - Stabilize Finance deployment.
   - Resolve install failures, detection mismatches, and endpoint performance issues.

Week 1 exit requirement:
- Finance must be substantially complete by end of Week 1, with no open Sev-1 deployment issue.

### Week 2: Standard-device expansion

1. Deploy Ring 2 in one or two controlled batches, not all at once.
2. Pause between batches long enough to confirm telemetry and helpdesk trends.
3. If Ring 2 is stable, begin Ring 3 before the end of the week.

### Week 3: Complete rollout and low-spec devices

1. Finish Ring 3.
2. Deploy Ring 4 only after standard devices are stable.
3. Reserve the final 2-3 business days for retries, exceptions, and rollback cleanup.

---

## 4. Assignment Rules

1. Use Required assignment for standard managed rollout rings.
2. Use Available only if you intentionally want user-driven install from Company Portal.
3. Use Uninstall only for rollback or forced removal.
4. Do not assign v3.1 directly to all 10,000 devices on day 1.
5. Do not include the low-spec group in early rings unless there is a confirmed compatibility result.

---

## 5. Success Gates

1. Ring 0 success gate
   - At least 98% install success.
   - No critical launch defect.
   - Detection rule must match real installs and only real installs.

2. Finance gate
   - At least 97% success in the Finance ring.
   - No material business disruption.
   - Helpdesk trend must be stable or improving.

3. Standard-device gate
   - At least 97% success across Ring 2 and Ring 3.
   - No repeating failure pattern linked to hardware class or Windows build.

4. Low-spec gate
   - 4 GB RAM devices must meet a stricter stability check before the last ring expands.
   - If performance is poor, keep them isolated and rework packaging or requirements.

---

## 6. Monitoring

1. Review deployment status after 4 hours, 24 hours, and 48 hours for each ring.
2. Watch for these signals:
   - Installed
   - Failed
   - Not applicable
   - Slow install times
   - Repeated user complaints after launch
3. Review install return codes and detection failures separately.
4. Check whether low-spec devices are overrepresented in failures.

---

## 7. Status Interpretation

1. Installed
   - Intune detected the expected registry value and considers the app present.

2. Failed
   - Install did not complete successfully, or the detection rule did not pass.
   - Check installer logs, return codes, and the registry value.

3. Not applicable
   - The device does not meet a requirement or is not in scope.
   - Common causes: wrong assignment, unsupported OS, or incompatible hardware requirement.

---

## 8. Rollback Plan

1. Trigger rollback immediately if:
   - Finance cannot work normally after deployment.
   - Success rate drops below the agreed gate for any ring.
   - A repeatable install or launch defect appears.

2. Rollback actions:
   - Pause all new v3.1 assignments.
   - Reassign the affected scope to v3.0 from the catalog.
   - Force policy refresh on impacted devices.
   - Verify the app launches and detection is healthy on a test subset.

3. Rollback should be tested before broad rollout continues.

---

## 9. Practical Intune Setup Notes

1. Create separate device groups for each ring.
2. Exclude low-spec devices from Rings 0-3 until Ring 4.
3. Keep the detection rule strict so v3.0 does not look like v3.1.
4. Confirm uninstall behavior before any production wave begins.
5. Keep a helpdesk note ready for the Finance go-live window.

---

## 10. Go/No-Go Summary

1. Go from Ring 0 to Ring 1 only if pilot telemetry is healthy.
2. Go from Ring 1 to Ring 2 only if Finance is stable and no Sev-1 issue exists.
3. Go to Ring 4 only after the standard fleet is stable.
4. Stop and rollback if the deployment creates user impact that exceeds the agreed tolerance.

---

## 11. Final Target State

1. All 10,000 endpoints should either have v3.1 installed or be documented exceptions.
2. Finance must be complete within Week 1.
3. Low-spec devices must not be forced into the broad rollout before they are validated.
4. v3.0 must remain available until the rollout is fully stable.
