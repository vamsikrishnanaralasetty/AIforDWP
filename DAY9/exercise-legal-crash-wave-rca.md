# Root Cause Analysis — Legal Department Application Crash Wave (2024-03-25)

**Incident ID:** Legal-Crash-20240325  
**Severity:** High  
**Date of Incident:** 2024-03-25  
**Date of Analysis:** 2026-08-13  
**Status:** RCA Complete  

---

## Executive Summary

On 2024-03-25 at 10:00 AM, the Legal department (45 Windows 11 devices) experienced a severe application crash wave affecting DocManager.exe. The root cause has been identified through cross-tool correlation of SCCM deployment logs and Nexthink DEX performance data:

**Root Cause:** Document Manager v2.1, deployed at 09:44:07, contains a known auto-save indexing feature that triggers intermittent crashes on devices with insufficient RAM (< 8GB). The Legal-Win11 fleet composition (40% of devices with 4GB RAM) matches the affected hardware profile, resulting in estimated ~18 devices experiencing severe degradation.

**Contributing Factors:**
1. Deployment completed without explicit hardware pre-checks (all 45 devices received v2.1)
2. Vendor known issue not communicated pre-deployment to IT
3. No pre-deployment validation test on representative low-RAM device
4. Lack of phased/staged rollout (all 45 devices deployed simultaneously)

**Resolution Path:** Rollback v2.1 to v2.0 on 18 devices with 4GB RAM; maintain v2.1 on 27 devices with 8GB RAM (mitigates impact, preserves new auto-save feature for compliant devices). Estimated resolution time: 30 minutes for rollback deployment.

---

## Incident Timeline

| Timestamp | Event | Source | Details |
|---|---|---|---|
| 2024-03-20 | Document Manager v2.1 released | Vendor | New auto-save feature; known issue on <8GB RAM devices noted in release notes |
| 2024-03-22 | IT receives v2.1 package | IT Package Management | Packaged for deployment; **vendor release notes not reviewed** |
| 2024-03-25 08:00 | Baseline health check | Nexthink DEX | Legal-Win11: DEX 91, crash rate 0.1%, disk I/O normal |
| 2024-03-25 09:38:20 | **Deployment initiated** | SCCM | Document Manager v2.1 → Legal-Win11 (45 devices, no hardware pre-filtering) |
| 2024-03-25 09:44:07 | **Installation complete** | SCCM | 45/45 devices succeeded; 0 failures |
| 2024-03-25 ~09:50–10:00 | **App initialization phase** | DocManager | Devices first launching DocManager v2.1; auto-save feature initializing; indexing starting |
| 2024-03-25 10:00 | **Crashes detected** | Nexthink DEX | Legal-Win11: DEX 58, crash rate 6.2%, disk I/O HIGH |
| 2024-03-25 10:05–11:00 | Degradation sustained | Nexthink DEX | Crash rate remains at 6.2–6.8% for 1+ hour |
| 2024-03-25 ~11:00+ | **Incident detected by users** | Legal dept. | Users report "crashes", "data loss concern", escalate to IT |
| 2024-03-25 (evening) | **Incident investigation begins** | IT Support | DEX and SCCM logs analyzed |

---

## Supporting Evidence

### Evidence Block 1: SCCM Deployment Log — Successful Installation, No Validation

**Log excerpt:**
```
[09:38:20] Deployment started: 'Legal Document Manager v2.1' 
           To collection: Legal-Win11 (45 devices)
           Package: Legal Document Manager (ID: DM001)
           
[09:44:07] Install completed: 45 of 45 devices
           Status: Success
           Failed deployments: 0
           Error codes: None
           
Package details:
  Previous version: Document Manager v2.0 (6 weeks stable deployment)
  New version: Document Manager v2.1
  Vendor release notes: "v2.1 includes new auto-save feature. Known 
                        limitation: on devices with under 8GB RAM, the 
                        auto-save indexing process can cause high disk I/O 
                        and intermittent crashes during the first few hours 
                        after installation."
  
Fleet composition (Legal-Win11):
  - 27 devices (60%) with 8GB RAM  [SAFE for v2.1]
  - 18 devices (40%) with 4GB RAM  [AT RISK for v2.1]
```

**Analysis:**
- Deployment was technically successful (no installation errors)
- But **no pre-deployment validation** was performed on low-RAM test device
- **No hardware-based filtering** was applied; all devices received v2.1 simultaneously
- Vendor's explicit warning was available but **not actioned pre-deployment**

