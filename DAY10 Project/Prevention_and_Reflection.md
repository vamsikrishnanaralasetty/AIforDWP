# Floor 6 Prevention Recommendation and Reflection

## Version Header
- Title: Floor 6 Prevention Recommendation and Reflection
- Version: 1.0
- Date: 14/08/2026
- Author: Vamsi
- Status: Final Draft

## SECTION 1 - Prevention Objective

The Floor 6 Monday incident affected users before IT became aware because a user-facing change had already been introduced to a live business group before the next working period began. By the time the business returned on Monday morning, the impact was visible to users rather than being intercepted through an operational checkpoint.

What happened at a process level:
- A floor-scoped change was introduced on Friday afternoon.
- Users returned to work on Monday and reported login delay, login failure, and related disruption.
- IT became aware only after users experienced the issue directly.

Why users were impacted before IT became aware:
- There was no formal stop-point between deployment completion and the next business period requiring a health review of the affected cohort.
- The operating model allowed a user-facing rollout to cross a non-business window without a mandatory business-readiness decision.
- Detection depended on users reporting a problem rather than on a controlled go or hold review before Monday start of day.

Where the operational process failed to detect the issue early:
- The process did not require a named owner to review early post-deployment evidence before rollout progression stood as accepted.
- The process did not require a measurable pass/fail decision before the business resumed work.
- The process treated deployment completion as the end of the change activity, rather than treating early user experience as part of the same controlled change window.

This prevention recommendation therefore focuses on closing the operational gap between deploying a user-facing change and allowing that change to stand unchallenged into the next business period.

---

## SECTION 2 - Recommended Process Control

### Control Name
Business-Hour Readiness Hold for User-Facing Endpoint Changes

### Purpose
To prevent a user-facing endpoint change from remaining active into the next business period unless a named engineer or change owner has reviewed a defined evidence set and recorded a pass decision.

### Scope
- All floor-scoped, department-scoped, or ring-scoped endpoint changes that can affect sign-in, startup, desktop load, application launch, or access to business content.
- Examples include application deployments, endpoint agent changes, sign-in related policy changes, startup component changes, and Windows experience-affecting configuration changes.

### Trigger Criteria
The control activates when all of the following are true:
- The change targets end-user devices or user sessions.
- The change is released after 12:00 local time on the last business day before a weekend, public holiday, or out-of-hours period longer than 12 hours.
- The change can affect user login, startup, application availability, or access to working data.

### Process Owner
Primary owner: End User Compute Change Manager.

Operational reviewer: Assigned deployment engineer or service owner for the released change.

Approval authority: IT Operations duty manager or delegated service manager.

### Required Inputs
- Approved change record.
- Target device and user cohort.
- Deployment completion status.
- Early post-deployment health evidence for the target cohort.
- Any incident or service desk reports linked to the target cohort.
- Rollback method and exclusion group details.

### Expected Outputs
- Recorded readiness decision: Pass, Hold, or Escalate.
- Evidence review note attached to the change record.
- Named reviewer and timestamp.
- If Hold: rollout freeze action and rollback decision record.
- If Escalate: manager and incident escalation record.

### Success Criteria
- 100% of in-scope changes have a recorded readiness decision before the next business start.
- 100% of readiness decisions identify reviewer, evidence reviewed, and time of decision.
- 0 in-scope changes progress into the next business period without either Pass, Hold, or Escalate status.
- Weekend or out-of-hours user-impact incidents caused by in-scope changes trend downward over time.

This is concrete, auditable, and measurable because every in-scope change must either have a documented pass decision or be held.

---

## SECTION 3 - Control Workflow

### 1. When the control activates
The control activates automatically when a user-facing endpoint change completes during the trigger window described above. Completion of the deployment does not close the change. Instead, the change enters Readiness Hold status until a pass decision is recorded.

### 2. Who performs the review
- The assigned deployment engineer gathers the required evidence set.
- The service owner or designated senior engineer performs the readiness review.
- The IT Operations duty manager confirms the final Pass, Hold, or Escalate decision.

