# Rollout Feedback — Theme Analysis and Priority Ranking

| Field | Detail |
|---|---|
| **Title** | End-User Feedback Theme Analysis and Priority Ranking |
| **Version** | 1.0 |
| **Date** | 12/08/2026 |
| **Author** | Copilot |
| **Reviewed by** | Pending |
| **Status** | Draft |
| **Comment set** | 15 comments, post-rollout feedback |

---

## Part 1 — Theme Clusters

---

### Theme 1 — Credentials Vault Inaccessibility

**Count:** 3

**Severity:** Blocker

**Representative quotes:**
- *"Shared credentials vault is completely inaccessible, whole team blocked."*
- *"Third day now I can't access the credentials vault, this is urgent."*

---

### Theme 2 — Admin Console Lockouts

**Count:** 2

**Severity:** Blocker

**Representative quotes:**
- *"Second engineer this week locked out of the admin console entirely."*
- *"Admin console lockouts happening across the whole team now, not just one person."*

---

### Theme 3 — VM and Remote Access Failure

**Count:** 2

**Severity:** Blocker

**Representative quotes:**
- *"Can't remote into any of my test VMs since the update, blocking my whole day."*
- *"My test VM access is still down, can't do my job today either."*

---

### Theme 4 — UI and Interface Changes

**Count:** 4

**Severity:** Minor

**Representative quotes:**
- *"Font in the new portal is slightly smaller, hard to read for some of us."*
- *"Notification sounds changed, mildly annoying but not a big deal."*

---

### Theme 5 — Positive Feedback and Rollout Satisfaction

**Count:** 4

**Severity:** Positive

**Representative quotes:**
- *"Overall the rollout felt smoother than last time, appreciate it."*
- *"Nice that the new theme supports dark mode properly now."*

---

## Part 2 — Top 2 Themes to Act On Today

Ranking weighs both volume (number of comments) and impact (Blocker / Friction / Minor / Positive). A small number of Blocker comments outranks a larger number of Minor comments.

---

### Rank 1 — Credentials Vault Inaccessibility

**Count:** 3  
**Severity:** Blocker

**Why it ranks first:**
Three independent comments, all Blocker severity, spanning at least three days (comment 8 explicitly states "third day now"). The language escalates across the set: "whole team blocked" (comment 5), "this is urgent" (comment 8), "escalated to my manager" (comment 14). This is not a single user encountering a one-off error — it is a persistent, team-wide outage of a shared credential store that has already reached manager escalation. Every day this remains unresolved, the blast radius and reputational cost to IT grows. Volume and severity both point to this as the immediate priority.

**Manager update:**
The shared credentials vault has been inaccessible for at least three days, blocking the whole team and already escalated by users to their manager — this needs an owner assigned and a resolution ETA communicated today.

---

### Rank 2 — Admin Console Lockouts

**Count:** 2  
**Severity:** Blocker

**Why it ranks second:**
Only two comments, but the trajectory is the critical factor. The first comment describes one engineer locked out; the second confirms the issue has spread to the whole team. This is an expanding blast radius — a Blocker that was initially individual is now department-wide. Left unaddressed, the comment pattern suggests it will worsen further. It ranks above VM access (also 2 comments, also Blocker) because the scope language — "not just one person" and "whole team now" — indicates active spread rather than a contained individual failure.

**Manager update:**
Admin console lockouts have escalated from a single engineer to the whole team within days — this is an expanding access outage that needs immediate investigation to stop further spread.

---

## Ranking decision note

VM and remote access failure (Theme 3) is also Blocker severity with 2 comments and would be the next priority after Themes 1 and 2. It is not ranked today solely because the scope language ("blocking my whole day", "can't do my job today either") describes individual impact rather than confirmed team-wide spread. It should not be deprioritised — assign an owner once Themes 1 and 2 have owners confirmed.

---

*This analysis covers 15 feedback comments. Themes 4 and 5 (UI changes and positive feedback) require no action today.*

---

## Part 3 — Corrected Full Ranking (Severity-Primary)

The Part 2 ranking correctly placed two Blockers in the top 2 positions. However, the rationale for placing Admin Console above VM Access relied partly on scope language and trajectory — which is a volume-adjacent argument. The note at the end of Part 2 also framed VM Access as something to address "once Themes 1 and 2 have owners confirmed", implying it could wait. That framing is wrong: a Blocker affecting even one person outranks a Minor issue affecting many.

Below is the corrected full ranking with severity as the primary criterion and volume as a tiebreaker only within the same severity tier.

| Rank | Theme | Count | Severity | Primary ranking driver |
|---|---|---|---|---|
| 1 | Credentials Vault Inaccessibility | 3 | Blocker | Highest volume within Blocker tier; team-wide; 3+ days unresolved; manager already escalated |
| 2 | Admin Console Lockouts | 2 | Blocker | Blocker tier; active scope expansion confirmed across comments |
| 3 | VM and Remote Access Failure | 2 | Blocker | Blocker tier; individuals cannot perform their job — severity alone places this above all Minor issues regardless of count |
| 4 | UI and Interface Changes | 4 | Minor | Higher volume than Ranks 2 and 3 but Minor severity — does not displace a Blocker |
| 5 | Positive Feedback | 4 | Positive | No action required |

### What changed and why

**VM and Remote Access (Theme 3) moves from an afterthought to Rank 3.**
In Part 2 it was noted as "next priority" but framed as something to pick up later. Corrected: two engineers unable to do their jobs is a Blocker by definition. It belongs in the active action list today, not in a queue behind lower-severity items. The fact that it affects fewer people than the UI theme (2 vs 4 comments) is irrelevant — severity trumps volume.

**UI and Interface Changes (Theme 4) stays at Rank 4 despite having 4 comments.**
Four comments, zero Blocker severity. Under a volume-first approach this theme would surface near the top. Under severity-first it cannot displace any Blocker regardless of count. "Font is slightly smaller" and "notification sounds changed" do not compete with "can't do my job today."

**The tiebreaker within the Blocker tier remains scope.**
Vault (Rank 1) leads because it has both the highest count and the clearest evidence of team-wide, multi-day impact. Admin Console (Rank 2) edges VM Access (Rank 3) because the comments confirm active spread to the whole team, whereas VM Access comments describe individual failures without confirmed spread. This is a scope-of-impact tiebreaker within the same severity tier — not a volume argument.

### Corrected rule of thumb

> All Blockers, regardless of comment count, must be actioned before any Friction, Minor, or Positive theme receives attention. Within the Blocker tier, use scope of impact (individual vs team-wide) and trajectory (stable vs spreading) as tiebreakers. Volume is the last resort tiebreaker only.
