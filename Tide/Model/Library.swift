import Foundation

// All copy lives here. Voice: lowercase, warm, a little wry, never preachy.
// Actions are short and doable today. The "why" is the secondary layer.

enum Library {
    static func content(for phase: Phase) -> PhaseContent {
        switch phase {
        case .menstrual: menstrual
        case .follicular: follicular
        case .ovulatory: ovulatory
        case .luteal: luteal
        }
    }

    private static func food(_ name: String, _ action: String, _ why: String) -> Suggestion {
        Suggestion(kind: .nourish, name: name, action: action, why: why)
    }
    private static func herb(_ name: String, _ action: String, _ why: String) -> Suggestion {
        Suggestion(kind: .steep, name: name, action: action, why: why)
    }
    private static func move(_ name: String, _ action: String, _ why: String) -> Suggestion {
        Suggestion(kind: .move, name: name, action: action, why: why)
    }
    private static func tend(_ name: String, _ action: String, _ why: String) -> Suggestion {
        Suggestion(kind: .tend, name: name, action: action, why: why)
    }

    // MARK: - Seed cycling

    /// The two halves of seed cycling: flax + pumpkin from day 1 through
    /// ovulation, sunflower + sesame from ovulation until the next period.
    enum SeedHalf { case first, second }

    static func seedHalf(forDay day: Int, ovulationDay: Int) -> SeedHalf {
        day <= ovulationDay ? .first : .second
    }

    static func seeds(_ half: SeedHalf) -> Suggestion {
        switch half {
        case .first:
            Suggestion(
                kind: .seeds,
                name: "flax + pumpkin",
                action: "a tablespoon each of ground flax and pumpkin seeds",
                why: "seed cycling pairs different seeds with the two halves of your cycle. from your period until ovulation, it's flax and pumpkin: flax's lignans may help your body balance rising estrogen, and pumpkin seeds are rich in zinc, which supports the follicle as it matures. grind the flax (or buy it ground) so your body can use it. research on seed cycling itself is still thin, so treat it as a simple, nourishing daily ritual rather than a treatment. persi will tell you when to switch."
            )
        case .second:
            Suggestion(
                kind: .seeds,
                name: "sunflower + sesame",
                action: "a tablespoon each of sunflower and sesame seeds",
                why: "after ovulation, seed cycling switches to sunflower and sesame. sunflower seeds bring vitamin e and selenium, and sesame brings zinc and its own lignans, nutrients traditionally used to support progesterone in the second half of the cycle. research on seed cycling itself is still thin, so treat it as a simple, nourishing daily ritual rather than a treatment. you'll switch back to flax and pumpkin when your next period starts."
            )
        }
    }

    /// Today's seeds, with a nudge on the days it changes over.
    static func seeds(forDay day: Int, ovulationDay: Int) -> Suggestion {
        let half = seedHalf(forDay: day, ovulationDay: ovulationDay)
        let base = seeds(half)
        var note: String?
        if half == .first && day == 1 { note = "new cycle, back to: " }
        if half == .second && day == ovulationDay + 1 { note = "time to switch: " }
        guard let note else { return base }
        return Suggestion(kind: base.kind, name: base.name, action: note + base.action, why: base.why)
    }

    /// Which seeds belong to a phase, for the phase detail page.
    static func seeds(for phase: Phase) -> [Suggestion] {
        switch phase {
        case .menstrual, .follicular: [seeds(.first)]
        case .ovulatory: [seeds(.first), seeds(.second)]
        case .luteal: [seeds(.second)]
        }
    }

    // MARK: - Menstrual · inner winter