### 3. What evidence must be reviewed
The reviewer must examine the following minimum evidence set for the affected rollout cohort:
- Deployment completion and failure state.
- Early user-impact signals for the targeted group.
- Sign-in and startup experience indicators for the targeted group.
- Application stability evidence for the deployed component.
- Comparison with a small unaffected control cohort where available.
- Readiness of the documented rollback or exclusion action.

The review must not be waived because the deployment completed successfully. The control is specifically about user readiness, not just deployment finish status.

### 4. What thresholds trigger escalation
Escalation is mandatory if any of the following are true:
- Any credible report indicates loss of access to business systems for more than one user in the target cohort.
- Any credible report indicates possible access to information outside normal expectation.
- More than 5% of the targeted cohort shows sign-in failure, severe startup delay, or repeat incident reports within the hold window.
- A rollback method is missing, incomplete, or not executable for the target cohort.
- Evidence across sources is contradictory enough that the reviewer cannot defend a Pass decision.

### 5. What conditions stop rollout progression
Rollout progression stops and the change is placed on Hold if any of the following apply:
- User-impact reports are present and align to the target cohort.
- Stability evidence shows failures, repeated startup degradation, or significant deviation from expected user experience.
- The affected cohort cannot be cleanly separated from unaffected users for containment.
- Required evidence is missing by the readiness review deadline.
- The reviewer cannot demonstrate that rollback can be performed before next business start if needed.

### 6. What conditions allow rollout continuation
Rollout continuation is allowed only when all of the following are true:
- No credible user-impact reports exist within the hold window for the target cohort.
- Evidence reviewed does not show meaningful degradation in sign-in, startup, or application stability.
- The rollback path is available and verified.
- Reviewer, service owner, and operations approver all record a Pass decision in the change record.

### Detailed operational workflow
1. Change is deployed to the approved ring or cohort.
2. System automatically marks the change as Readiness Hold if it meets trigger criteria.
3. Deployment engineer assembles the required evidence pack within the defined hold window.
4. Reviewer compares target-cohort evidence against expected service behavior and any available control cohort.
5. Reviewer records one decision only: Pass, Hold, or Escalate.
6. If Pass: change proceeds and the hold is closed.
7. If Hold: rollout progression stops, exclusion or rollback actions are initiated, and affected stakeholders are informed.
8. If Escalate: incident management and service leadership are engaged before next business start.
9. Change record is not closed until readiness disposition is documented.

This workflow makes the stop-point real, accountable, and visible in audit records.

---

## SECTION 4 - Why This Control Would Have Prevented the Incident

### Which warning signs would have existed
The warning signs likely available before Monday business hours were:
- Signs that the change affected only the targeted Floor 6 cohort rather than the wider estate.
- Early evidence of poor startup behavior or unstable application behavior on deployed devices.
- Failed or partial deployment states on a subset of the affected group.
- Initial business-impact reports or service desk contacts linked to the same rollout cohort.

### When they would likely have appeared
These signs would most likely have appeared between the Friday deployment completion window and the next business-start review window, especially during first restart, first sign-in, or first application launch after the change.

### How the control would have detected them
Step by step:
1. The Friday afternoon release would have met the trigger criteria because it was a user-facing endpoint change deployed before a non-business period.
2. The change would have entered Readiness Hold instead of being treated as complete.
3. The deployment engineer would have been required to gather the defined readiness evidence before Monday business start.
4. The reviewer would have been required to assess target-cohort health rather than assuming the rollout was acceptable because distribution finished.
5. Any credible impact pattern, missing rollback readiness, or instability signal would have forced a Hold or Escalate decision.

### How intervention could have occurred before Monday business hours
- The rollout could have been paused before additional devices or users were exposed.
- Affected devices could have been excluded from continued assignment.
- Rollback preparation could have been completed before the main business day began.
- Stakeholders could have been warned that a change was being held pending validation, rather than learning about the issue through user disruption.

The control would not guarantee that a defect never ships. It would, however, make it much less likely that a business-facing problem remains undetected until users arrive at work.

---

## SECTION 5 - Benefits and Trade-Offs

### Benefits
- User impact reduction:
  - Users are less likely to become the first detection point for a bad rollout.
- Risk reduction:
  - Potential access, startup, or application failures are more likely to be intercepted before business start.
