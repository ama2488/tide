# Getting persi into the App Store

Everything Apple will ask for, in order. Items in **[BRACKETS]** are yours to fill in.

---

## 1. Before you start

- [ ] **Join the Apple Developer Program** at developer.apple.com/programs ($99/year).
  - *Individual* is quickest, but the App Store lists **your legal name** as the seller.
  - *Organization* (e.g. an LLC) shows the business name instead, but needs a free
    D-U-N-S number and takes longer to approve.
- [ ] **Host the privacy policy** (`AppStore/privacy.html`) at a public link. Fill in the
  date and support email first. Easy options: GitHub Pages, Netlify Drop (drag the file
  in), or paste the text into a Notion/Carrd page.
- [ ] **Choose the final bundle ID**, e.g. `com.[yourname].persi`. It can never change
  after the first upload. Users never see it.
  - Keep the one already on your phone if you want your current data to carry over.
  - Picking a new one is fine too; your phone will treat it as a new app.

## 2. In Xcode

- [ ] **Signing & Capabilities:** set **Team** to your *paid* developer team.
- [ ] **Version:** 1.0 (Build 1) is fine for the first upload. Raise the build number for
  every upload after that (Xcode can do it for you when distributing).
- [ ] **Run the tests** (⌘U) and try the app once more on your phone.
- [ ] Set the run destination to **Any iOS Device (arm64)**, then **Product → Archive**.
- [ ] In the Organizer window: **Distribute App → App Store Connect → Upload**.

Already set in the project: the HealthKit entitlement, the Health permission text, the app
icon, and `ITSAppUsesNonExemptEncryption = NO` (so you won't be asked about export
compliance on each upload).

## 3. In App Store Connect (appstoreconnect.apple.com)

- [ ] **My Apps → + → New App**
  - Platform: iOS
  - Name: **persi: cycle rituals** (must be unique on the App Store)
  - Primary language: English (U.S.)
  - Bundle ID: the one from step 1
  - SKU: anything, e.g. `persi-ios`
- [ ] **TestFlight first:** add yourself, then friends via a public link. Live with it for
  a week or two before submitting.
- [ ] Fill in the listing (section 4), privacy (section 5) and age rating, add
  screenshots, pick the build, and **Submit for Review**. Reviews usually take 1–2 days.

---

## 4. Listing copy

**Name** (30 max)
> persi: cycle rituals

**Subtitle** (30 max)
> your cycle, day by day

**Category**
> Primary: Health & Fitness · Secondary: Lifestyle

**Promotional text** (170 max, can be changed anytime without review)
> a gentle daily guide to living with your cycle, not against it. foods, herbs, movement and rituals for exactly where you are today.

**Description**
> persi is a quiet, hand-drawn companion for living with your cycle, not against it.
>
> open it and you'll see where you are, one line of encouragement, and a few small things to try today:
>
> · nourish: a food that supports this phase
> · steep: an herb or tea
> · move: the kind of movement your body is ready for
> · tend: a small practice for your mind and your days
> · seeds: optional seed cycling, with a nudge when it's time to switch
>
> tap "why" on anything to learn what's happening in your body and why it helps right now. the rest stays out of the way.
>
> made around your rhythm
> · menstrual, follicular, ovulatory and luteal phases, with gentler suggestions in the last days before your period
> · log your periods and persi learns your real cycle length
> · optionally read period days from Apple Health, including from Apple Cycle Tracking and other apps
>
> your rituals, too
> · add the teas, foods and practices you already love, for the phases they belong to
> · group several into one protocol, like a set of cycle-sync teas
> · they show up on exactly the right days
>
> private by design
> · no account, no login, no ads
> · everything stays on your phone
>
> persi offers general wellness ideas, not medical advice, and is not a contraceptive or fertility tool. check with a clinician before starting any new herb or supplement.

**Keywords** (100 max, commas, no spaces; don't repeat words already in the name)
> period,cycle syncing,luteal,follicular,ovulation,herbal tea,seed cycling,pms,hormones,wellness,moon

**Support URL** → [your privacy page URL, or a simple support page]
**Privacy Policy URL** → [your hosted privacy.html]
**Copyright** → 2026 [your name or business]

## 5. App Privacy ("nutrition label")

- **Do you or your third-party partners collect data from this app?** → **No**
- Result shown on the App Store: **Data Not Collected**

This is accurate because nothing ever leaves the device. If you ever add analytics, sync,
purchases tied to an account, or sponsors that track, this answer must change.

## 6. Age rating

Answer the questionnaire honestly. The relevant topic is **medical or treatment
information** (general wellness and herbal suggestions): answer *infrequent / mild*.
Everything else is *none*. Apple calculates the rating from your answers.

## 7. Screenshots

Required: **6.9" iPhone** screenshots (1320 × 2868 portrait). Take them in the Simulator
with the largest current *Pro Max* iPhone: press **⌘S** and they save to your Desktop.
3–5 screenshots is plenty:

1. **Today**: phase, encouragement, actions
2. **A "why" sheet**: shows the depth behind each suggestion
3. **Your rituals / a protocol row on Today**
4. **The cycle wheel**
5. **A phase page**: hormones sketch and lists

Tip: set up a nice-looking day first (log a period so the phase is right, add one ritual,
check off an item or two). Light mode reads best in the store.

## 8. Notes for App Review

Paste into *App Review Information → Notes*:

> persi works fully offline with no account or login. To review: complete the short
> onboarding (any dates work). The Today screen shows the current cycle phase and daily
> suggestions; tap "why" on any row for details. Apple Health access is optional and
> read-only (menstrual flow days only). It can be tested in Settings → connect apple
> health. No data leaves the device. The app offers general wellness information with a
> clear "not medical advice" disclaimer in settings and on herb details.

No demo account is needed.

## 9. Common reasons apps like this get rejected, and how persi already handles them

| Guideline | What Apple checks | persi |
|---|---|---|
| 5.1.1 Privacy | Privacy policy link, accurate privacy label | `privacy.html`, "Data Not Collected" |
| 5.1.3 Health data | HealthKit data never used for ads or stored in iCloud | read-only, on-device only |
| 2.5.1 HealthKit | Health integration is clear in the app | "connect apple health" in settings and onboarding, with explanation |
| 1.4.1 Medical | No unproven medical claims | "may", "traditionally used", disclaimers |
| 4.2 Minimum functionality | More than a simple website | native, interactive, personalized |
