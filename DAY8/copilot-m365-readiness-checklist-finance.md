# Microsoft 365 Copilot — Readiness Checklist: Finance Department

| Field | Detail |
|---|---|
| **Title** | M365 Copilot Readiness Checklist — Finance |
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
**SharePoint posture:** Permissions inherited from 2019 migration; no full audit conducted since  

---

> **Critical note before starting:** Copilot for M365 operates on the Microsoft Graph and surfaces any content the signed-in user already has permission to access — SharePoint, OneDrive, Teams, Exchange, and more. It does not add permissions, but it makes existing over-permissioned access trivially exploitable via a single natural language prompt. A payroll file that was technically readable by the wrong person but never found manually can be retrieved in seconds with Copilot. For a Finance department with seven years of unaudited inherited permissions, **sections 3 and 4 (permissions and oversharing) are not optional pre-work — they are blockers. Do not assign the Copilot add-on until every item in those sections is ticked.**

---

## Section 1 — Licensing Prerequisites

| # | Check | How to verify | Done |
|---|---|---|---|
| 1.1 | All ~200 Finance users hold a valid M365 E5 licence | Microsoft 365 admin centre > Users > Active users > filter by licence | ☐ |
| 1.2 | No Finance users are on E3 or lower — E3 does not satisfy Copilot prerequisites | Same filter; export and cross-reference against Finance HR list | ☐ |
| 1.3 | Microsoft Copilot for M365 add-on licences are procured and available in the tenant (not yet assigned) | Admin centre > Billing > Licences — confirm quantity ≥ 200 available | ☐ |
| 1.4 | Licence assignment is planned for a named pilot group first (~20 users), not all 200 simultaneously | Confirm with licence owner before any assignment | ☐ |

---

## Section 2 — Microsoft 365 Apps Client Version

| # | Check | How to verify | Done |
|---|---|---|---|
| 2.1 | All Finance endpoints run Microsoft 365 Apps for Enterprise (not Office 2019/2021 perpetual) | Intune > Reports > Microsoft 365 Apps > App inventory | ☐ |
| 2.2 | Apps build version is Current Channel or Monthly Enterprise Channel, at minimum Version 2302 (build 16130.20218) | Intune app inventory or Office Deployment Tool report; check each device's Office version | ☐ |
| 2.3 | No Finance devices are stuck on Semi-Annual Enterprise Channel — Copilot features are unavailable on that channel | Filter Intune app inventory by channel; flag any SAEC devices for channel migration | ☐ |
| 2.4 | Update compliance is confirmed — no Finance devices are more than one version behind Current Channel | Intune > Reports > Windows Update compliance | ☐ |

---

## Section 3 — Identity, MFA, and Conditional Access

| # | Check | How to verify | Done |
|---|---|---|---|
| 3.1 | All 200 Finance users have MFA registered (authenticator app preferred; SMS not acceptable for high-sensitivity Finance data) | Entra ID > Users > MFA registration status report | ☐ |
| 3.2 | A Conditional Access policy requires MFA for all Finance users on every sign-in | Entra ID > Security > Conditional Access — review policies scoped to Finance group | ☐ |
| 3.3 | The same CA policy requires Intune-compliant device as a condition | Confirm "Require device to be marked as compliant" is set in the grant controls | ☐ |
| 3.4 | All Finance devices are enrolled in Intune and show Compliant status | Intune > Devices > Compliance — filter by Finance Azure AD group; zero non-compliant | ☐ |
| 3.5 | No Finance user accounts have permanent Global Admin or Exchange Admin roles (use PIM with JIT for privileged access) | Entra ID > Roles > Assignments — check for permanent high-privilege assignments in Finance group | ☐ |
| 3.6 | Guest/external accounts are not members of Finance-scoped SharePoint sites or Teams | Entra ID > External identities > Guest user list; cross-reference against Finance sites | ☐ |

---

## Section 4 — SharePoint and OneDrive Permissions and Oversharing

> **This is the highest-priority section.** The 2019 migration permissions have never been audited. Inherited permissions and broad group assignments on Finance content represent the single largest data-exposure risk when Copilot is enabled. Every item here must be completed and verified before licence assignment. Do not treat these as advisory.

