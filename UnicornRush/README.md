# 🦄 Unicorn Rush: Garage to IPO

A startup tycoon for iOS, built with SwiftUI. You name your company, open a coffee bar in a
garage, and grow it into a trillion-dollar empire. Along the way you pitch investors, level up
as a founder, and post your **Founder Card** to show friends how big your startup has become.

It uses the same core loops that make *My Hotel*, *My Pizza Ready* and *We Are Warriors* hard to
put down, with a theme people can relate to: "I'm building something, and I'm getting better at it."

---

## Why it's addictive (the design)

| Hook | How Unicorn Rush does it |
|---|---|
| **Constant small wins** | Ten departments (☕️ Coffee Bar → 🦄 Moonshot Factory) pay out every few seconds. Every payout gets haptics, a "+$" pop and a number that ticks up. |
| **Clear "next level"** | **Funding rounds are the levels**: Pre-Seed → Seed → Series A (🦄 $1B) → B → C → **IPO** → Decacorn → … → Galactic Empire. A progress bar always shows how close the next round is. |
| **A boss fight per level** | To close a round you have to **pitch**: a timing mini-game where you stop the needle in the sweet spot 3 times. Each round makes it harder. Closing a round permanently doubles revenue. |
| **"I'm upskilling"** | **Founder Level & XP** come from every tap, purchase, hire and round. Each level gives a skill point for Hustle, Leadership, Charisma, Negotiation or Vision. Titles climb from *Wantrepreneur* to *Builder*, *Visionary*, *Titan* and *GOAT*. |
| **Speed milestones** | At 25/50/100/200/300/400 units a department runs **2x faster**. There's always a number you're close to. |
| **Automation fantasy** | Hiring a manager (*10x Dev Dex*, *Closer Cleo*…) runs that department forever, even while you're offline. |
| **Variable rewards** | A **golden unicorn** 🦄 floats across the screen every 1–2.5 min. Tap it for a random reward: a cash windfall or **VIRAL: 7x revenue for 30s**. |
| **Prestige** | After the IPO you can **Exit** and start a new company with Reputation ⭐️ (+2% revenue each, forever). Each run goes faster, which creates the "one more run" pull. |
| **Come-back loops** | Offline earnings ("While you were away…"), a **daily streak 🔥** whose bonus grows each day, and local notifications that are only requested after the first round closes (higher opt-in). |
| **Identity & pride** | You name the company and pick its logo. The tier ladder goes Bronze → Silver → Gold → Diamond → Legend Founder. |
| **Shareable pride** | A 9:16 **Founder Card** sized for Instagram/TikTok stories shows company, valuation, round, tier, level, streak and stars, plus "Can you beat me? #UnicornRush". Right after each round closes the game prompts you to "Brag about it". |
| **Social proof** | A Game Center leaderboard for best valuation (optional, see below). |

### Pacing (simulated)

The economy was tuned with a greedy-player simulation (unmanaged stations at 35% uptime, no
skills, boosts or offline income, so real players move a bit faster):

| Milestone | Time |
|---|---|
| Pre-Seed 🌱 | ~2 min |
| Seed 🌿 | ~4 min |
| Series A 🦄 ($1B) | ~9 min |
| Series B | ~17 min |
| Series C | ~38 min |
| **IPO → first Exit** | ~2 h active play (spread over 1–2 days with offline earnings) |

The first session therefore has 3–4 level-ups and a unicorn moment, which gives new players an
early reason to share. All the numbers are in `UnicornRush/Model/GameData.swift`.

---

## Play it now on your iPhone (web version)

`web/index.html` is **Unicorn Rush: SF**, a walk-around life sim. You land in San Francisco with
$80 and rent due every month, then do the founder things yourself:

