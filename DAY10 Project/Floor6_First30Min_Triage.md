# Floor 6 Monday Incident - First 30 Minute Triage

## Version Header
- Title: Floor 6 Monday Incident - First 30 Minute Triage
- Version: 1.0
- Date: 14/08/2026
- Author: Vamsi
- Status: Draft

## Scenario Source (Single Input)
09:14 Slack message from IT Ops lead:

> "Floor 6 is a mess this morning. At least a dozen people can't log in or it's taking forever. One paralegal says Copilot pulled up a client matter she swears she's never had access to - that one worries me. Someone else says their desktop shortcuts vanished. We rolled out a new document management app to that floor on Friday afternoon. Can you get to the bottom of this and tell me what's actually going on, what we do right now, and what we tell the partners by lunch? I need something I can actually hand to non-technical people."

## Scope and Constraints
- This triage is based only on the Slack message.
- No logs, exports, telemetry, audit data, deployment reports, or endpoint evidence were available at draft time.
- This document is triage only.
- No remediation actions are proposed.
- No root cause is proposed.
- No assumption is made that Friday deployment caused any symptom.
- No assumption is made that all symptoms are related.
- The Copilot matter-access report is treated as a potential security incident until disproven.

---

## SECTION 1 - Incident Separation

### Track 1: Potential Unauthorized Matter Access via Copilot
- Incident Name: Potential Unauthorized Matter Access via Copilot
- Incident Classification: Security, User Experience
- User Impact: One paralegal reports Copilot surfaced a client matter she states she never had access to.
- Business Impact: Potential confidentiality exposure, legal/compliance risk, client trust impact.
- Facts Known:
  1. One report exists of unexpected matter visibility in Copilot.
  2. IT Ops lead explicitly flagged this as concerning.
- Assumptions Not Yet Proven:
  1. User never had direct or inherited access.
  2. Copilot exposed restricted content (not metadata or naming confusion).
  3. Cause is product defect rather than permission history or indexing/context behavior.
- Why Separate: Security evidence, handling, and escalation path differ from performance and configuration issues.
- Potential Risk if Ignored: Ongoing data exposure, delayed regulatory/legal response, increased blast radius.

### Track 2: Floor 6 Login Failures and Severe Login Slowness
- Incident Name: Floor 6 Login Failure / Severe Login Latency
- Incident Classification: Availability, Performance, possible Identity dependency
- User Impact: At least a dozen users reportedly cannot log in or are experiencing very slow login.
- Business Impact: Broad productivity loss, delayed legal operations, rising service desk pressure.
- Facts Known:
  1. Issue is reported this morning on Floor 6.
  2. Symptoms include both failure and severe delay.
  3. Estimated impact count is at least 12 users.
- Assumptions Not Yet Proven:
  1. All affected users share one failure mode.
  2. Physical floor location indicates shared network/dependency issue.
  3. Issue is linked to Friday deployment.
- Why Separate: Multi-user access disruption requires dedicated availability triage and independent scope validation.
- Potential Risk if Ignored: Business interruption widens, outage duration increases, executive escalation intensifies.

### Track 3: Missing Desktop Shortcuts
- Incident Name: Desktop Shortcuts Missing
- Incident Classification: Configuration, User Experience
- User Impact: At least one user reports missing shortcuts, causing navigation friction.
- Business Impact: Moderate direct disruption; potential indicator of profile/policy drift.
- Facts Known:
  1. A report exists of vanished shortcuts.
  2. Scope and affected app list are unknown.
- Assumptions Not Yet Proven:
  1. Shortcuts were deleted versus hidden/redirected.
  2. Same underlying cause as login issue.
  3. Linked to Friday deployment.
- Why Separate: Likely profile/configuration line of inquiry with different evidence sources and urgency.
- Potential Risk if Ignored: Possible spread of profile/config issues, rising support demand.

### Track 4: Friday Deployment Correlation Hypothesis
- Incident Name: Friday Document Management Rollout Correlation
- Incident Classification: Deployment, Change Management
- User Impact: Indirect, as potential shared timing factor.
- Business Impact: If related, potential wider impact beyond Floor 6 depending on targeting.
- Facts Known:
  1. New document management app rolled out Friday afternoon to Floor 6.
  2. Monday symptoms reported on the same floor.
- Assumptions Not Yet Proven:
  1. Timing equals causation.
  2. Deployment introduced changes affecting login/profile/security context.
- Why Separate: Change-correlation must be tested without anchoring bias.
- Potential Risk if Ignored: Missed cross-track evidence and delayed accurate communications.

---

## SECTION 2 - First 30 Minute Triage Plan

