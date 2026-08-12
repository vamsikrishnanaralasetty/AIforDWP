# Copilot for Microsoft 365 — Readiness Assessment: Finance Department

| Field | Detail |
|---|---|
| **Title** | Copilot for M365 Readiness Assessment — Finance |
| **Version** | 1.0 |
| **Date** | 12/08/2026 |
| **Author** | Copilot |
| **Reviewed by** | Pending |
| **Status** | Draft |
| **Scope** | Finance department, ~200 users |

---

**Department:** Finance  
**Users in scope:** ~200  
**Licensing:** M365 E5 confirmed; Copilot add-on not yet assigned  
**Data sensitivity:** High — payroll, board packs, M&A documents, client financial data  
**SharePoint posture:** Inherited permissions from 2019 migration; no full audit since  

---

## 1. Purpose and Scope

This document assesses the Finance department's readiness to receive Microsoft Copilot for M365 licences. It identifies gaps that must be closed before the add-on is assigned, defines the remediation sequence, and sets go/no-go criteria.

Copilot for M365 operates on the Microsoft Graph and surfaces information the user is already permitted to access — including SharePoint, Teams, Exchange, and OneDrive. In a department handling payroll, M&A, and board materials, **existing over-permissioning is directly amplified by Copilot**. A user who can technically read a document they should not see today is unlikely to find it manually. With Copilot, they can retrieve it in a single prompt. This makes permission hygiene a prerequisite, not an afterthought.

---

## 2. Current-State Summary

| Dimension | Current State | Risk Level |
|---|---|---|
| Licensing (E5) | Confirmed, all 200 users | None |
| Copilot add-on | Not assigned | Blocking — do not assign until gates cleared |
| SharePoint permissions | Inherited from 2019 migration, unaudited | **Critical** |
| Data classification / sensitivity labels | Unknown — to confirm | High |
| DLP policies covering Finance data | Unknown — to confirm | High |
| Purview audit logging | Unknown — to confirm | Medium |
| Conditional Access / MFA | Unknown — to confirm | Medium |
| End-user AI literacy | Unknown — to confirm | Medium |

---

## 3. Gap Analysis

### 3.1 SharePoint Permission Inheritance (Critical)

**Problem:** Permissions set during a 2019 migration are likely broken inheritance chains, outdated group memberships, and broad "everyone" or "all staff" access applied to site collections or document libraries that now hold highly sensitive Finance content.

**Why this is critical for Copilot:** Copilot respects Graph permissions. It does not add access, but it does make existing access trivially exploitable. A misconfigured permission that was unlikely to be noticed manually becomes instantly reachable via natural language query.

**Required actions before licence assignment:**
1. Run a SharePoint permissions report across all Finance-owned site collections (use SharePoint Admin Centre > Reports, or PnP PowerShell `Get-PnPSiteCollectionPermissions`).
2. Identify and break any site-level inheritance chains that grant access beyond the intended Finance sub-group.
3. Enumerate all "Everyone", "Everyone except external users", and broad AD security group assignments; remove or tighten each one.
4. Confirm that M&A and board pack libraries use dedicated, named security groups with no inherited site-level access.
5. Document the intended access model per library or site section and obtain sign-off from the Finance Director and Information Security.
6. Re-run the permissions report after remediation to confirm all overpermissioned accounts are resolved.

**Owner:** SharePoint/M365 Admin  
**Estimated effort:** 3–5 days depending on volume of site collections

---

### 3.2 Sensitivity Labels and Data Classification (High)

**Problem:** Without Microsoft Purview sensitivity labels applied to Finance content, Copilot has no awareness of document classification, and DLP policies cannot enforce protection at the content level.

