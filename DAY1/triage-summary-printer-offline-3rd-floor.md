# Triage Summary — 3rd Floor Shared Printer Offline (Team-Wide)

*Analyst note: Produced under Personal AI Usage Charter — no real PII or device identifiers used.*

---

## Summary
Shared printer on 3rd floor is not working, affecting the whole team, with a time-critical client meeting at 14:00.

---

## Impact
- **Who:** Entire team on 3rd floor (number of users: to confirm)
- **How many affected:** Multiple — team-wide (exact headcount: to confirm)
- **Business urgency:** **High / Time-Critical** — client meeting at 14:00 today creates a hard deadline. Treat as priority until resolved or a print alternative is confirmed.

---

## Known Facts
- The affected device is a shared/floor printer on the 3rd floor (make/model/hostname: to confirm)
- The entire team is unable to print
- There is a client meeting at 14:00 today requiring printed materials (to confirm what specifically needs printing)
- No information on when the printer last worked (to confirm)
- No error message or status described by the user

---

## Missing Information to Gather
- [ ] Caller's name, staff ID, and team name
- [ ] Printer make, model, and asset tag or hostname
- [ ] When did it last print successfully?
- [ ] What is the printer displaying — any error lights, paper jam indicator, offline status on screen?
- [ ] Is the printer showing as offline in Windows (Devices & Printers) on affected machines?
- [ ] Has anything changed recently — office move, network maintenance, printer driver update?
- [ ] Is the print spooler service running on the print server (to confirm via IT monitoring or remote check)?
- [ ] Is there a secondary or nearby printer that could serve as a temporary alternative for the 14:00 meeting?
- [ ] What needs to be printed for the client meeting — volume and urgency?

---

## Likely Category
**Printing / Peripheral — Shared Printer Offline (Multi-User)**
Sub-category: Floor/network printer failure with business-critical time constraint

---

## Suggested First Diagnostic Step
**Immediately** identify a print alternative for the 14:00 meeting — ask the caller if there is another printer on a nearby floor or if documents can be presented digitally. This protects the business deadline while the fault is investigated in parallel.

Simultaneously, ask the caller to check the physical printer for:
1. Any error lights or messages on the printer's display panel
2. Whether the printer is powered on and shows a "Ready" state

This determines whether the fault is physical (paper jam, offline, no power) or network/spooler-based, and splits the diagnostic path before any remote investigation is needed.
