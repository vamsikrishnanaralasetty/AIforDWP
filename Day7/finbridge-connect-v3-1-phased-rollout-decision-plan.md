# FinBridge Connect v3.1 Phased Rollout Decision Plan

**App:** FinBridge Connect v3.1 (.intunewin package already in Intune app catalog)  
**Rollback app/version:** FinBridge Connect v3.0 in the catalog  
**Target estate:** 10,000 Windows 11 endpoints  
**Business constraint:** Finance needs access by end of Week 1 for 500 users  
**At-risk hardware:** 5% of devices have 4 GB RAM and may struggle with v3.1

---

## 1. RING STRUCTURE

### Ring 1 - Pilot
- Size: 100 devices
- Duration: 3 business days minimum, 5 business days maximum
- Who to include:
  - IT support and endpoint engineering devices
  - A small number of Finance power users who can tolerate test deployment risk
  - A mix of standard Win11 hardware, but no deliberate focus on low-spec devices
- Purpose:
  - Validate install, detection, performance, and uninstall behavior before wider exposure
  - Confirm the Intune registry-based detection rule returns Installed only when v3.1 is truly present
- Intune assignment group type:
  - Azure AD device group, ideally static or tightly controlled dynamic group for pilot devices

### Ring 2 - Early
- Size: 500 users/devices for Finance priority, plus 900 to 1,000 additional non-Finance test-friendly endpoints if needed to keep the ring representative
- Duration: 4 business days minimum, 5 business days maximum
- Who to include:
  - Finance users who require the app by end of Week 1
  - A controlled sample of standard business users from stable departments
  - Exclude the 4 GB RAM cohort from this ring
- Purpose:
  - Meet the Finance deadline while still keeping rollout volume small enough to observe problems quickly
  - Confirm the app behaves correctly under real Finance workload before broad deployment
- Intune assignment group type:
  - User group for Finance users, plus a separate device group for the non-Finance early-wave endpoints if included

### Ring 3 - Broad
- Size: remaining standard devices after Rings 1 and 2, approximately 8,500 devices minus any excluded low-spec cohort
- Duration: 5 business days minimum, 8 business days maximum
- Who to include:
  - Standard Win11 endpoints that are not 4 GB RAM devices
  - Business units with no known compatibility warning from Ring 2
- Purpose:
  - Scale to the majority of the fleet once the install path, detection rule, and user experience have been proven
- Intune assignment group type:
  - Large Azure AD device group, preferably dynamic by device attributes or managed corporate device scope

---

## 2. ADVANCE CRITERIA

### Ring 1 to Ring 2
Evaluate only after the Ring 1 monitoring window has completed.

- Install success rate:
  - Minimum 95% successful installs across Ring 1 devices in the first 72 hours
  - Observable in Intune app install status as Installed divided by total targeted devices
- Error rate threshold:
  - Maximum 3% Failed status across Ring 1 in the same 72-hour window
  - Count only devices that are actually targeted and eligible
- User-reported issues:
  - Maximum 2 helpdesk tickets per 100 targeted devices within the first 72 hours
  - Tickets must be tagged to FinBridge Connect v3.1 or a clear install/launch issue
- Monitoring period:
  - Minimum 72 hours from first Ring 1 deployment before advancement is considered

Advance only if all four criteria are met.

### Ring 2 to Ring 3
Evaluate only after Ring 2 has run long enough to cover first-use and day-two issues.

- Install success rate:
  - Minimum 97% successful installs across Ring 2 devices in the first 96 hours
  - Observable in Intune device or user install reports
- Error rate threshold:
  - Maximum 2% Failed status across Ring 2 in the same 96-hour window
- User-reported issues:
  - Maximum 1 ticket per 100 targeted devices within the first 96 hours
  - Tickets must be specific to app install, launch, or post-install crash behavior
- Monitoring period:
  - Minimum 96 hours from first Ring 2 deployment before advancement is considered

Advance only if all four criteria are met.

### Hold condition, without full rollback
Pause progression to the next ring if either of the following occurs during a ring:
- Failed status reaches 4% to 7% but remains below rollback threshold
- User ticket rate exceeds the ring threshold by up to 50% for less than 24 hours

Specific example:
- If Ring 2 shows 6 Failed devices out of 150 targeted devices in the first 48 hours, and the failures are all on one hardware model, hold Ring 2, stop new assignments to Ring 3, and investigate the model-specific issue without reverting the whole tenant to v3.0.

Hold action:
- Freeze the next-ring assignment group only
- Keep current ring active while root cause is investigated
- Do not change the app version unless a rollback trigger is met

---

## 3. ROLLBACK TRIGGERS