**Required actions:**
1. Confirm whether a Purview sensitivity label taxonomy exists for the organisation.
2. If not, define a minimum label set covering Finance data: at minimum `Confidential`, `Highly Confidential — Finance`, and `Restricted — M&A`.
3. Enable auto-labelling policies targeting SharePoint Finance sites and OneDrive accounts for known Finance users.
4. Apply default labels to Finance SharePoint libraries (site-level default label in SharePoint library settings).
5. Run a content scan (Purview Information Protection scanner or SharePoint content search) to identify unlabelled high-sensitivity documents.

**Owner:** Information Security / Compliance team  
**Estimated effort:** 1–2 weeks to define, publish, and propagate labels; longer if a new taxonomy must be approved

---

### 3.3 Data Loss Prevention (DLP) Policies (High)

**Problem:** DLP policies need to cover Finance data in SharePoint, Teams messages, and Exchange/Outlook — all surfaces Copilot can read and generate from.

**Required actions:**
1. Confirm existing DLP policies in Purview compliance portal.
2. Ensure policies apply to SharePoint Finance site collections and OneDrive for Finance users.
3. Add or update rules to detect financial sensitive information types: payroll data, UK bank account numbers, company financial identifiers.
4. Set policy mode to `Enforce` (not audit-only) before Copilot is assigned.
5. Test policies against known sensitive documents to confirm detection is firing correctly.

**Owner:** Compliance / Information Security  
**Estimated effort:** 3–5 days if policies already exist and need tuning; 1–2 weeks if building from scratch

---

### 3.4 Purview Audit Logging (Medium)

**Problem:** Once Copilot is active, all Copilot interactions are logged in the Purview audit log (M365 E5 includes Audit Premium). This must be confirmed as enabled before go-live to ensure post-incident traceability.

**Required actions:**
1. Confirm audit logging is turned on in Purview compliance portal (Audit > Start recording user and admin activity).
2. Enable Copilot-specific audit events: `CopilotInteraction` events will appear once the add-on is assigned.
3. Confirm retention period meets Finance/regulatory requirements (Audit Premium supports up to 1-year default, extendable to 10 years with add-on).

**Owner:** Compliance / M365 Admin  
**Estimated effort:** 1 day to confirm and configure

---

### 3.5 Conditional Access and MFA (Medium)

**Problem:** Copilot add-on must only be accessible from compliant, managed devices. Confirm that the Finance cohort is fully covered by Conditional Access policies requiring MFA and device compliance.

**Required actions:**
1. In Entra ID (Azure AD) Conditional Access, confirm a policy is scoped to the Finance group requiring MFA and Intune-compliant device.
2. Check that all 200 Finance users are members of the target group and have MFA registered.
3. Confirm devices are Intune-compliant (no non-compliant devices flagged in Endpoint Manager for Finance users).
4. Optionally, scope the Copilot licence assignment to a security group first, and ensure only that group is allowed.

**Owner:** Identity / Security team  
**Estimated effort:** 1–2 days to audit and remediate any gaps

---

### 3.6 End-User AI Literacy and Acceptable Use (Medium)

**Problem:** Finance users handling sensitive data need to understand how Copilot works, what it can and cannot do with their data, and the organisation's acceptable use policy before they start using it.

**Required actions:**
1. Define an acceptable use policy for Copilot for M365 covering Finance-specific scenarios (e.g., do not use Copilot to draft communications that include raw payroll figures unless reviewed; do not prompt Copilot to summarise M&A documents for external sharing).
2. Create a short (15–20 minute) Finance-specific onboarding guide covering: what Copilot can access, what to avoid prompting, how to report unexpected output.
3. Run a pre-go-live awareness session or short e-learning for all 200 users.
4. Establish a feedback channel (ServiceNow category or shared mailbox) for users to report Copilot concerns.

**Owner:** IT / Change Management  
**Estimated effort:** 1 week to prepare materials; schedule sessions during licence rollout

---

## 4. Recommended Remediation Sequence