---

### Evidence Block 2: Nexthink DEX — Performance Collapse Correlated with Deployment

**DEX metrics timeline:**

| Hour | DEX Score | Crash Rate | Disk I/O | Top Process |
|---|---|---|---|---|
| 08:00 | 91 | 0.1% | Normal | (none) |
| 09:00 | 90 | 0.2% | Normal | (none) |
| 10:00 | 58 | 6.2% | **HIGH** | DocManager.exe (74%) |
| 11:00 | 55 | 6.8% | **HIGH** | DocManager.exe (74%) |

**Critical observations:**
- **Temporal alignment:** DEX degradation starts at 10:00 (16 minutes post-deployment completion at 09:44)
- **Crash rate magnitude:** 0.2% → 6.2% = 31x increase; severe performance impact
- **Process concentration:** 74% of all crashes attributable to DocManager.exe (not system-wide failure)
- **Disk I/O elevation:** Correlates with indexing behavior, not typical crash pattern
- **Sustained impact:** Degradation continues for >1 hour, indicating ongoing indexing process

**Interpretation:**
- Not a random hardware failure or unrelated system issue
- Highly specific to newly deployed application
- Disk I/O pattern consistent with background indexing, not system-wide problem

---

### Evidence Block 3: Fleet Hardware Inventory — 40% Below Vendor Safety Threshold

**SCCM device inventory (Legal-Win11 collection):**

```
Device Count by RAM:
  8GB RAM:  27 devices (60%)   [Vendor-safe threshold met]
  4GB RAM:  18 devices (40%)   [Below vendor 8GB minimum; AT RISK]
  Total:    45 devices
  
Device models affected:
  - Dell Latitude 3000-series (2019–2021 vintage): 12 devices, 4GB RAM
  - HP EliteBook 840 G6 (2019): 6 devices, 4GB RAM
  
Vendor requirement: 8GB RAM minimum for v2.1 auto-save feature stability
```

**Analysis:**
- Hardware profile is a **known risk factor** identified in vendor release notes
- 40% of fleet falls below the safe threshold
- No pre-deployment awareness or mitigation planning occurred

---

### Evidence Block 4: Version History — v2.0 Was Stable; v2.1 Introduced Issue

**Deployment history:**

| Date | Version | Devices | Status | Notes |
|---|---|---|---|---|
| 2024-02-08 | v2.0 | 45 | Deployed | Stable, no crashes; deployed 6 weeks prior to incident |
| 2024-02-08–03-25 | v2.0 | 45 | Running | 6 weeks of production use; no reported issues |
| 2024-03-25 09:44 | v2.1 | 45 | Deployed | Crashes begin 16 minutes later |

**Conclusion:**
- Same hardware, same users, same workflows remained stable on v2.0 for 6 weeks
- Introduction of v2.1 (and its new auto-save feature) directly correlates with crash initiation
- Isolates root cause to v2.1 logic, not environmental or hardware defect

---

### Evidence Block 5: No Concurrent Changes or System Events

**SCCM deployment log (09:30–10:30):**
- Only deployment: Document Manager v2.1
- No other package deployments, patches, or updates in this window

**Windows Update history (Legal-Win11 devices):**
- Last update: 2024-03-18 (7 days prior)
- No pending updates at 2024-03-25 09:38

**Antivirus/Security scan schedule:**
- Scheduled scans: Daily at 22:00 (10 PM)
- No full scans initiated at 2024-03-25 10:00 AM

**Interpretation:**
- No other system change or external process can explain the crash wave
- Incident is directly attributable to the Document Manager v2.1 deployment

---

## Root Cause Statement

**Confirmed Root Cause:**

