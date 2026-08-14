# Floor 6 Support Handoff: L1, L2, and Runbook

## Version Header
- Title: Floor 6 Support Handoff: L1, L2, and Runbook
- Version: 1.0
- Date: 14/08/2026
- Author: Vamsi
- Status: Draft

## Purpose
This document provides a separate support-facing handoff for the Floor 6 login and performance issue. It is intended to help Service Desk, L2 support, and engineering work from the same clear steps.

---

## L1 - First Contact

### What users may say
- "I cannot sign in"
- "My logon is taking a long time"
- "I get to the desktop very slowly"

### What L1 should confirm
- User is on Floor 6
- The issue started Monday morning
- The user is reporting login delay or failure, not a general password problem
- The issue is affecting more than one person

### What L1 should record
- User name
- Device name
- Time the issue happened
- Exact wording of the problem
- Whether the user can eventually get to the desktop
- Whether the user also noticed missing shortcuts or unusual app behavior

### What L1 should not do
- Do not promise a fix time
- Do not tell the user to reinstall anything
- Do not assume the issue is only personal to that user
- Do not treat the issue as complete until the user can sign in normally again

### L1 escalation trigger
Escalate to L2 immediately if:
- The user cannot sign in at all
- Sign-in is extremely slow
- More than one Floor 6 user reports the same issue
- The issue started after the Friday change window

---

## L2 - Triage Guidance

### Working assumption
The current leading operational hypothesis is that the Friday document management application deployment may be contributing to slow sign-in or login failure on Floor 6 devices.

### What L2 should check first
1. Confirm the affected user list and device list.
2. Compare the affected cohort with the Friday deployment scope.
3. Check whether the issue is login failure, slow login, or both.
4. Confirm whether the issue affects only Floor 6.
5. Confirm whether the user eventually reaches the desktop.

### Evidence L2 should gather
- Affected user names
- Device names
- First seen time
- Whether sign-in succeeds after retry
- Whether the user sees a long delay before the desktop appears
- Whether the user notices missing shortcuts or changed behavior after sign-in

### L2 decision points
- If the issue is limited to a small cohort, keep the incident scoped and continue targeted investigation.
- If the issue is broad across Floor 6, continue with the runbook steps below.
- If the issue appears outside Floor 6, escalate the scope immediately.
- If login failure and slow login appear to be separate patterns, track them separately rather than forcing one explanation.

### L2 guidance on communication
Use calm, plain language. Confirm that the issue is being investigated and that users should report device name, time, and exact symptom. Avoid speculation about root cause.

---

## Runbook - Controlled Investigation and Containment

### Goal
Reduce user impact while confirming whether the Friday application deployment is part of the problem.

### Step 1 - Confirm the impacted cohort
- Build the list of affected Floor 6 users and devices.
- Separate users who cannot sign in from users who can sign in but wait a long time.
- Note any users who report missing shortcuts or other changes.

Expected result:
- Clear list of who is affected and how.

### Step 2 - Compare against the Friday deployment scope
- Confirm which devices and users received the new document management application.
- Check whether the affected devices overlap with the deployment target.

Expected result:
- Confirmed overlap or confirmed mismatch.

### Step 3 - Hold further rollout if overlap is strong
- If the affected cohort matches the deployment cohort, pause any further expansion of the deployment.
- Keep the change limited until the issue is better understood.

Expected result:
- No additional users are exposed while the investigation continues.

### Step 4 - Apply the agreed rollback path if needed
- Use the approved removal or exclusion path for the suspected application.
- Limit the action to the affected Floor 6 cohort.
- Keep unaffected users outside the rollback scope.

Expected result:
- The suspected application is no longer active on the affected devices.

### Step 5 - Validate user experience after containment
- Confirm whether sign-in is now faster.
- Confirm whether affected users can reach the desktop normally.
- Confirm whether the issue stops recurring after sign-out and sign-in.

Expected result:
- Improvement in login behavior or clear evidence that another cause is still present.

### Step 6 - Continue to separate symptoms
- If some users only have slow logins while others cannot sign in, keep the patterns separate.
- Do not merge all reports into one explanation unless evidence supports that.

Expected result:
- Cleaner incident tracking and clearer next steps.

### Runbook stop conditions
Stop the runbook if:
- The issue is no longer appearing for the affected cohort
- Rollout containment is confirmed
- The evidence shows another issue is more likely

---

## Handoff Notes
- This document is a support handoff, not a final root cause report.
- It is meant to help L1 and L2 work from the same incident picture.
- It should be updated if the confirmed cause changes.

---

End of Document
