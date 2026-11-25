# tide

A gentle, native iOS guide to living with your menstrual cycle, not against it.

Open the app and you see where you are, one line of encouragement, and four
small things to try today: something to **nourish** you, something to **steep**,
a way to **move** and a way to **tend** to yourself. Check them off as you go.
Tap any of them to see *why it helps right now*. The deeper reading on hormones
and the full menu for each phase is one tap further down.

## Running it

Requirements: a Mac with **Xcode 16+**, iOS 17+ simulator or device.

1. Open `Tide.xcodeproj`.
2. Choose the **Tide** scheme and an iPhone simulator.
3. ⌘R. (To run on a device, set your team under *Signing & Capabilities*.)
4. ⌘U runs the unit tests for the cycle math and content.

No dependencies, no accounts, no network. Everything is stored on the device
in `UserDefaults`.

### Trying Apple Health in the simulator
The simulator has its own Health app. Open it → *Browse* → *Cycle Tracking* →
log a few periods a month apart. Then in tide: *settings → connect apple health*.

## Period log

Every "my period started / ended" tap is saved. Once there are **two complete
cycles** (three logged starts), tide uses the average of your last six cycles
and periods instead of the numbers you entered at setup. Gaps over 45 days are
treated as a missed log and skipped. You can turn learning off in settings.

Around the edges of a period a small card appears on Today: *did your period
start?* (from two days before it's due) or *has your period ended?* (from the
expected last day). A late period reads as a longer luteal phase ("running 3
days long") for up to 10 days, rather than jumping to day 1.

## Apple Health

Read-only. tide reads menstrual flow days from HealthKit, whichever app wrote
them (Apple Cycle Tracking, Oura, Natural Cycles…), groups them into periods,
and merges them into the log. A period you logged in tide always wins; Health
only fills in its end date. Sync runs when the app opens.

## Structure

```
Tide/
  App/TideApp.swift          entry point + root (onboarding ↔ today)
  Model/
    CycleCalendar.swift      cycle day + phase estimation (pure, tested)
    DailyPlan.swift          today's phase, encouragement, 4 actions
    CycleStore.swift         persisted settings, period log, check-offs
    PeriodLog.swift          period entries, learned averages, prompts, grouping
    HealthSync.swift         read-only Apple Health import
    Phase.swift              phases, colors, suggestion types
    Library.swift            all copy: foods, herbs, movement, practices, words
  Design/
    Theme.swift              palette, type, buttons, steppers
    HandDrawn.swift          wobbly circle/line/capsule/arc, paper grain, check
    PhaseGlyph.swift         moon glyphs, cycle wheel, hormone sketch
  Views/
    TodayView.swift          the main screen
    SuggestionSheet.swift    tap an action → why
    PhaseDetailView.swift    hormones, how you might feel, full lists
    CycleView.swift          the whole cycle + "my period started today"
    PeriodViews.swift        Today prompt card, log/edit sheet, history
    SettingsView.swift
    OnboardingView.swift     three questions (+ optional Apple Health)
TideTests/                   cycle math, content, period log tests
```

## Design notes

- **Co–Star:** monochrome base, lowercase voice, tiny monospaced labels, line art,
  a dark mode that goes near-black with cream ink.
- **Nobody Wants This:** warm cream paper, a 70s palette (clay, sage, marigold,
  plum), italic serif headlines, a romantic, slightly wry tone of voice.
- **Headspace:** soft rounded halos, a slow breathing animation on the moon,
  friendly encouragement, one clear next step.
- **Made by hand:** every circle, line, pill and arc is drawn with a seeded wobble
  (same every render, never jittery), plus a faint paper grain.
- **Simplicity over information:** the Today screen shows a phase, one sentence and
  four actions. Explanations only appear when you ask for them.

## How phases are estimated

Day 1 is the first day of bleeding. Ovulation is estimated at
`cycleLength − 14` (the luteal phase is the most consistent part of the cycle):

| phase      | days (28-day cycle, 5-day period) |
|------------|-----------------------------------|
| menstrual  | 1 – period length                 |
| follicular | after the period, until 2 days before ovulation |
| ovulatory  | ovulation day ± 1                 |
| luteal     | the rest                          |

Tap **my period started today** (cycle screen) or answer the prompt on Today to start a new cycle.

## A note on the content

The suggestions are general wellness ideas drawn from nutrition research and
traditional herbalism, and the evidence behind them varies. Where it matters,
the copy says so (for example, chasteberry is framed as "ask your clinician").
Tide is not medical advice and is not a contraceptive or fertility tool.
