# Triage Summary — T-1001

## Summary
New Windows 11 laptop is prompting for a BitLocker recovery key on every boot.

## Impact
- Who: Single named user (identity not provided in ticket: to-verify)
- How many: 1 device confirmed; whether other new laptops are affected is unknown (to-verify)
- Business urgency: High — user cannot access device without recovery key at every restart, blocking productive use

## Known Facts
- Device is a new Windows 11 laptop
- BitLocker is active on the device
- Recovery key prompt is appearing on every boot (not a one-off event)
- Ticket reference: T-1001

## Missing Information to Gather
- User name, team, and contact details (to-verify)
- Device make, model, and asset/serial number (to-verify)
- Whether the recovery key is known/available to the user or IT (to-verify)
- Whether the device was enrolled via Intune/SCCM/MECM or imaged manually (to-verify)
- Whether any TPM, BIOS/UEFI, Secure Boot, or firmware changes were made or are pending (to-verify)
- Whether this is a rebuilt/reimaged device or brand new out of box (to-verify)
- Whether any other new laptops from the same batch are showing the same behaviour (to-verify)
- Whether the device successfully boots when the key is entered, or fails after (to-verify)

## Likely Category
Endpoint Security / BitLocker — TPM or Secure Boot configuration issue on new device (to-verify; could also be Intune policy, incorrect provisioning, or BIOS/UEFI setting causing TPM not to be trusted at each boot)

## First Diagnostic Step
Check TPM status and Secure Boot configuration in BIOS/UEFI, and review the device's BitLocker protection status using the device management tooling (to-verify which tooling is in use: Intune, SCCM, or local) to confirm whether the TPM protector is present and active, or if the device is relying solely on the recovery key protector.