- Improved deployment quality:
  - Deployment success is judged by user readiness, not just package completion.
- Better operational visibility:
  - Each in-scope change has a named decision, evidence pack, and audit trail.

### Trade-Offs
- Additional review effort:
  - Engineers and service owners must perform a readiness review for in-scope changes.
- Operational overhead:
  - The control adds a formal hold step, documentation, and sign-off.
- Possible rollout delays:
  - A deployment may remain paused until evidence is reviewed and accepted.

### Why the control remains worthwhile
The trade-off is justified because the control turns an unmanaged risk window into a controlled decision point. A short, formal readiness hold is less costly than allowing users, business leaders, and incident teams to absorb the impact of an avoidable Monday-morning disruption.

---

## SECTION 6 - Required Reflection

### Where My First Instinct Was Wrong
My first instinct when reviewing the incident was to suspect an authentication-path problem. That hypothesis seemed reasonable because the earliest user wording was that people "could not log in," and broad sign-in disruption often points toward a shared identity dependency.

What evidence failed to support that first instinct:
- The investigation record did not produce a confirmed wider business pattern outside Floor 6.
- The only clearly time-bound, floor-specific change in the incident window was the Friday document management deployment.
- The symptom set included severe delay as well as failure, which fits startup degradation and application overhead as well as identity failure.

What evidence changed my view:
- The differential analysis showed that identity remained plausible, but it also showed the strongest concrete change signal was the floor-scoped Friday deployment.
- The evidence-collection planning focused on application presence, startup behavior, CPU, memory, disk, and crash evidence because those were the fastest checks that could directly confirm or weaken the deployment hypothesis.
- The immediate-fix planning showed there was a targeted containment path available for the deployment cohort, which made the deployment-related explanation more operationally persuasive even before final proof.

How the investigation process corrected the assumption:
- The process separated confirmed facts from assumptions.
- It forced comparison of multiple hypotheses instead of letting the first symptom define the answer.
- It prioritized evidence that could distinguish identity failure from startup and application degradation.
- It shifted the decision from "what seems most familiar" to "what best fits the known change window, cohort scope, and available containment action."

Reference to the Section 3a AI-generated script review:
- The AI-generated script review encouraged a narrow assumption that the recently deployed application was already the correct answer, because the script was built around collecting app-specific resource evidence.
- The engineer review corrected that by strengthening validation, error handling, collection logging, and output structure so that the script could support or challenge the application hypothesis rather than merely reinforce it.
- Evidence-based analysis was more reliable than accepting the first explanation because a plausible story is not the same as a proven cause. The engineer review made the evidence collection defensible and reduced the risk of confirmation bias.

This reflection satisfies the capstone requirement because it shows a reasonable initial assumption, explains why it was attractive, identifies why it was insufficient, and shows how structured investigation and engineer review changed the judgment.

---

## SECTION 7 - Lessons Learned

### Technical Lesson Learned
User-facing application changes can create startup and sign-in impact even when the deployment mechanism itself appears successful. Future incident response should treat startup experience, application stability, and rollout cohort overlap as first-class technical evidence for endpoint incidents.

### Operational Lesson Learned
A change is not operationally safe simply because it has finished deploying. Future change handling should require a formal user-readiness decision before a user-facing rollout is allowed to stand across a weekend or other long out-of-hours window.

### Investigation Lesson Learned
Early symptom wording can bias the investigation toward the most familiar explanation. Future responders should separate facts, assumptions, and missing evidence at the start so that each major hypothesis is tested against the same standard.

### AI-Assisted Engineering Lesson Learned
AI-generated code and hypotheses can accelerate a response, but they can also encourage premature narrowing on one explanation. Future incident response should continue to use AI assistance as a drafting and acceleration tool, with engineer review providing the validation, control, and evidence discipline needed for production decision-making.

### How these lessons will influence future incident response
These lessons support a more disciplined response model in which change control, evidence collection, and hypothesis testing stay tightly connected. Future incidents should move more quickly from user report to controlled evidence review, while reducing the chance that either a deployment artifact or an AI-generated assumption becomes an unchallenged conclusion.

---

End of Document
