# Deployment Plan: FinBridge Connect v3.1 (Intune .intunewin)

| Field | Detail |
|---|---|
| **Title** | FinBridge Connect v3.1 Enterprise Rollout Plan |
| **Version** | 1.0 |
| **Date** | 11/08/2026 |
| **Author** | Copilot |
| **Reviewed by** | Pending |
| **Status** | Draft |
| **Change** | Initial deployment plan |

---

**Application:** FinBridge Connect v3.1 (`.intunewin`)  
**Target fleet:** 10,000 Windows 11 endpoints  
**Previous version:** v3.0 (stable in prior rollout)  
**Rollback package available:** v3.0 in Intune app catalog  
**Primary detection rule:** Registry version string  
**Deadline:** 3 weeks from plan start (target completion by 01/09/2026)

---

## 1. Objectives and Non-Negotiables

### Business objectives
- Deliver v3.1 to all 10,000 endpoints within 3 weeks.
- Complete highest-priority Finance deployment (500 users) by end of Week 1.
- Protect user productivity by limiting failed installs and rollback impact.

### Technical non-negotiables
- No broad assignment to low-spec (4 GB RAM) devices until validated in pilot.
- Detection rule must uniquely distinguish v3.1 from v3.0 and stale registry data.
- Rollback to v3.0 must be tested before any production ring expansion.

---

## 2. Assumptions and Constraints

| Constraint | Impact | Required control |
|---|---|---|
| Finance users need app by end of Week 1 | Aggressive schedule for first 500 users | Dedicated fast-track ring and daily checkpoints |
| 5% of devices have older hardware (4 GB RAM) | Higher risk of poor performance or install timeout | Separate low-spec ring, slower cadence, stricter success gate |
| v3.0 rollout had no major issues | Lower baseline deployment risk | Reuse proven assignment model where possible |
| Registry-only detection rule | Risk of false positives from stale key/value | Add strict version/value/path checks and remediation script |

---

## 3. Ring Strategy

| Ring | Population | Approx count | Start | Exit criteria |
|---|---|---:|---|---|
| Ring 0 - IT Pilot | IT engineering + support devices | 100 | Day 1 | >= 98% install success; no critical defect |
| Ring 1 - Finance Priority | Finance users | 500 | Day 3 | >= 97% success and no Sev-1 business outage |
| Ring 2 - General Wave A | Broad business users (excluding low-spec) | 3,500 | Week 2 | >= 97% success, helpdesk volume stable |
| Ring 3 - General Wave B | Broad business users (excluding low-spec) | 4,900 | Week 2/3 | >= 97% success, no unresolved Sev-1/Sev-2 trend |
| Ring 4 - Low-Spec Devices | 4 GB RAM endpoints across business units | 1,000 | Week 3 | >= 95% success, performance within acceptance |

Total endpoints across all rings: 10,000

---

## 4. Timeline (3 Weeks)

## Week 1 (11/08/2026 to 17/08/2026)
- Day 1:
  - Validate install, uninstall, repair, and detection logic in pre-prod tenant or pilot scope.
  - Execute rollback test from v3.1 to v3.0 on at least 10 devices.
- Day 2:
  - Deploy Ring 0 (100 devices).
  - Monitor first 4-hour and 24-hour telemetry checkpoints.
- Day 3:
  - Go/No-Go for Finance rollout based on Ring 0 metrics.
  - Deploy Ring 1 (Finance 500).
- Day 4-5:
  - Finance stabilization window and hotfix handling.
  - Daily incident review with Service Desk and Finance stakeholder.

Week 1 hard checkpoint:
- Finance must be at or above 97% successful deployment by 17/08/2026 EOD.

## Week 2 (18/08/2026 to 24/08/2026)
- Deploy Ring 2 in staged batches (for example 1,500 then 2,000).
- If stable for 24 hours after final Ring 2 batch, deploy Ring 3 first half.
- Perform low-spec readiness validation in parallel (performance and stability checks).

## Week 3 (25/08/2026 to 01/09/2026)
- Complete Ring 3 remaining devices.
- Deploy Ring 4 (low-spec) in smaller daily batches.
- Reserve final 2 business days for exceptions, retries, and rollback cleanup.