    static let menstrual = PhaseContent(
        tagline: "turn inward.",
        hormones: "estrogen and progesterone are at their lowest. that drop is the signal for your uterine lining to shed. prostaglandins — the compounds that help the uterus contract — peak now, which is where cramps come from. with less hormonal fuel, energy naturally dips.",
        feel: "tired, tender, quieter. many people also feel a kind of clarity here — less noise, more honesty. it's a good time to rest, reflect and replenish what you're losing.",
        foods: [
            food("lentils",
                 "make a warm bowl of lentil soup",
                 "you lose iron as you bleed. lentils bring iron, protein and fiber, and warm, cooked food is easy on a body that's already working hard."),
            food("dark leafy greens + lemon",
                 "add dark greens with a squeeze of lemon",
                 "spinach, chard and kale offer iron and magnesium. the vitamin c in lemon helps your body absorb plant iron far better."),
            food("dark chocolate",
                 "have two squares of dark chocolate, 70% or more",
                 "dark chocolate is rich in magnesium, which helps muscles — including the uterus — relax. the craving is real; answer it gently."),
            food("broth or miso",
                 "sip a mug of broth or miso",
                 "minerals, salt and warmth with almost no effort. hydration helps with fatigue, and warmth relaxes the belly."),
            food("beets",
                 "roast a few beets for dinner",
                 "beets carry folate and minerals that support rebuilding blood, and their earthy sweetness is grounding when energy is low."),
        ],
        herbs: [
            herb("ginger",
                 "steep fresh ginger with a little honey",
                 "ginger is one of the best-studied herbs for period cramps — several trials found it comparable to common pain relievers when started at the onset of bleeding. it's warming, too."),
            herb("red raspberry leaf",
                 "brew a cup of red raspberry leaf tea",
                 "a traditional uterine tonic, long used by herbalists to support the muscles of the uterus. the evidence is mostly traditional — enjoy it as a ritual."),
            herb("nettle leaf",
                 "brew a strong cup of nettle",
                 "nettle is mineral-dense — iron, calcium, magnesium — and has been used for generations to replenish what's lost during bleeding."),
            herb("chamomile",
                 "end the day with chamomile",
                 "chamomile is gently antispasmodic and calming. it may ease cramping and makes a soft doorway into sleep."),
        ],
        movement: [
            move("slow walk",
                 "take a slow, 20-minute walk",
                 "gentle movement boosts circulation and releases endorphins, which may ease cramps — without asking much of a body running on low hormones."),
            move("restorative yoga",
                 "rest in child's pose and gentle twists for 10 minutes",
                 "slow, supported shapes release tension in the hips and lower back, where period discomfort tends to collect."),
            move("stretch",
                 "stretch your hips and low back before bed",
                 "loosening the pelvis and lumbar muscles can relieve the dull ache that comes with menstrual contractions."),
            move("rest day",
                 "take a full rest day. it counts.",
                 "your body is doing real physiological work right now. recovery is part of training, not a break from it."),
        ],
        practices: [
            tend("heat",
                 "rest with a warm compress on your belly",
                 "heat relaxes the uterine muscle and improves blood flow. studies show it can ease cramps about as well as some over-the-counter options."),
            tend("let go",
                 "write down one thing you're ready to let go of",
                 "with hormones at their quietest, attention tends to turn inward. many people find this the most honest, reflective point of the month."),
            tend("early night",
                 "go to bed 30 minutes earlier",
                 "sleep is often lighter around your period. extra time in bed helps you recover the energy that low hormones and blood loss take."),
            tend("cancel something",
                 "cancel one non-essential plan",
                 "protecting your energy now pays you back in the weeks ahead. you're allowed to be unavailable."),
        ],
        encouragements: [
            "you're allowed to be a closed door today.",
            "rest is not a reward. it's the work.",
            "the tide goes out so it can come back in.",
            "softness is a strategy.",
            "do less, on purpose.",
            "nothing is wrong with you. you're just in winter.",
        ]
    )

    // MARK: - Follicular · inner spring

