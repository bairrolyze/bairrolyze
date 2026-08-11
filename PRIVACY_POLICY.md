# Privacy Policy — Bairrolyze

**Last updated: 11 August 2026**

This Privacy Policy explains how **Tellura** ("we",
"us", "our") handles information in connection with the **Bairrolyze** mobile
application (the "App"). We have designed Bairrolyze to collect as little personal
data as possible: **the App has no user accounts and no advertising or analytics
tracking.**

By using the App you agree to the practices described in this policy.

---

## 1. Summary (the short version)

- We do **not** require you to create an account or sign in.
- We do **not** use advertising SDKs, analytics SDKs, or third-party trackers.
- The **address or location you look up** is sent to our backend service and to
  mapping/data providers solely to generate a neighbourhood score. We do not use
  it to identify you.
- Your **search history and saved places are stored only on your device**, not on
  our servers.
- Purchases are processed by **the app store and RevenueCat** — we never see your
  full payment card details.

---

## 2. Information we process

### a) Location and address data
When you search an address — or grant location permission and use "use my current
location" — the App sends that **address or the coordinates** to our backend so we
can look up nearby amenities and calculate a Location Score. This data is used only
to fulfil your request. We do not attach it to a persistent identifier and we do not
build a profile of you.

Granting location permission is **optional**; you can always type an address instead.
You can revoke location permission at any time in your device settings.

### b) Data stored locally on your device
The following are stored **only on your device** (using on-device storage such as
Hive and system preferences) and are **not transmitted to us**:
- Your recent search history.
- Places you save/bookmark.
- App settings and preferences.

Deleting the App removes this local data.

### c) Purchase information (Bairrolyze Pro, if used)
If you buy a subscription or one-time purchase, the transaction is handled by the
**Apple App Store / Google Play** and by **RevenueCat**, our subscription
infrastructure provider. They process a purchase token and receipt to validate your
entitlement. **We do not receive or store your full payment card number.** See
RevenueCat's privacy policy: https://www.revenuecat.com/privacy/

### d) Technical data
Standard network information (such as your IP address) is necessarily processed by
our hosting provider and the third-party APIs below in order to deliver a response.
We do not use this to identify you and we do not retain it for tracking purposes.

**We do not knowingly collect:** your name, email, contacts, photos, precise
persistent identifiers for advertising, or health/financial data.

---

## 3. Third-party services

To turn an address into a neighbourhood score, our backend queries the following
providers. Only the address/coordinates and technical request data needed to answer
your query are shared with them:

| Provider | Purpose | Privacy policy |
|---|---|---|
| OpenStreetMap / Nominatim | Geocoding (address → coordinates) | https://osmfoundation.org/wiki/Privacy_Policy |
| Overpass API | Nearby amenities (schools, transit, etc.) | https://openstreetmap.org/copyright |
| OpenRouteService | Walking/driving travel times (optional) | https://openrouteservice.org/privacy-policy/ |
| OpenAI | Generating the written neighbourhood summary | https://openai.com/policies/privacy-policy |
| UK Police API (data.police.uk) | Crime statistics for UK addresses | https://www.police.uk/pu/about-police-uk-crime-data/ |
| RevenueCat | In-app purchase / subscription validation | https://www.revenuecat.com/privacy/ |

These providers process the data as independent controllers or as our processors,
under their own privacy policies.

---

## 4. How we use information

We use the information described above only to:
- Geocode your query and calculate the neighbourhood Location Score;
- Generate the amenity breakdown and written summary you requested;
- Validate and provide access to paid features you purchase;
- Operate, secure, and debug the service.

We do **not** sell your personal data, and we do **not** use it for advertising.

---

## 5. Legal basis (EEA/UK — GDPR)

Where GDPR applies, our legal bases are:
- **Performance of a contract / your request** (Art. 6(1)(b)) — to process the
  address you ask us to score and to deliver purchased features.
- **Legitimate interests** (Art. 6(1)(f)) — to keep the service secure and working.
- **Consent** (Art. 6(1)(a)) — for device location access, which you may withdraw at
  any time via device settings.

---

## 6. Data retention

- **On-device data** (search history, saved places) remains until you delete it in
  the App or uninstall the App.
- Address lookups sent to our backend may be **cached temporarily** to improve
  performance and reduce load on third-party APIs; caches expire automatically and
  are not used to identify you.
- We do not maintain user-level profiles or long-term personal records.

---

## 7. Your rights

Depending on your location (including under the EU/UK GDPR), you may have the right
to access, correct, delete, or restrict processing of your personal data, to object
to processing, and to data portability. Because the App has no accounts and stores
your history only on your device, you can exercise most of these rights directly by
clearing data in the App or uninstalling it. For any other request, contact us at
the address below. You also have the right to lodge a complaint with your local data
protection authority (in Portugal, the **CNPD** — https://www.cnpd.pt).

---

## 8. Children's privacy

Bairrolyze is not directed to children under 13 (or the minimum age required in your
country), and we do not knowingly collect personal data from them.

---

## 9. International transfers

Some third-party providers listed above (for example, OpenAI and RevenueCat) may
process data outside the EEA/UK. Where required, such transfers are covered by
appropriate safeguards such as the European Commission's Standard Contractual
Clauses.

---

## 10. Changes to this policy

We may update this Privacy Policy from time to time. The "Last updated" date at the
top reflects the latest version. Material changes will be reflected in the App or on
this page.

---

## 11. Contact

**Tellura**
Email: **info@bairrolyze.com**

If you are in the EEA/UK and have concerns we cannot resolve, you may contact your
local supervisory authority.