---

## 5. Intune Configuration Guidance

### App deployment settings
- Use required deployment for ring-based Entra ID groups.
- Configure assignment filters to exclude low-spec devices from Rings 1-3.
- Enable restart behavior aligned with business hours policy.

### Detection rule hardening
Current method: registry version string check.

Recommended detection conditions for v3.1:
- Validate exact registry path.
- Validate exact value name.
- Validate exact semantic version string `3.1.x` (not substring match only).
- Confirm app executable version file metadata when possible as secondary validation.

Example logic (conceptual):
- Detect Installed only when:
  - Registry key exists
  - Version value exists
  - Version equals expected v3.1 build

### Requirements and low-spec control
- Add requirement rule to block or defer installation for devices below approved minimum spec if supported by app requirements.
- Create a dedicated dynamic group for 4 GB RAM devices for Ring 4 controlled rollout.

---

## 6. Monitoring and Operational Metrics

Track these metrics per ring at 4h, 24h, and 48h:
- Install success rate
- Install failure rate by error code
- Average install duration
- App launch success post-install
- Crash rate (if telemetry available)
- Service Desk ticket volume related to FinBridge

Go/No-Go thresholds:
- Proceed to next ring only if:
  - No active Sev-1 incident
  - Success rate meets ring threshold
  - No sustained increase in high-severity tickets

---

## 7. Rollback Plan (v3.0)

Rollback trigger examples:
- Sev-1 business outage in Finance or broad user impact
- Install success drops below 90% for any major ring
- Critical defect in v3.1 core transaction flow

Rollback actions:
1. Pause v3.1 assignments for active and pending rings.
2. Assign v3.0 required to affected rollback scope.
3. Force re-evaluation cycle on impacted devices.
4. Validate app launch and key business transactions.
5. Communicate status updates to stakeholders every 2 hours until stable.

Rollback validation minimum:
- Test on 20 devices including at least 5 low-spec endpoints.

---

## 8. Communications Plan

### Audience: Finance leadership and user champions
- Daily Week 1 status update (adoption %, issues, mitigation ETA).
- Immediate notification for any Sev-1 or rollback trigger.

### Audience: Service Desk
- Known issue list and troubleshooting script.
- Escalation matrix for v3.1 install failures and performance complaints.

### Audience: Engineering and endpoint operations
- Twice-daily deployment dashboard review during active rollout.
- Single incident bridge for P1/P2 issues.

---

## 9. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Detection false positive due to stale registry value | Medium | High | Harden rule + add secondary file version check |
| Low-spec devices experience poor performance | High | Medium/High | Isolated ring, smaller batches, monitored rollback |
| Finance user disruption in Week 1 | Medium | High | Dedicated ring, daily hypercare, fast rollback option |
| Unexpected dependency conflict on subset of endpoints | Low/Medium | Medium | Ringed rollout with hold points and rapid incident triage |

---

## 10. Execution Checklist

Pre-deployment:
- [ ] Validate installer command line and silent switches.
- [ ] Validate detection rule with clean install, upgrade, and stale-key scenarios.
- [ ] Validate rollback from v3.1 to v3.0.
- [ ] Build ring-based Entra ID groups and assignment filters.
- [ ] Publish Service Desk knowledge notes.

During deployment:
- [ ] Confirm each ring Go/No-Go decision in change record.
- [ ] Review telemetry checkpoints (4h/24h/48h).
- [ ] Update stakeholder comms at planned cadence.

Post-deployment:
- [ ] Confirm 10,000 endpoint completion or documented exceptions.
- [ ] Close outstanding incidents and exception backlog.
- [ ] Capture lessons learned for next release cycle.

---

## 11. Decision Summary for This Scenario

Recommended approach:
- Start with a small IT pilot, then fast-track Finance in Week 1.
- Delay low-spec endpoints to final ring with tighter success criteria.
- Treat detection-rule hardening and rollback validation as mandatory before Finance deployment.
- Use v3.0 rollback quickly if Finance stability is threatened.