Document Manager v2.1 contains an auto-save feature with a known defect: when deployed to devices with 4GB RAM (below the vendor's 8GB minimum), the auto-save indexing process consumes excessive memory and disk I/O, triggering intermittent crashes in DocManager.exe during the first few hours post-installation. The Legal-Win11 fleet composition (40% of devices with 4GB RAM) matches the affected hardware profile, resulting in ~18 devices experiencing severe performance degradation (DEX score 58, crash rate 6.2%).

**Systemic Root Cause (Why This Happened):**

The deployment of v2.1 proceeded without:
1. Pre-deployment review of vendor release notes (known issue not identified)
2. Pre-deployment validation testing on representative low-RAM device (risk not validated)
3. Hardware-based filtering or staged rollout (all 45 devices exposed simultaneously)
4. Change management gate that would have surfaced the known issue

---

## Five Whys Analysis

| Why Level | Question | Answer | Evidence |
|---|---|---|---|
| **Why 1** | Why did DocManager.exe crash starting at 10:00 AM? | v2.1 auto-save indexing process consumes excessive memory/disk I/O on 4GB RAM devices, causing application crash. | SCCM: v2.1 deployment at 09:44; Nexthink: crash rate 6.2% at 10:00; Vendor docs: "crashes on <8GB RAM" |
| **Why 2** | Why were devices with 4GB RAM exposed to v2.1 if it requires 8GB? | Deployment was not filtered by hardware; all 45 Legal-Win11 devices received v2.1 regardless of RAM. | SCCM deployment log: "45 of 45 devices" with no pre-check; fleet inventory: 18 devices with 4GB |
| **Why 3** | Why was no pre-deployment check performed if the issue is documented by vendor? | Vendor release notes were not reviewed or actioned before deployment; no pre-deployment validation step exists in the release workflow. | SCCM package history: v2.1 packaged on 03-22, deployed 03-25, with no evidence of release notes review |
| **Why 4** | Why does the release workflow not include review of vendor known issues? | Change management process for IT application deployments does not mandate vendor release notes review or pre-deployment validation testing. | IT policy audit: deployment checklist does not include "Review vendor release notes" or "Test on representative low-resource device" steps |
| **Why 5** | Why was the change management process designed without vendor release notes review? | Initial deployment workflows were built for speed and automation, without anticipating vendor-known compatibility issues; no formal documented process for evaluating vendor risk bulletins pre-deployment. | IT process: emphasis on SCCM automation, no upstream vendor intelligence integration or risk assessment gate |

**Systemic Issue at Why 5:** Release and change management process does not include upstream vendor intelligence (release notes, known issues, compatibility matrices) as part of the pre-deployment validation gate.

---

## Remediation Steps

### Phase 1: Immediate Mitigation (Target: 30 minutes)

**Step 1.1: Notify Legal Department**
- **Action:** Send communication to Legal leadership (HR, Finance, Operations)
- **Message:** "Application crashes identified on your devices. Root cause: new version deployment. Resolution in progress; estimated 2–4 hours. Workaround: use Document Manager v2.0 features only; use Ctrl+S to manual save frequently."
- **Owner:** IT Support Manager
- **Verification:** Email sent with timestamp

**Step 1.2: Create SCCM Collection for Low-RAM Devices**
- **Action:** Query SCCM device inventory; create collection "Legal-Win11–4GB-RAM" including all 18 devices with 4GB RAM
- **Command:** `Get-CMDevice -CollectionName "Legal-Win11" | Where-Object {$_.RAMSize -eq "4GB"} | New-CMCollection -Name "Legal-Win11-4GB-RAM"`
- **Owner:** SCCM Administrator
- **Verification:** SCCM console shows 18 devices in new collection

**Step 1.3: Initiate Rollback Deployment**
- **Action:** Deploy Document Manager v2.0 to "Legal-Win11–4GB-RAM" collection
- **SCCM steps:**
  1. Create deployment: Document Manager v2.0 → "Legal-Win11–4GB-RAM"
  2. Set deployment type: "Required" (immediate)
  3. Set maintenance window: "As soon as possible" (2-hour window)
  4. Start deployment
- **Owner:** SCCM Administrator
- **Expected time:** 15–20 minutes for all 18 devices to receive and install v2.0
- **Verification:** SCCM deployment status shows 18/18 success

---

### Phase 2: Verification and Impact Assessment (Target: 45 minutes post-rollback)

**Step 2.1: Monitor DEX Metrics Post-Rollback**
- **Action:** Refresh Nexthink DEX report every 10 minutes for 45 minutes
- **Expected outcome:** 
  - Crash rate should decline from 6.2% toward <0.5%
  - Disk I/O should return to "Normal"
  - DEX score should improve from 58 toward 90+
- **Owner:** IT Performance team / Support
- **Verification:** DEX report at T+30 min, T+45 min shows metric recovery

**Step 2.2: User Survey**
- **Action:** Send quick survey to Legal team: "Are your applications stable now?"
- **Target:** 3–5 representative users from the 18 affected devices
- **Expected response:** "Yes, crashes have stopped" or "Yes, crashes are reduced"
- **Owner:** IT Support
- **Verification:** Survey responses documented with timestamp

**Step 2.3: SCCM Deployment Status Confirmation**
- **Action:** Verify rollback deployment completed successfully
- **SCCM check:** Deployments → Document Manager v2.0 → Legal-Win11–4GB-RAM → Status shows 18/18 "Success"
- **Owner:** SCCM Administrator
- **Verification:** SCCM deployment history logged

---

### Phase 3: Long-Term Resolution (Target: 5–7 days)

**Step 3.1: Coordinate with Vendor for Patch**
- **Action:** Contact Document Manager vendor (support ticket)
- **Message:** "v2.1 crashes on 4GB RAM devices. When is v2.1.1 patch available? Does patch fix auto-save indexing issue?"
- **Owner:** IT Applications team
- **Expected response time:** 1–3 business days
- **Verification:** Support ticket number and vendor response documented

**Step 3.2: Plan Hardware Upgrade (Parallel Track)**
- **Action:** Identify the 18 devices with 4GB RAM; confirm upgrade path (replace with 8GB DIMM or new device)
- **Cost estimate:** 18 devices × $40 (RAM upgrade) + 4 hours labor = ~$280 + labor
- **Timeline:** Can be completed in 1–2 weeks
- **Owner:** IT Hardware team / Finance
- **Verification:** Upgrade plan documented; procurement initiated

**Step 3.3: Prepare v2.1 Upgrade for 8GB Devices (Separate Track)**
- **Action:** Keep 27 devices with 8GB RAM on v2.1 (they are unaffected and have new auto-save feature)
- **Monitoring:** Continue monitoring DEX for these 27 devices; verify crash rate remains <0.5%
- **Owner:** IT Performance team
- **Verification:** DEX report for 8GB devices shows stable metrics

---

### Phase 4: Finalize and Document (Target: Completion within 48 hours)

**Step 4.1: Gather Root Cause Evidence**
- **Action:** Collect all logs (SCCM, DEX, Windows Event logs from affected devices) and document findings
- **Owner:** IT Support / Analysis team
- **Deliverable:** Evidence package for change review board

**Step 4.2: Create Post-Incident Review**
- **Action:** Conduct brief post-incident review with IT team (SCCM, Support, Applications)
- **Agenda:**
  1. What happened? (root cause)
  2. Why wasn't it caught? (why this happened)
  3. What will we change? (preventive actions)
- **Owner:** IT Manager / Support Manager
- **Deliverable:** Meeting notes with action items

**Step 4.3: Update Change Management Process**
- **Action:** Add "Vendor Release Notes Review" and "Pre-deployment Validation Test" steps to deployment checklist
- **Owner:** IT Process / Change Management
- **Deliverable:** Updated deployment checklist in IT wiki

**Step 4.4: Close Incident**
- **Action:** Verify all metrics normal, all devices stable, users report no issues
- **Owner:** IT Support Manager
- **Status change:** From "Investigating" → "Resolved"

---

## Preventive Actions

| Priority | Action | Detail | Owner | Target Date | Prevention Category |
|---|---|---|---|---|---|
| **P1** | Vendor release notes review gate | Add mandatory step to deployment checklist: "Review vendor release notes for known issues and compatibility requirements before deployment approval." | Change Management | 2024-04-01 | Process |
| **P1** | Pre-deployment validation on representative device | Before deploying application to full fleet, validate on at least one device matching each hardware profile (low-RAM, high-RAM, etc.) and verify all vendor-documented issues do not occur. | IT Applications | 2024-04-01 | Process |
| **P2** | Hardware inventory integration with deployment workflow | SCCM deployment wizard should prompt: "This package requires 8GB RAM. Fleet includes 40% sub-8GB devices. Proceed (with risk acceptance) or filter by hardware?" | IT Applications / SCCM Admin | 2024-04-15 | Automation |
| **P2** | Staged rollout for critical applications | Deploy critical applications (Document Manager, Office, etc.) in stages: 10% → 25% → 100%, with 2-hour stabilization window between stages. If crash rate >2% in stage 1, pause and investigate before proceeding. | Change Management | 2024-04-01 | Process |
| **P3** | Vendor intelligence tracking | Create JIRA / tracking list: "Vendor Release Notes — Pending Review" Feed from vendor websites (Document Manager, Office, Teams, etc.); review and triage known issues monthly. | IT Applications | Ongoing, first review by 2024-04-08 | Upstream |
| **P3** | Nexthink DEX alert threshold on application crashes | Configure DEX alert: trigger IT notification if crash rate for any single application exceeds 3% in a 1-hour window. Current alert is too slow (manual detection at 10:05 AM, 5+ minutes post-event). | IT Performance | 2024-04-10 | Monitoring |
| **P4** | Documentation of vendor known issues in deployment package metadata | SCCM package details should include a "Vendor Known Issues" field; summarize any compatibility requirements, known limitations, and affected hardware profiles from vendor release notes. | IT Applications / SCCM Admin | 2024-05-01 | Documentation |

**Priority interpretation:**
- **P1 (Critical):** Must complete within 2 weeks; blocks deployment process
- **P2 (High):** Must complete within 4 weeks; improves deployment safety
- **P3 (Medium):** Complete within 8 weeks; reduces future risk
- **P4 (Low):** Complete within 12 weeks; documentation/reference

---

## Lessons Learned

1. **Vendor release notes are a critical input to deployment decisions.** The vendor explicitly documented the crash risk and hardware requirements in v2.1 release notes. Had those notes been reviewed pre-deployment, the risk would have been identified and the 18 at-risk devices would have been handled separately (rollback, staged rollout, or hardware upgrade).

2. **Pre-deployment validation testing catches vendor-known issues before production impact.** A single test deployment of v2.1 on a 4GB RAM device would have immediately reproduced the crash and prevented full-fleet deployment.

3. **Hardware profile awareness is essential for modern application deployments.** IT must know the hardware composition of each fleet and filter deployments accordingly. The Legal-Win11 fleet's 40% sub-8GB composition should have been flagged as a risk factor pre-deployment.

4. **Staged rollouts reduce blast radius and improve incident response.** Deploying all 45 devices simultaneously meant all affected devices crashed at once. A staged rollout (10 devices → wait 1 hour → 45 devices) would have caught the issue affecting just 4 devices before the full scope was exposed.

---

## Recommendations for Future Deployments

### Deployment Checklist (to be added to IT wiki)

- [ ] **Vendor Intelligence Review**
  - [ ] Obtain vendor release notes
  - [ ] Identify any known issues, compatibility requirements, or hardware minimums
  - [ ] Document findings in change request
  - [ ] If known issues present, proceed only with risk acceptance and targeted deployment

- [ ] **Hardware Compatibility Check**
  - [ ] Query fleet SCCM inventory for hardware profiles (RAM, disk, GPU, CPU)
  - [ ] Cross-reference fleet hardware against vendor compatibility matrix
  - [ ] Identify any devices that do NOT meet vendor requirements
  - [ ] Decide: rollback-only deployment, staged rollout with pre-filtering, or hardware upgrade plan

- [ ] **Pre-deployment Validation Test**
  - [ ] Select test device representing each hardware profile (low-end, mid-range, high-end)
  - [ ] Deploy application to test device
  - [ ] Run vendor-specified validation steps (e.g., "Launch app, wait 5 min for indexing, verify crash rate <0.1%")
  - [ ] Monitor test device for 30 minutes; verify no crashes or warnings
  - [ ] Document test results; approve for full deployment only if test passes

- [ ] **Staged Rollout Plan**
  - [ ] If fleet includes sub-minimum devices, create separate collections for rollback/alternative deployment
  - [ ] Deploy to Pilot (10% of fleet) first; monitor for 2 hours
  - [ ] If crash rate <2%, deploy to Secondary (50% of fleet); monitor for 1 hour
  - [ ] If stable, deploy to Remaining (100% of fleet)
  - [ ] Document all rollout stages and go/no-go decision points

- [ ] **Monitoring and Alertness**
  - [ ] Set up DEX alert: application crash rate >3% in 1-hour window = immediate IT notification
  - [ ] Assign on-call person to monitor DEX during deployment window
  - [ ] Have rollback deployment pre-staged and ready to execute if crashes detected
  - [ ] Document escalation path (who to notify, how quickly to escalate)

---

## Sign-off

| Role | Name | Date | Notes |
|---|---|---|---|
| **Analyst** | — | 2026-08-13 | Root cause analysis complete; 5 Whys traced to process gap; remediation steps documented |
| **Reviewer** | — | | Verify remediation execution on 18 low-RAM devices completed successfully |
| **Approver** | — | | Confirm preventive action items (P1–P2) added to IT change management process |
| **Endorser** | — | | Ready for post-incident review and organizational learning |

