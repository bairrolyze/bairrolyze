# Google Play — Data Safety form answers (Bairrolyze)

Fill this in at **Play Console → App content → Data safety**. The answers below
match `PRIVACY_POLICY.md` / `landing/privacy.html`. Keep the two consistent — Play
cross-checks the form against your policy and your app's actual behaviour.

**Privacy policy URL to enter:** `https://rajesharyain.github.io/bairrolyze/privacy.html`

---

## Section 1 — Data collection & security (overview)

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (location + purchase info leave the device) |
| Is all collected data encrypted in transit? | **Yes** (HTTPS to the backend and all third-party APIs) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — data is on-device; uninstalling/clearing the app deletes it (state this in the justification box) |

> "Collected" in Play's terms = data that leaves the device, even transiently.
> Your on-device search history / saved places are **not** "collected" and are **not**
> declared. The address sent to the backend **is** collected (it's transmitted).

---

## Section 2 — Data types to declare

### ✅ Location → **Approximate location** and/or **Precise location**
- **Collected:** Yes
- **Shared:** Yes (sent to third-party geocoding/amenity/AI providers to compute the score)
- **Processed ephemerally?** You may mark **No** (it can be briefly cached) — if unsure, leave unchecked.
- **Required or optional:** **Optional** (users can type an address instead of using GPS)
- **Purpose:** **App functionality** (only)
- Declare **Precise** if you use GPS coordinates from `geolocator`; **Approximate** covers typed-address lookups. Declaring **Precise** is the safe superset.

### ✅ Financial info → **Purchase history**
- **Collected:** Yes (via Google Play Billing / RevenueCat, only if Pro is live at launch)
- **Shared:** Yes (RevenueCat, as purchase-validation processor)
- **Purpose:** **App functionality**
- **Required or optional:** **Optional**
- *If you ship without any IAP at launch, skip this entire row.*

### ❌ Do NOT declare (the app does not collect these)
Personal info (name/email), Contacts, Photos/Videos, Files, Calendar, Messages,
Health, Web browsing history, and — importantly — **App activity / Analytics** and
**Device or other IDs for advertising** (you have no analytics or ad SDKs).

---

## Section 3 — Security practices (justification text you can paste)

> Bairrolyze has no user accounts. Search history and saved places are stored only
> on the user's device and are never transmitted to us. The only data that leaves the
> device is (a) the address or coordinates the user chooses to look up, sent over
> HTTPS to our backend and mapping/AI providers solely to calculate a neighbourhood
> score, and (b) purchase-validation tokens handled by Google Play Billing and
> RevenueCat. No advertising or analytics SDKs are used. Users can delete all local
> data by clearing app storage or uninstalling the app.

---

## Consistency checklist (do these before submitting)

- [ ] Privacy policy is live at the URL above (push to `main`, confirm Pages deployed).
- [ ] Same URL entered in **Data safety** *and* in **Store listing → Privacy policy**.
- [ ] Location declared as **Optional / App functionality / Shared**.
- [ ] Purchase history declared **only if** IAP ships at launch.
- [ ] No analytics/ads data types declared.
- [ ] In-app Privacy Policy link works (Settings → Legal → Privacy Policy).