### Ranked Urgency
1. Track 1: Potential Unauthorized Matter Access via Copilot
2. Track 2: Floor 6 Login Failure / Severe Login Latency
3. Track 4: Friday Deployment Correlation Hypothesis
4. Track 3: Missing Desktop Shortcuts

### Track 1 Priority Ranking: 1
- Why this priority was assigned: Potential confidentiality exposure carries immediate security and legal risk even with a single reporter.
- What evidence to collect first: Reporter identity, exact time, exact prompt, exact Copilot output, matter identifier, whether link opened restricted content.
- First tool/system/platform to check: Microsoft Purview Audit and M365/Copilot audit event trail; matter repository permission history.
- Why highest-value first check: Fastest way to establish whether unauthorized content access occurred and to form a defensible timeline.
- Evidence currently missing: Audit records, effective permissions at event time, corroboration.
- Result that would reduce concern: No unauthorized retrieval and no effective entitlement found.
- Result that would increase concern: Confirmed content retrieval without valid entitlement.
- Outcome requiring immediate escalation: Any validated unauthorized access to client-confidential matter or inability to rapidly scope exposure.
- Prioritization reasoning: Highest security risk and potentially highest legal consequence.

### Track 2 Priority Ranking: 2
- Why this priority was assigned: High reported user impact and active business disruption.
- What evidence to collect first: Affected user list, timestamps, exact errors, affected versus unaffected comparison by device/network/location.
- First tool/system/platform to check: Entra ID sign-in logs, then Nexthink/Endpoint Analytics for logon duration and endpoint health.
- Why highest-value first check: Quickly separates identity failure from endpoint performance bottleneck and defines breadth.
- Evidence currently missing: Failure code pattern, latency baseline comparison, precise blast radius.
- Result that would reduce concern: Narrow cohort, transient pattern, unaffected control group confirmed.
- Result that would increase concern: Sustained failures across broader cohort or spread beyond Floor 6.
- Outcome requiring immediate escalation: Rapid growth in affected users or enterprise identity-service impact indicators.
- Prioritization reasoning: Highest known user-impact track but secondary to possible security exposure.

### Track 4 Priority Ranking: 3
- Why this priority was assigned: Strong explanatory value across symptoms, but still a hypothesis.
- What evidence to collect first: Change IDs, rollout targets/rings, package versions, install success/failure telemetry, policy changes.
- First tool/system/platform to check: ITSM change records plus Intune/SCCM assignment and deployment status.
- Why highest-value first check: Validates overlap between impacted users and rollout scope.
- Evidence currently missing: Verified cohort overlap and deployment health integrity.
- Result that would reduce concern: Little/no overlap or clean deployment outcomes.
- Result that would increase concern: High overlap plus failure/partial deployment patterns aligned to symptom timing.
- Outcome requiring immediate escalation: Evidence of broad faulty deployment with significant operational or security impact.
- Prioritization reasoning: Important for correlation and communication accuracy, but not primary before Tracks 1 and 2.

### Track 3 Priority Ranking: 4
- Why this priority was assigned: Lowest current severity and unknown scale.
- What evidence to collect first: Count of affected users, shortcut types, profile path state, policy/script actions.
- First tool/system/platform to check: Intune/SCCM/GPO reporting plus user profile event logs.
- Why highest-value first check: Distinguishes isolated profile issue from policy-wide configuration drift.
- Evidence currently missing: Scope, repeatability, timeline correlation.
- Result that would reduce concern: Isolated single-user profile anomaly.
- Result that would increase concern: Multi-user, repeatable pattern after shared policy/package event.
- Outcome requiring immediate escalation: Evidence of broad profile corruption affecting core user workspace.
- Prioritization reasoning: Lower immediate risk, monitored for growth.

---

## SECTION 3 - Evidence Collection Plan

### Track 1: Potential Unauthorized Matter Access via Copilot
- Data Sources:
  1. Microsoft Purview Audit
  2. M365 Audit Logs
  3. Copilot audit/service events
  4. SharePoint/OneDrive/matter-system permission history
  5. Service desk incident details
- Logs:
  - Copilot interaction audit logs
  - Repository access logs
  - Security logs tied to access attempts
- Telemetry:
  - Copilot request/response correlation IDs
  - Access-scope and content retrieval traces (where available)
- Deployment Records:
  - Recent Copilot policy/configuration changes
  - Labeling/classification policy updates
  - Connector/index updates
- Audit Records:
  - Purview unified audit
  - M365 unified audit
  - Permission/ACL change audits
  - Admin action logs
- User Validation Required:
  - Reporter walkthrough with exact prompt, timing, observed output, and whether underlying content could be opened
- Why needed / expected evidence / elimination value:
  - These sources establish if true unauthorized access occurred, whether entitlement existed, and whether event sequence supports or refutes a security incident.