- 🏠 **Hacker House:** stand at your desk and Claude Code ships features (🧩) onto your stack.
- 🌳 **Dolores Park:** drop features to post them. Followers grow, and some posts go viral.
- 👀 **The streets:** followers bring leads who walk around the city. Run into them to close them as paying customers (MRR).
- 🎤 **SoMa events:** a Founder Mixer, AI Hackathon, VC Brunch or Demo Day goes live on a timer. Grab contacts and catch 💰 VCs for investor intros. Hackathons pay prizes for features.
- 🏦 **Sand Hill Road:** once you have enough customers, intros and followers, walk in and pitch (a timing mini-game). The rounds are the levels: Pre-Seed → Seed → Series A → B → C (🦄) → IPO.
- **Upgrades** are bought by standing on floor spots: Claude Max, 2nd monitor, backpack, oat lattes, an e-scooter, a SoMa office, and engineers, marketers and sales reps (their salaries burn runway). The billboard on the 101 unlocks at Seed.

Open it in Safari on your iPhone and tap **Share → Add to Home Screen**. Progress is saved in that browser.

## Running the native app

You need a Mac with **Xcode 16+**. The project is generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen), so no `.xcodeproj` merge conflicts.

```bash
brew install xcodegen
cd UnicornRush
xcodegen generate
open UnicornRush.xcodeproj
```

Then choose your Team under *Signing & Capabilities* and run on a simulator or an iPhone (iOS 17+).

> ⚠️ This code was written in a Linux environment that had no Swift compiler. Every file passes a
> Swift syntax parse and the code was reviewed for type errors, but the first Xcode build may still
> report a few small fixes. They should be quick.

### Optional: Game Center leaderboard
1. In App Store Connect, enable Game Center for the app and create a leaderboard with ID
   `unicornrush.valuation` (type: high score).
2. In Xcode, add the **Game Center** capability.

Until you do this, every Game Center call is a silent no-op.

---

## Code map

```
UnicornRush/
├── project.yml                 XcodeGen spec (iOS 17, iPhone, portrait)
└── UnicornRush/
    ├── App/UnicornRushApp.swift     entry point, scene-phase → offline earnings / notifications
    ├── Model/
    │   ├── GameData.swift           ALL balancing: departments, rounds, skills, titles, trophies
    │   ├── GameState.swift          Codable save (tolerant of missing keys) + number formatting
    │   └── GameEngine.swift         20 Hz simulation, buying, pitch, XP, prestige, streaks, unicorn
    ├── Services/                    Haptics, local notifications, Game Center
    └── Views/
        ├── OfficeView.swift         main screen: HUD, funding banner, department rows, unicorn
        ├── PitchView.swift          the funding-round timing mini-game
        ├── FounderView.swift        level, title ladder, skill tree
        ├── TrophiesView.swift       achievements, career stats, the Exit
        ├── ShareCardView.swift      Founder Card + image render + share sheet
        ├── RootView.swift           tabs, onboarding, reward sheets, celebrations, toasts
        └── Theme.swift              colours, card style, confetti
```

---

## Roadmap to launch & virality

1. **Juice pass**: sound effects (cash register, pitch hit/miss, round-closed fanfare) and
   SpriteKit particles on payouts.
2. **Rewarded ads** (AdMob/AppLovin): "2x offline earnings", "extra pitch strike", "skip cooldown".
   These are the main revenue source for games in this genre.
3. **IAP**: "Seed Investor Pack" (permanent 2x revenue) and a starter pack after the first round closes.
4. **Weekly "Demo Day" event**: everyone starts a fresh company, and the leaderboard resets each
   week. Gives the game a reason to be talked about every week.
5. **Rival founders**: friends' companies (via Game Center) on your leaderboard, plus a push
   notification when someone passes your valuation.
6. **More shareable moments**: a short screen recording of the IPO bell (ReplayKit) and a
   year-in-review card ("Wrapped" style).
7. **Office visuals**: an isometric office that grows (garage → loft → tower → space station),
   the *My Hotel*-style visible progression.
8. **Analytics**: track the funnel (D1/D7 retention, time to each round, share-tap rate) and tune
   `GameData.swift` against it.