    static let follicular = PhaseContent(
        tagline: "begin again.",
        hormones: "follicle-stimulating hormone (fsh) wakes up a handful of follicles in your ovaries, and as one matures it releases estrogen. estrogen climbs steadily through this phase, rebuilding your uterine lining — and lifting mood, energy, focus and verbal ease along with it.",
        feel: "lighter, curious, more social, more willing. this is a natural window for starting things, learning things and saying yes.",
        foods: [
            food("fermented foods",
                 "add a forkful of kimchi or sauerkraut",
                 "your gut helps recycle and clear estrogen through a group of microbes nicknamed the estrobolome. fermented foods support that ecosystem as estrogen rises."),
            food("avocado",
                 "add half an avocado to a meal",
                 "healthy fats are the raw material for hormones, and avocado brings fiber and vitamin e alongside them as estrogen builds."),
            food("broccoli sprouts",
                 "top lunch with a handful of broccoli sprouts",
                 "sprouts are a concentrated source of sulforaphane, which supports the liver pathways that process estrogen as it rises."),
            food("eggs",
                 "build your breakfast around eggs",
                 "protein, b vitamins and choline give your body raw material for rising energy as the follicle matures."),
            food("something bright",
                 "eat something fresh and bright — a big salad or citrus",
                 "rising estrogen often brings better digestion and a lighter appetite. crisp, fresh foods tend to feel good now."),
        ],
        herbs: [
            herb("nettle leaf",
                 "keep your minerals up with a cup of nettle",
                 "after bleeding, nettle's iron, calcium and magnesium help you rebuild while energy returns."),
            herb("lemon balm",
                 "steep lemon balm for a clear, easy focus",
                 "lemon balm is calming yet uplifting; small studies suggest it supports mood and concentration — a nice match for a phase made for new ideas."),
            herb("green tea",
                 "trade your second coffee for green tea",
                 "l-theanine plus gentle caffeine gives steady focus without the spike, and its antioxidants support your liver's work processing hormones."),
        ],
        movement: [
            move("something new",
                 "try a class you've never done",
                 "estrogen supports mood, motivation and coordination. it's the easiest time of the month to learn a new skill or movement pattern."),
            move("run or hike",
                 "go for a run or a brisk hike",
                 "energy and endurance build as estrogen rises, and many people recover a little faster in this phase."),
            move("dance",
                 "dance in your kitchen to three songs",
                 "playful cardio matches the bubbly energy of spring. no form required."),
            move("cardio",
                 "do 30 minutes of cardio that makes you sweat",
                 "your body handles carbohydrates well here and tends to feel strong — a good time to build aerobic fitness."),
        ],
        practices: [
            tend("start",
                 "start the project you've been circling",
                 "rising estrogen boosts dopamine and the drive to begin. ride the momentum while it's here."),
            tend("brainstorm",
                 "write down ten ideas. keep one.",
                 "verbal fluency and creative thinking get a lift from estrogen. capture it on paper."),
            tend("plan",
                 "plan the week ahead",
                 "you have the energy to look forward now. future-you, in luteal, will be grateful for the structure."),
            tend("say yes",
                 "say yes to plans with a friend",
                 "social energy rises with estrogen. connection now refuels you for the quieter weeks."),
        ],
        encouragements: [
            "say yes to the thing you'd normally overthink.",
            "begin badly. that's how beginnings go.",
            "you're more curious than you are afraid. use that.",
            "new ideas are drawn to you right now. keep a pen close.",
            "plant something today. it doesn't have to be a seed.",
            "you don't need a plan to start. you need a first step.",
        ]
    )

    // MARK: - Ovulatory · inner summer

    static let ovulatory = PhaseContent(
        tagline: "be seen.",
        hormones: "estrogen peaks and triggers a surge of luteinizing hormone (lh), which releases an egg. testosterone gets a small bump too. it's the hormonal high point of the cycle — confidence, libido, communication and energy all tend to crest.",
        feel: "magnetic, expressive, energized. some people feel a twinge on one side, more warmth or a little bloating. a great time for big conversations and big efforts.",
        foods: [
            food("cruciferous veg",
                 "eat a serving of broccoli, cauliflower or brussels sprouts",
                 "these contain compounds like indole-3-carbinol that support your liver as it processes estrogen at its peak."),
            food("berries",
                 "have a bowl of berries",
                 "antioxidants help protect cells during the inflammatory moment of ovulation, and the fiber helps carry used estrogen out."),
            food("salmon or sardines",
                 "have salmon or sardines today",
                 "omega-3 fats are anti-inflammatory and support overall hormone health — useful around the peak."),
            food("fiber bowl",
                 "make a quinoa bowl with raw veggies",
                 "plenty of fiber helps your body bind and eliminate excess estrogen so it doesn't recirculate."),
            food("water",
                 "drink two extra glasses of water",
                 "fluid needs rise with energy and activity, and hydration supports the fertile cervical fluid your body makes now."),
        ],
        herbs: [
            herb("dandelion root",
                 "try a cup of roasted dandelion root",
                 "traditionally used to support the liver, which is busy breaking down estrogen at its highest point. roasted, it tastes a little like coffee."),
            herb("turmeric",
                 "add turmeric and black pepper to a meal",
                 "curcumin is anti-inflammatory, and black pepper helps you absorb it. it may help with ovulation twinges."),
            herb("hibiscus",
                 "pour yourself an iced hibiscus tea",
                 "tart, cooling and rich in antioxidants — a fitting match for the warmest phase of the cycle."),
            herb("rose",
                 "steep a few rose petals",
                 "rose has long been used as a heart-opening, mood-lifting herb. mostly, it's a pleasure — and pleasure counts."),
        ],
        movement: [
            move("hiit",
                 "do a 20-minute hiit session, all in",
                 "energy and power peak now. just warm up well — some research suggests ligaments may be slightly looser around ovulation."),
            move("lift",
                 "lift something heavy, with good form",
                 "estrogen and testosterone support strength and muscle-building. it's a great window to test a personal best."),
            move("group class",
                 "take a group fitness class",
                 "you're at your most social and competitive. let the room carry you."),
            move("hard run or spin",
                 "go for a hard run or a spin class",
                 "your cardiovascular capacity is high. use it."),
        ],
        practices: [
            tend("the conversation",
                 "have the conversation you've been putting off",
                 "verbal skill and confidence peak with estrogen and testosterone. it's the easiest time to say the hard thing kindly."),
            tend("ask",
                 "ask for something you want",
                 "a raise, a favor, a date. you're at your most persuasive."),
            tend("date",
                 "plan a date — with someone, or yourself",
                 "libido and the desire for connection are naturally highest around ovulation."),
            tend("share",
                 "share your work with someone",
                 "you're wired to be seen right now. let people see what you've made."),
        ],
        encouragements: [
            "you're magnetic today. act accordingly.",
            "say the thing out loud.",
            "let yourself be seen — even by people who might not get it.",
            "your voice carries today. aim it somewhere good.",
            "flirt with your own life.",
            "you are allowed to take up the whole room.",
        ]
    )