### Track 2: Floor 6 Login Failure / Severe Login Latency
- Data Sources:
  1. Entra ID Sign-in Logs
  2. Nexthink and Endpoint Analytics
  3. Service desk ticket stream
  4. Device management health reports
- Logs:
  - Windows Event Viewer (Security, System, User Profile Service)
  - Authentication client logs
  - Network/auth broker logs where applicable
- Telemetry:
  - Sign-in latency distributions
  - Boot/logon timing anomalies
  - Endpoint health indicators
- Deployment Records:
  - Recent policy/app/profile changes targeting Floor 6 users/devices
- Audit Records:
  - Identity policy changes
  - Conditional Access edits
  - Device compliance policy changes
- User Validation Required:
  - Exact error text, estimated login duration, consistency across retries/reboots/network paths
- Why needed / expected evidence / elimination value:
  - These data determine whether failures are identity rejection, endpoint slowness, or mixed patterns and define blast radius.

### Track 4: Friday Deployment Correlation Hypothesis
- Data Sources:
  1. ITSM/CAB change records
  2. Intune and SCCM deployment reports
  3. Deployment ring and targeting group definitions
- Logs:
  - Installer logs
  - Management agent logs
  - Detection-rule logs
- Telemetry:
  - Deployment success/failure rates
  - Install duration and retry patterns
  - Post-deployment experience deltas
- Deployment Records:
  - Version manifests
  - Release notes
  - Assignment snapshots
- Audit Records:
  - Admin changes to assignment and policy targeting
- User Validation Required:
  - Whether impacted users were in rollout scope and when symptoms started relative to deployment window
- Why needed / expected evidence / elimination value:
  - Confirms or rejects overlap between incident cohort and deployment cohort without assuming causality.

### Track 3: Missing Desktop Shortcuts
- Data Sources:
  1. Intune/SCCM profile and script execution history
  2. GPO change history
  3. Service desk pattern review
- Logs:
  - User Profile Service logs
  - Explorer/shell logs
  - Script execution and folder redirection logs
- Telemetry:
  - Configuration drift indicators
  - Shell/startup anomaly metrics
- Deployment Records:
  - Desktop layout/profile-related packages or policies
- Audit Records:
  - GPO/Intune policy edit and approval history
- User Validation Required:
  - Which shortcuts disappeared, whether targets still exist in user profile paths, and whether behavior reproduces on new session
- Why needed / expected evidence / elimination value:
  - Differentiates isolated user profile artifact from broader managed configuration change.

---

## SECTION 4 - First-Hour Manager Update

We have separated this morning’s reports into four investigation tracks so we do not incorrectly treat them as one problem.

- Separate issues identified so far:
  1. Potential confidential matter access concern related to Copilot
  2. Login failures and severe login delays affecting multiple users
  3. Missing desktop shortcuts for at least one user
  4. A timing correlation hypothesis involving Friday’s app rollout
- Highest business risk:
  - Login disruption, because it may be blocking work for a large group.
- Highest security risk:
  - The Copilot matter-access report, treated as a potential confidentiality issue until disproven.
- Largest user impact:
  - Login failure/slowness (currently reported as at least a dozen users).
- Evidence being gathered:
  - Identity sign-in data, endpoint performance signals, change/deployment records, and audit trails tied to the Copilot report.
- What remains unknown:
  - Exact user counts per symptom, whether symptoms share a cause, whether unauthorized matter access occurred, and whether Friday rollout scope overlaps with impacted users.
- Next investigation steps:
  - Validate impact counts by track, complete first-pass security audit validation for the Copilot report, map impacted users to rollout targeting, and provide a risk-ranked update suitable for partner communication.

---

## SECTION 5 - Initial Risk Assessment

| Investigation Track | Impact | Urgency | Business Risk | Security Risk | Current Confidence Level | Escalation Required |
| --- | --- | --- | --- | --- | --- | --- |
| Track 1: Potential Unauthorized Matter Access via Copilot | Medium now, potentially high if confirmed | High | High | Very High | Low | Yes |
| Track 2: Floor 6 Login Failure / Severe Login Latency | High | High | High | Medium | Medium-Low | Yes |
| Track 4: Friday Deployment Correlation Hypothesis | Medium | Medium-High | Medium-High | Medium | Low | No (monitor threshold) |
| Track 3: Missing Desktop Shortcuts | Low-Medium | Medium | Medium | Low | Low | No |

Rating explanations:
- Track 1: Security risk is very high due to potential confidentiality exposure; confidence is low until audit evidence is reviewed.
- Track 2: Urgent due to breadth of reported user impact; confidence is medium-low because current count is report-based.
- Track 4: Moderate risk because it may explain multiple symptoms, but remains an unproven hypothesis.
- Track 3: Lower urgency due to unknown scope and currently lower observed impact.

---

End of Document
