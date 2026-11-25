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

## Structure

```
Tide/
  App/TideApp.swift          entry point + root (onboarding ↔ today)
  Model/
    CycleCalendar.swift      cycle day + phase estimation (pure, tested)
    DailyPlan.swift          today's phase, encouragement, 4 actions
    CycleStore.swift         persisted settings + daily check-offs
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
    SettingsView.swift
    OnboardingView.swift     three questions
TideTests/                   cycle math + content tests
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

Tap **my period started today** on the cycle screen to reset day 1.

## A note on the content

The suggestions are general wellness ideas drawn from nutrition research and
traditional herbalism, and the evidence behind them varies. Where it matters,
the copy says so (for example, chasteberry is framed as "ask your clinician").
Tide is not medical advice and is not a contraceptive or fertility tool.
