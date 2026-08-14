# Floor 6 Copilot Security Incident Assessment

## Version Header
- Title: Floor 6 Copilot Security Incident Assessment
- Version: 1.0
- Date: 14/08/2026
- Author: Vamsi
- Status: Draft

## Scenario Basis
Single user report from a paralegal during the Floor 6 Monday incident:

"Copilot pulled up a client matter she swears she's never had access to."

No audit logs, permission reviews, Copilot traces, SharePoint checks, OneDrive checks, Purview analysis, or endpoint artifacts have been reviewed yet.

---

## SECTION 1 - Incident Classification

### Classification Decision
- Incident Type: Potential Security Incident (possible unauthorized information exposure)
- Secondary Type: Trust and Compliance Risk Event
- Triage Position: Security-signal classification pending evidence verification

### Why this should not be treated as a normal support ticket
- The reported symptom is not only a functionality concern; it suggests possible access to client matter information outside expected authorization.
- Any plausible unauthorized access signal can carry legal, regulatory, confidentiality, and client-trust implications beyond normal application support scope.
- Support-only handling risks delayed security review and delayed evidence preservation.

### Why this should not be dismissed as AI weirdness
- "Unexpected output" is not evidence of harmless behavior.
- Copilot responses are grounded in enterprise data access pathways; therefore unexpected matter visibility is a security-relevant signal until proven otherwise.
- Dismissing early would replace evidence-based triage with assumption and could allow material risk to go unassessed.

### Why the report is potentially security-related
- The report directly concerns possible access boundary violation (user reports seeing a matter she believes she should not access).
- Access boundary concerns map to confidentiality and least-privilege controls.
- Even a single credible report can represent a high-severity signal if protected legal/client data may be involved.

### Type of security concern being reported
- Primary Concern: Potential unauthorized information exposure.
- Control Domain Potentially Involved: Identity and access governance, permissions inheritance, data labeling/protection, auditability.
- Current State: Unconfirmed security signal; investigation required.

### Business risks if the report is accurate
- Client confidentiality compromise.
- Legal and contractual exposure.
- Compliance reporting and audit consequences.
- Reputational damage with partners/clients.
- Loss of confidence in M365 Copilot and internal data governance.

### Facts currently known
- A paralegal reported that Copilot surfaced a client matter she says she never had access to.
- The statement is currently the only evidence.
- No technical validation has yet been completed.

### Facts currently unknown
- Whether Copilot actually displayed restricted content, metadata, or a similarly named item.
- Whether the user had current or historical direct/inherited access.
- Whether data was merely referenced or actually opened/retrieved.
- Whether this is isolated or part of a broader pattern.
- Whether policy, permissions, indexing, or context behavior contributed.

### Facts vs assumptions
- Fact: A single user-reported statement exists.
- Fact: No supporting telemetry or audit evidence has been reviewed yet.
- Assumption (not yet proven): Unauthorized access actually occurred.
- Assumption (not yet proven): The user is mistaken.
- Assumption (not yet proven): Copilot malfunctioned.
- Assumption (not yet proven): A permissions configuration error exists.

Reasoning: At this stage, classification is based on potential impact and risk category, not on confirmed root cause.

---

## SECTION 2 - What I Would NOT Do

1. Close the ticket without investigation.
- Why inappropriate: It ignores a potential confidentiality signal and prevents proper risk validation.

2. Reclassify immediately as a normal support incident.
- Why inappropriate: Security implications exceed standard support boundaries until evidence disproves them.

3. Assume Copilot invented information.
- Why inappropriate: This conclusion is unsupported without audit and source-validation evidence.

4. Assume the user is mistaken.
- Why inappropriate: User perception may be incomplete, but it is still a valid trigger for security triage.

5. Assume this is a Microsoft product bug.
- Why inappropriate: Product defect is one possibility among many and cannot be asserted without evidence.

6. Assume a permissions issue is already confirmed.
- Why inappropriate: Permission faults must be demonstrated via audit and entitlement review, not inferred.

7. Announce a breach occurred.
- Why inappropriate: Current evidence does not establish confirmed unauthorized exposure.

8. Down-prioritize because only one report exists.
- Why inappropriate: Single-reporter events can still indicate high-severity confidentiality risk.

9. Perform ad hoc data access tests in production using live sensitive matters.
- Why inappropriate: Can contaminate evidence, expand exposure, and create additional audit complexity.

10. Provide definitive conclusions to business stakeholders before first-pass evidence collection.
- Why inappropriate: Premature conclusions create misinformation and weaken trust in incident handling.

---

## SECTION 3 - Immediate Investigation Actions (Evidence Plan Only)