### 4a — Permissions Audit

| # | Check | How to verify | Done |
|---|---|---|---|
| 4.1 | A full permissions report has been run across all Finance-owned SharePoint site collections | SharePoint Admin Centre > Active sites > export; then run `Get-PnPSiteCollectionPermissions` via PnP PowerShell against each Finance site URL | ☐ |
| 4.2 | All inherited permission chains from the 2019 migration have been reviewed — broken inheritance is documented and intentional, unintentional inheritance is remediated | Compare exported permissions against intended access model; document every break-inheritance decision | ☐ |
| 4.3 | "Everyone", "Everyone except external users", and "All Company" type groups have been removed from every Finance site collection, library, and folder | Search permissions export for these group names; remove each occurrence and confirm with site owner | ☐ |
| 4.4 | Broad legacy Active Directory security groups (e.g. "UK Staff", "All Finance Legacy") that were migrated in 2019 and may have grown in membership since have been reviewed and replaced with tightly scoped named groups | Cross-reference AD group membership lists against the intended Finance access model | ☐ |
| 4.5 | Each Finance SharePoint site has a designated site owner who has confirmed the current permissions are correct | Email confirmation or sign-off record from each site owner on file | ☐ |
| 4.6 | The permissions clean-up has been re-run and confirmed — a second export after remediation shows no outstanding overpermissioned accounts | Run `Get-PnPSiteCollectionPermissions` again post-remediation; diff against pre-remediation export | ☐ |

### 4b — High-Sensitivity Library Controls

| # | Check | How to verify | Done |
|---|---|---|---|
| 4.7 | Payroll documents are held in a dedicated SharePoint library with unique permissions — accessible only to named Payroll team members and HR leadership | Open library > Library settings > Permissions — confirm unique permissions and list members | ☐ |
| 4.8 | Board pack documents are held in a dedicated library accessible only to named board-level members and PA/EA accounts with confirmed need | Same check; confirm no broad Finance group has access | ☐ |
| 4.9 | M&A documents are stored in a separate site collection with access restricted to named deal-team members only; no inheritance from a parent Finance site | Confirm the M&A site is a standalone site collection not inheriting from a Finance hub; enumerate members | ☐ |
| 4.10 | Client financial data libraries have permissions that map to named client engagement teams — no one outside the engagement team can access client-specific folders | Review per-client library or folder permissions; confirm no over-broad assignments | ☐ |

### 4c — OneDrive and Sharing Settings

| # | Check | How to verify | Done |
|---|---|---|---|
| 4.11 | The tenant-level external sharing setting for SharePoint/OneDrive is set to "Existing guests only" or "Only people in your organisation" — "Anyone" links are disabled | SharePoint Admin Centre > Policies > Sharing — confirm top-level setting | ☐ |
| 4.12 | Finance-specific SharePoint sites have site-level sharing set to "Only people in your organisation" as a minimum | SharePoint Admin Centre > Active sites > select each Finance site > Sharing — confirm per-site setting | ☐ |
| 4.13 | A report of existing "Anyone" (anonymous) links across Finance sites has been run and all such links have been expired or revoked | Run SharePoint sharing report (Admin Centre > Reports > Sharing links) filtered to Finance sites; revoke all anonymous links | ☐ |
| 4.14 | OneDrive sharing for Finance users is restricted — users cannot share externally without approval | SharePoint Admin Centre > Settings > OneDrive — confirm external sharing is restricted for the Finance group via sensitivity policy or Conditional Access | ☐ |
| 4.15 | Microsoft Syntex SharePoint Advanced Management (included in E5) has been evaluated for access governance — specifically Restricted SharePoint Search, which limits Copilot to a defined set of sites during the initial rollout period | Review tenant Restricted SharePoint Search setting in SharePoint Admin Centre > Settings; consider enabling for pilot phase | ☐ |

---

## Section 5 — Sensitivity Labels and Data Loss Prevention