```
Phase 1 — Permission Hygiene (Week 1–2)
  └─ SharePoint permissions audit and clean-up
  └─ Remove overpermissioned groups from Finance site collections
  └─ Confirm M&A / board pack libraries are access-controlled

Phase 2 — Data Classification and DLP (Week 2–3)
  └─ Define or align sensitivity label taxonomy
  └─ Apply labels to Finance SharePoint sites (default + auto-label)
  └─ Confirm and enforce DLP policies across SharePoint, Teams, Exchange

Phase 3 — Technical Controls (Week 3)
  └─ Confirm audit logging is active
  └─ Verify Conditional Access and MFA for all 200 users
  └─ Confirm Intune device compliance

Phase 4 — User Readiness (Week 3–4, parallel with Phase 3)
  └─ Publish acceptable use policy
  └─ Deliver onboarding awareness session
  └─ Stand up feedback/reporting channel

Phase 5 — Pilot Licence Assignment (Week 4–5)
  └─ Assign Copilot add-on to a pilot group (~20 users — Finance IT champions)
  └─ Monitor Copilot audit events, DLP alerts, and user feedback for 1 week
  └─ No Sev-1 or permission-related incident in pilot period → proceed to full rollout
```

---

## 5. Go / No-Go Criteria

All of the following must be confirmed before the Copilot add-on is assigned to any Finance user.

| Gate | Requirement | Status |
|---|---|---|
| P-01 | SharePoint permissions audit complete and all critical findings remediated | To confirm |
| P-02 | No "Everyone" or unintended broad-group access on Finance site collections | To confirm |
| P-03 | Sensitivity labels published and auto-labelling enabled on Finance SharePoint sites | To confirm |
| P-04 | DLP policies set to Enforce mode and tested against Finance content | To confirm |
| P-05 | Purview audit logging confirmed active; Copilot audit events enabled | To confirm |
| P-06 | All 200 Finance users covered by Conditional Access policy (MFA + compliant device) | To confirm |
| P-07 | Acceptable use policy published and Finance Director sign-off obtained | To confirm |
| P-08 | Pre-go-live user awareness session scheduled | To confirm |

**Decision:** Do not assign the Copilot add-on until all P-01 through P-08 are marked Confirmed.

---

## 6. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Copilot surfaces restricted M&A or payroll data to unpermissioned users | High (if pre-conditions skipped) | Critical — regulatory and reputational | Treat Phase 1 permission clean-up as a hard blocker before licence assignment |
| Auto-labelling misclassifies documents, triggering false-positive DLP blocks | Medium | Medium — user disruption | Run auto-labelling in simulation mode for 5 days before switching to enforce |
| Finance users use Copilot to inadvertently include sensitive figures in external emails | Medium | High | Acceptable use policy + DLP policy on Exchange outbound |
| Shadow IT — users request Copilot via personal accounts | Low | High | Communicate that Copilot will be provided; block consumer Copilot via MCAS/Defender for Cloud Apps if needed |
| Audit log gap between licence assignment and logging confirmation | Low | Medium | Confirm audit logging in Phase 3 before any licence is assigned |

---

## 7. Next Steps

| # | Action | Owner | Target |
|---|---|---|---|
| 1 | Kick off SharePoint permissions audit | SharePoint Admin | Week 1 |
| 2 | Engage Compliance to confirm or build label taxonomy | Compliance | Week 1 |
| 3 | Review existing DLP policies in Purview | Compliance / Security | Week 1 |
| 4 | Confirm audit logging status and Conditional Access coverage | M365 Admin / Identity | Week 2 |
| 5 | Draft acceptable use policy for Finance Copilot | IT / Legal | Week 2–3 |
| 6 | Schedule user awareness session | Change Management | Week 3 |
| 7 | Assign pilot licences to ~20 Finance champions | M365 Admin | Week 4 (post go/no-go) |
| 8 | Full rollout to remaining ~180 Finance users | M365 Admin | Week 5 (post pilot clean) |

---

*This document is a draft for review. All "to confirm" items require validation against the live tenant before go/no-go decision is made.*