The following evidence should be collected first. This section defines what to collect and why; it does not execute investigation.

### 1) Evidence Source: User validation interview (reporting paralegal)
- Why relevant: Establishes exact event context and reduces ambiguity in downstream log searches.
- Question it helps answer: What exact prompt, time, output wording, and follow-up actions occurred?

### 2) Evidence Source: Microsoft Purview Audit logs
- Why relevant: Central audit trail for content and compliance-relevant activities.
- Question it helps answer: Is there auditable evidence of access/request activity aligned to the reported time and user?

### 3) Evidence Source: Microsoft 365 Unified Audit logs
- Why relevant: Cross-service event visibility for user, object, and operation sequence.
- Question it helps answer: What event chain occurred before, during, and after the reported Copilot interaction?

### 4) Evidence Source: Copilot activity records/correlation identifiers
- Why relevant: Links user prompt context to service-side activity and referenced sources.
- Question it helps answer: What source objects were involved in response generation?

### 5) Evidence Source: SharePoint site/library/folder/file permissions and access history
- Why relevant: Many legal matter records may live in SharePoint-backed repositories.
- Question it helps answer: Did the reporting user have effective direct or inherited permission at event time?

### 6) Evidence Source: OneDrive permissions and sharing links (if matter artifacts involved)
- Why relevant: OneDrive shares can create indirect visibility pathways.
- Question it helps answer: Were there active links or shares that could explain access scope?

### 7) Evidence Source: Entra ID group membership and recent membership changes
- Why relevant: Group-based entitlement can alter effective access unexpectedly.
- Question it helps answer: Was the user in any group granting matter access when the event occurred?

### 8) Evidence Source: Document access history for the specific matter item(s)
- Why relevant: Confirms whether the user or service context touched target content.
- Question it helps answer: Was the reported matter actually accessed, previewed, or only referenced?

### 9) Evidence Source: Sensitivity labels and protection configuration on implicated content
- Why relevant: Determines expected control boundaries for confidential legal matter data.
- Question it helps answer: What protections should have governed access and response behavior?

### 10) Evidence Source: DLP policy scope and recent policy changes
- Why relevant: DLP can influence how sensitive data is surfaced and controlled.
- Question it helps answer: Were controls in place and enforced for this content type and user context?

### 11) Evidence Source: Change records for recent M365/Copilot/permission policy updates
- Why relevant: Establishes timeline correlation without assuming causality.
- Question it helps answer: Did any recent changes affect entitlement, indexing, labeling, or access pathways?

### 12) Evidence Source: Service desk incident pattern scan
- Why relevant: Detects whether this is isolated or recurring.
- Question it helps answer: Are there similar reports from other users or practice areas?

Evidence-collection reasoning: these sources together test entitlement, access path, content exposure, and control effectiveness in an auditable sequence.

---

## SECTION 4 - Escalation Assessment

### Who should be notified
- Security Operations / Cyber Incident Response.
- Compliance and Data Protection function.
- M365 service owner / Collaboration platform owner.
- IT Operations incident manager.
- Legal/Privacy liaison (per organizational policy, for potential client-data exposure scenarios).

### Why escalation is required
- The report indicates a potential confidentiality boundary breach involving client matter information.
- Security and compliance teams are required to assess exposure risk, evidence integrity, and reporting obligations.
- Delayed escalation increases risk of incomplete evidence and delayed business-risk decisions.

### Appropriate urgency level
- Recommended Urgency: High (security signal requiring immediate triage start).
- Severity confirmation: Pending evidence.

Reasoning: impact potential is high even though certainty is currently low.

### Business impact if confirmed
- Possible unauthorized exposure of privileged/client matter information.
- Contractual and regulatory consequences.
- Client trust erosion and reputational harm.
- Elevated legal and executive scrutiny.
- Potential need for formal incident response and stakeholder communications.

---

## SECTION 5 - Two-Sentence Escalation

A paralegal reported that Microsoft 365 Copilot surfaced a client matter the user states she has never had access to, and this is currently the only confirmed fact available. Please initiate an urgent Security and Compliance investigation to validate access history and audit evidence, as this may represent potential unauthorized information exposure until disproven.

---

## SECTION 6 - Manager Explanation (Non-Technical)

This is not being handled as a normal support issue because the report suggests a possible confidentiality problem, not just an application problem, and confidentiality risks require Security and Compliance involvement from the start. We need investigation before conclusions because we currently have one user report and no technical evidence yet, and this receives higher priority than routine app issues due to the potential legal, client-trust, and business impact if the report is confirmed.

---

End of Document