| # | Check | How to verify | Done |
|---|---|---|---|
| 5.1 | A sensitivity label taxonomy covering Finance data exists and is published to all Finance users — minimum labels: `Confidential`, `Highly Confidential — Finance`, `Restricted — M&A` | Microsoft Purview > Information Protection > Labels — confirm labels published to Finance group | ☐ |
| 5.2 | Auto-labelling policies are configured to detect and label Finance-relevant content (payroll figures, financial statements, M&A keyword sets) in SharePoint and OneDrive | Purview > Information Protection > Auto-labelling — confirm simulation has been run and policy is in Enforce mode | ☐ |
| 5.3 | Default sensitivity labels are applied at the SharePoint library level for each Finance site — documents without a user-applied label inherit the library default | SharePoint library settings > Default sensitivity label — check each Finance library | ☐ |
| 5.4 | DLP policies are active and in Enforce mode (not Audit-only) covering SharePoint, OneDrive, Teams chat, and Exchange for Finance users | Purview > Data loss prevention > Policies — confirm Finance-scoped policies are enforced, not in test mode | ☐ |
| 5.5 | DLP policies detect relevant sensitive information types: UK bank account numbers, payroll identifiers, financial statements, and custom types for M&A keywords | Review each DLP rule's SIT list; add custom SITs if required | ☐ |
| 5.6 | Microsoft Purview audit logging is confirmed active and set to retain Copilot interaction events (`CopilotInteraction`) for the retention period required by Finance/regulatory policy | Purview > Audit > confirm logging is on; check retention policy under Audit > Retention policies | ☐ |

---

## Section 6 — End-User Communications and Enablement

| # | Check | How to verify | Done |
|---|---|---|---|
| 6.1 | An acceptable use policy for Copilot for M365 has been drafted and approved — Finance-specific clauses must include: do not use Copilot output containing payroll or M&A data in external communications without review; do not prompt Copilot to summarise restricted documents for redistribution | Policy document reviewed and signed off by Finance Director and Legal/Compliance | ☐ |
| 6.2 | A Finance-specific onboarding guide has been created explaining: what Copilot can access, what it cannot do (it cannot access data the user is not permitted to see), acceptable prompt types, and how to report unexpected results | Document created and stored in the Finance SharePoint intranet space | ☐ |
| 6.3 | A pre-go-live awareness session has been scheduled and delivered (or scheduled) for all 200 Finance users before or alongside licence assignment | Calendar invite issued; attendance tracked | ☐ |
| 6.4 | A feedback and incident reporting channel is available — a dedicated ServiceNow category or shared mailbox where Finance users can report Copilot concerns, unexpected content surfacing, or suspected data access issues | Channel confirmed live before pilot licences are assigned | ☐ |
| 6.5 | IT champions (~5–10 Finance users, ideally team leads or power users) have been identified and briefed to support their colleagues during the pilot and rollout | Champions list confirmed; briefing session completed | ☐ |

---

## Final Go / No-Go Gate

Complete this gate check before assigning any Copilot licences. All items marked Critical must be confirmed. Advisory items should be resolved within 2 weeks of go-live.

| Gate | Section | Priority | Status |
|---|---|---|---|
| All Section 4a items ticked — permissions audit complete and all critical findings remediated | 4a | **Critical — blocker** | ☐ |
| All Section 4b items ticked — high-sensitivity libraries isolated and access-controlled | 4b | **Critical — blocker** | ☐ |
| All Section 4c items ticked — external sharing locked down, anonymous links revoked | 4c | **Critical — blocker** | ☐ |
| All Section 1 items ticked — licensing confirmed | 1 | Critical | ☐ |
| All Section 2 items ticked — client version confirmed | 2 | Critical | ☐ |
| All Section 3 items ticked — MFA and Conditional Access confirmed | 3 | Critical | ☐ |
| All Section 5 items ticked — labels and DLP in enforce mode | 5 | Critical | ☐ |
| Acceptable use policy signed off (6.1) | 6 | Critical | ☐ |
| User awareness session delivered or scheduled (6.3) | 6 | Advisory | ☐ |
| IT champions briefed (6.5) | 6 | Advisory | ☐ |

**Decision rule:** Do not assign the Copilot add-on — even to the pilot group — until all Critical gates are ticked. Advisory items may remain open at pilot start provided a completion date is confirmed.

---

*This document is a working checklist. Each completed item should be initialled by the engineer who verified it and dated. The completed checklist should be retained as evidence for the post-deployment audit record.*