    // MARK: - Luteal · inner autumn

    static let luteal = PhaseContent(
        tagline: "come home to yourself.",
        hormones: "the empty follicle becomes the corpus luteum and releases progesterone, a calming, warming hormone that prepares your body for a possible pregnancy. estrogen rises a second time, then — if there's no pregnancy — both fall in the last few days, which is what sets off pms.",
        feel: "the first stretch tends to feel grounded, focused and nesty, which makes it good for finishing things. in the last few days, as hormones drop, you may feel more sensitive, hungrier, slower, puffy or irritable. your resting metabolism nudges up throughout, so you genuinely need a bit more food.",
        foods: [
            food("sweet potato",
                 "roast a sweet potato",
                 "your metabolism runs a little higher now. complex carbs steady blood sugar and help your body make serotonin, which can dip before your period."),
            food("chickpeas",
                 "add chickpeas to lunch",
                 "chickpeas are rich in vitamin b6, which has been studied for easing pms mood symptoms."),
            food("salmon",
                 "have salmon or another oily fish",
                 "omega-3 fats are anti-inflammatory, and studies suggest they may ease pms mood symptoms and cramping."),
            food("magnesium",
                 "eat a magnesium-rich meal — greens, beans or cacao",
                 "magnesium may ease bloating, cramps, poor sleep and pms mood swings. many of us run low."),
            food("regular meals",
                 "eat every few hours. don't skip.",
                 "blood sugar swings hit harder in this phase. steady meals mean steadier moods."),
            food("squash",
                 "roast a squash for dinner",
                 "fiber, slow carbs and carotenoids. warm, sweet, grounding food suits the start of autumn."),
            food("turkey or tempeh",
                 "build a meal around turkey or tempeh",
                 "both bring protein for steady energy and tryptophan, a building block of serotonin."),
        ],
        herbs: [
            herb("chasteberry",
                 "ask your clinician about chasteberry (vitex)",
                 "one of the best-studied herbs for pms. it appears to act on the pituitary to support progesterone. it takes a few cycles to work, and isn't for everyone — especially on hormonal birth control or when trying to conceive."),
            herb("cinnamon",
                 "dust cinnamon on your oats or tea",
                 "cinnamon may help steady blood sugar and has been studied for easing cramps. it's warming, like the season."),
            herb("tulsi",
                 "steep a cup of tulsi (holy basil)",
                 "tulsi is a gentle, traditional adaptogen used to take the edge off stress — useful as the cycle's second half wears on."),
            herb("peppermint",
                 "sip peppermint tea after a meal",
                 "progesterone slows digestion. peppermint relaxes the gut and can ease that heavy, full feeling."),
        ],
        movement: [
            move("moderate strength",
                 "do a strength session at a steady pace",
                 "progesterone raises body temperature and can make intense efforts feel harder. moderate strength work keeps you strong without overtaxing."),
            move("pilates or yoga",
                 "take a pilates or yoga class",
                 "controlled, mindful movement suits a body that's warmer and more sensitive, and it helps with bloating."),
            move("outdoor walk",
                 "walk outside for 30 minutes",
                 "daylight and steady movement support serotonin, which can start to dip in this phase."),
            move("steady cardio",
                 "go for an easy, conversational jog or ride",
                 "steady, moderate cardio burns off tension without spiking stress hormones the way all-out efforts can now."),
        ],
        practices: [
            tend("finish",
                 "finish one lingering task",
                 "early luteal brings detail-oriented focus. it's a natural time to wrap things up rather than start them."),
            tend("nest",
                 "clear one drawer or corner",
                 "the urge to tidy and nest is common now. a small win settles the mind."),
            tend("batch cook",
                 "cook a double batch and freeze half",
                 "future-you, in the last days of luteal and the first days of your period, will be very glad there's soup."),
            tend("admin hour",
                 "give an hour to the boring admin",
                 "focus and patience for detail are good now. clear the small stuff before your energy dips."),
        ],
        encouragements: [
            "finish one thing. that's enough.",
            "your sensitivity is information, not a flaw.",
            "steady is its own kind of strong.",
            "boundaries are a love language too.",
            "you're in your finishing era.",
            "a quiet night and a big bowl of something is a perfectly good plan.",
        ],
        late: LateContent(
            intro: "in the last four or five days, progesterone and estrogen both fall. this is when pms tends to show up, so persi gets gentler here: more magnesium and calcium, calming herbs, softer movement and lower expectations.",
            foods: [
                food("dark chocolate + almonds",
                     "have a few squares of dark chocolate with almonds",
                     "magnesium may ease cramps, poor sleep and pms mood swings. this is the craving worth answering."),
                food("calcium",
                     "have yogurt, kefir or calcium-rich greens",
                     "calcium is one of the better-studied nutrients for pms; trials found it eased mood, bloating and cravings."),
                food("something warm",
                     "make something warm — a stew, roasted roots or a grain bowl",
                     "digestion is slower and appetite is up. warm, cooked complex carbs are easy to digest and support serotonin."),
                food("banana + nut butter",
                     "snack on a banana with nut butter",
                     "b6 and potassium help with mood and water balance, and the pairing keeps blood sugar steady."),
                food("go easy on salt",
                     "go easy on salty snacks today",
                     "salt makes pre-period water retention and bloating worse. a little less goes a long way this week."),
            ],
            herbs: [
                herb("dandelion leaf",
                     "sip dandelion leaf tea for bloating",
                     "dandelion leaf is a gentle, traditional diuretic that may help with pre-period water retention."),
                herb("passionflower",
                     "steep passionflower before bed",
                     "a calming herb studied for anxiety and sleep — helpful as progesterone falls and sleep gets lighter."),
                herb("lemon balm",
                     "steep lemon balm when you feel edgy",
                     "lemon balm is calming without making you sleepy, and small studies suggest it eases pms irritability."),
                herb("ginger",
                     "start a daily ginger tea",
                     "in studies, ginger eased period cramps best when started a day or two before bleeding."),
            ],
            movement: [
                move("long stretch",
                     "swap intensity for a long, slow stretch",
                     "as hormones fall, honoring lower energy prevents burnout and supports the reset ahead."),
                move("gentle walk",
                     "take a slow walk, no destination",
                     "light movement lifts mood and eases bloating without asking much of you."),
                move("yin yoga",
                     "do 10 minutes of yin or restorative yoga",
                     "long, supported holds calm the nervous system right when it's most easily rattled."),
                move("swim",
                     "float or swim easy laps",
                     "water takes the weight off a puffy, tender body, and the rhythm is soothing."),
            ],
            practices: [
                tend("less caffeine",
                     "skip the second coffee or tonight's glass of wine",
                     "caffeine and alcohol can worsen anxiety, breast tenderness and poor sleep before your period."),
                tend("boundary",
                     "say no to one thing",
                     "sensitivity rises as hormones fall. boundaries protect the softer version of you."),
                tend("bath",
                     "take a warm bath with epsom salts",
                     "warmth soothes tension, and a bath is one of the easiest ways to slow down before bed."),
                tend("lower the bar",
                     "pick three must-dos. let the rest wait.",
                     "your capacity is genuinely lower right now. trimming the list is planning, not giving up."),
                tend("heads-up",
                     "tell someone close you're a little tender this week",
                     "a heads-up turns a hard week into a shared one, and saves you explaining later."),
            ],
            encouragements: [
                "the feelings are real. the conclusions can wait.",
                "you don't owe anyone your sunniest self.",
                "be the softest place you land today.",
                "nothing needs fixing tonight.",
                "lower the bar. then lower it again, kindly.",
                "your period is coming. so is relief.",
            ]
        )
    )
}