### Install failure rate trigger
- Threshold:
  - 10% or higher Failed status in any ring within 48 hours of assignment start
- Action:
  - Halt all further v3.1 assignments immediately
  - Begin rollback planning for affected rings
- Decision maker:
  - Endpoint deployment owner with service desk and application owner input
- Decision window:
  - Within 2 business hours of threshold breach
- Exact Intune rollback action:
  - Remove the affected ring assignment group from the v3.1 Required assignment
  - Add the same group to the v3.0 Required assignment in Intune
  - Trigger device sync or policy refresh for targeted endpoints

### Application crash rate trigger
- Threshold:
  - 5% or higher app crash reports within 24 hours on a ring, measured by endpoint telemetry, service desk correlation, or app monitoring data where available
- Action:
  - Pause the rollout and open rollback consideration immediately
- Decision maker:
  - Application owner in consultation with endpoint engineering and Finance representative if Finance is affected
- Decision window:
  - 4 hours from trigger identification
- Exact Intune rollback action:
  - Stop new v3.1 assignments for the affected ring
  - Move the affected group from v3.1 Required to v3.0 Required
  - Keep the uninstall assignment off unless v3.1 must be forcibly removed before v3.0 installation

### Business-critical failure trigger
- Immediate rollback scenario:
  - Finance users cannot launch the application at all during business hours after deployment, blocking transactions or time-sensitive work
- Action:
  - Immediate halt and rollback, regardless of percentage
- Decision maker:
  - Finance service owner or delegated business owner, with deployment owner executing the change
- Decision window:
  - 1 hour maximum from confirmation
- Exact Intune rollback action:
  - Remove Finance from v3.1 Required assignment
  - Assign Finance to v3.0 Required immediately
  - Force sync the Finance devices or users

### 4 GB RAM device failure trigger
- Threshold:
  - 20% or higher failure rate within the dedicated low-spec hardware group during the first 72 hours of that ring
- Action:
  - Isolate the 4 GB RAM ring from the main rollout path
  - Do not expand low-spec devices into broader rings until the issue is resolved
- Decision maker:
  - Endpoint engineering lead
- Decision window:
  - 1 business day
- Exact Intune rollback action:
  - Remove the low-spec dynamic group from v3.1 Required assignment
  - Assign the low-spec group to v3.0 Required if the business needs continuity
  - Leave the main standard-device rings on v3.1 unless their own thresholds are breached

---

## 4. FINANCE DEADLINE RESOLUTION

### Option A - Compress the pilot to fit Finance into Ring 2 by end of Week 1
- Minimum safe pilot duration:
  - 48 hours, provided the pilot is limited to 25 to 50 highly controlled devices and the install path has already been validated in a lower environment
- Risk introduced:
  - Reduces the time available to catch first-run issues, detection errors, and edge-case failures before Finance is exposed
- Compensating control:
  - Restrict the pilot to IT-controlled devices only
  - Require a same-day review of install status, crash reports, and helpdesk tickets before any Finance assignment starts
  - Keep v3.0 ready for immediate switchback

### Option B - Treat Finance as a separate priority Ring 0 before the main pilot
- Structure:
  - Ring 0 contains only Finance users who need the app by the deadline, sized at 500 users
  - Ring 1 becomes the technical pilot for IT and engineering devices, or Ring 1 can remain the broad pilot after Finance is protected
- Advance conditions for Finance Ring 0:
  - Minimum 97% installed within 72 hours
  - Maximum 2% Failed status within 72 hours
  - Maximum 1 user ticket per 100 Finance users within 72 hours
  - No business-critical outage during the Finance window
- Own rollback plan:
  - If Finance cannot work normally, remove Finance from v3.1 Required and assign Finance to v3.0 Required immediately
  - Decision window: 1 hour maximum from confirmation of the business impact
  - Execute the rollback in Intune by changing Finance assignment from v3.1 to v3.0 and forcing sync

### Recommendation
- Choose Option B.
- Justification:
  - Finance has a hard Week 1 deadline and business-critical priority, so it should not wait for a longer general pilot cycle.
  - A separate Finance-first ring isolates business urgency from technical validation and reduces the chance that pilot learning delays the deadline.
  - This approach keeps the broader pilot meaningful while still protecting the Finance outcome, and it makes rollback clear if the app disrupts financial work.

---

## Decision Summary

1. Use a dedicated Finance priority Ring 0 as the first production exposure.
2. Keep the technical pilot tightly controlled and independent of the Finance deadline.
3. Advance only on measurable Intune reporting thresholds and fixed time windows.
4. Roll back to v3.0 immediately for Finance outage, high failure rate, or broad app crash evidence.
