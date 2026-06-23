# receipts

> **the receipts don't lie.**

A privacy-first Android app that turns a WhatsApp chat export into a brutally honest breakdown of your relationship dynamics. No accounts. No servers. All on your device.

---

## What it does

Import any WhatsApp conversation — one-on-one or a group chat — and Receipts computes 25 metrics across four categories: volume, timing, tone, and big-picture composites. It tells you who texts first, who ghosts questions, who replies faster, whose effort is dropping off, and a lot more.

Every number is backed by actual messages you can tap into to verify. Hence — receipts.

---

## Metrics

### Volume
| Metric | What it measures |
|---|---|
| Message Share | Who sends more messages |
| Word Share | Who writes more overall |
| Avg Message Length | Words per message |
| Emoji Rate | % of messages that contain at least one emoji |
| Emoji Diversity | Shannon entropy of each person's emoji palette — who uses a wider variety |
| Media Share | Who sends more photos, videos, voice notes, etc. |
| Deleted / Edited Rate | % of messages that were deleted or edited after sending |

### Timing
| Metric | What it measures |
|---|---|
| Reply Speed | Median reply latency per person |
| Texts First | Who initiates more conversations |
| Double-Text Rate | How often each person sends follow-ups without a reply |
| Last Word | Who tends to have the final message in a conversation |
| Ghost Rate | % of each person's questions that go unanswered |
| Breaks Silence | Who reaches out after a 2+ day gap |
| Back-and-Forth | Speaker-switch density — how much it feels like a real dialogue |
| Momentum | Whether overall chat activity is trending up, flat, or cooling off |
| Hours Overlap | How much each person's active hours of the day overlap |

### Tone
| Metric | What it measures |
|---|---|
| Question Rate | % of messages that ask a question |
| Laughter | % of messages with laughter markers (lol, haha, kkk, etc.) |
| Affection | % of messages with affectionate words or emoji |

### Big Picture
| Metric | What it measures |
|---|---|
| Investment Index | Weighted average of message, word, initiation, and question share |
| Balance Score | How symmetric the investment is — 100 = perfectly equal |
| Pursuit Gap | Composite keenness signal: who is putting in more effort overall |
| Reciprocity | How mutual the conversation is — high initiation balance + fast back-and-forth |
| Dry Texter Score | Composite dryness: short messages, few questions, slow replies, ghosting |
| Relationship Health | Top-line score blending balance, reciprocity, and momentum |

Every metric either shows a per-person breakdown (A vs B bars) or a single scalar for the chat as a whole. Metrics that don't have enough data to be reliable are gated — they show up as "not enough data" instead of misleading numbers.

---

## Privacy

**Everything stays on your device.** There is no backend, no account, no analytics, no telemetry, and no network requests of any kind.

- **Parsing** happens locally in a Dart isolate
- **Storage** uses Hive, a local key-value database embedded in the app
- **No data leaves the app** at any point — not during import, analysis, or "copy to clipboard"
- The "ON-DEVICE" badge shown throughout the UI is not marketing copy; it is a technical fact

The only thing that leaves your phone is what you explicitly copy or share yourself.

### What is stored
Receipts persists the following to local Hive boxes:
- Parsed messages (text, timestamp, sender, metadata)
- Computed metric results
- Session boundaries
- Run metadata (date range, participant names, message count)

You can delete any individual chat import or wipe everything from the home screen. Deleting a run removes all associated messages, sessions, and metrics permanently.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 (Dart 3.12+) |
| State management | Flutter Riverpod 2 |
| Local storage | Hive + Hive Flutter |
| Charts | fl_chart |
| Typography | Google Fonts — Archivo Black, Space Grotesk |
| Emoji counting | `characters` (grapheme-aware — handles multi-codepoint emoji correctly) |
| Deduplication | `crypto` (SHA-256 of message content) |
| Share intake | `flutter_sharing_intent` (OS share sheet) + `file_selector` (manual picker) |
| ZIP parsing | `archive` |
| Date formatting | `intl` |

No third-party analytics, crash reporting, or cloud SDKs are included.

---

## Design philosophy

Receipts uses a **neobrutalist** visual language: warm cream backgrounds, thick ink borders, hard 5 px drop shadows with no blur, and strong accent colors rotating through blue, pink, yellow, and lime.

The goal is for the UI to feel like a physical document — something you'd print out and hand across a table. The aesthetic matches the app's purpose: these are receipts, not dashboards.

Typography does a lot of the work. Archivo Black is used for display numbers. Space Grotesk handles everything else. No rounded softening — when the data is uncomfortable, the design doesn't apologise for it.

On the engineering side, the domain layer (parsing, metrics, sessionization) is pure Dart with zero Flutter imports. Metrics run inside a Dart `Isolate` so large chats (100 K+ messages) don't freeze the UI. Evidence message IDs are stored alongside every metric so the drill-down screen can show exactly which messages contributed to the number.

---

## Use cases

- Wondering if you always text first? There's a metric for that.
- Want to know whose questions get ignored more? Ghost rate.
- Trying to figure out why things feel one-sided? Investment index + Pursuit gap.
- Want to see if you and someone text at the same time of day? Hours overlap.
- Just curious how a friendship has trended over two years? Momentum chart.
- Ready to send someone the data? Copy stats to clipboard and paste it wherever.

Works with romantic relationships, friendships, family chats, and work DMs. Works with small chats (a few hundred messages) and very large ones.

---

## How to install

### Option 1 — Download the APK (easiest)

1. Go to the [**Releases**](../../releases) page
2. Download the latest `receipts-x.x.x.apk`
3. On your Android phone, open the APK file
4. If prompted, allow installation from unknown sources under **Settings → Security → Install unknown apps**
5. Install and open

Requires Android 5.0 (API 21) or higher.

### Option 2 — Build from source

#### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.x)
- Android SDK with a connected device or emulator
- Java 17

#### Steps

```bash
# Clone the repo
git clone https://github.com/suramya-didwania/chat-stat.git
cd chat-stat/mobile

# Install dependencies
flutter pub get

# Run on a connected device
flutter run

# Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## How to export your WhatsApp chat

**Android**
1. Open the chat in WhatsApp
2. Tap ⋮ → More → Export chat
3. Choose **Without media**
4. Share the `.txt` file directly to Receipts, or save it and use the in-app file picker

**iPhone**
1. Open the chat
2. Tap the contact/group name at the top → Export Chat
3. Choose **Without Media**
4. AirDrop or share the `.zip` to your Android device (or use a cloud drive)

Receipts accepts both `.txt` and `.zip` formats, and handles both Android (dash-format timestamps) and iOS (bracket-format timestamps) exports automatically.

---

## Building automatically

A GitHub Actions workflow at [`.github/workflows/release.yml`](.github/workflows/release.yml) builds and publishes the release APK to the [Releases](../../releases) page on every push to `main`. No manual steps needed to ship a new build.

---

## Project structure

```
mobile/
├── lib/
│   ├── app/theme/tokens.dart        # Design system: colors, typography, components
│   ├── ingest/ingest_service.dart   # Share intent + file intake
│   ├── parser/
│   │   ├── chat_parser.dart         # Regex parser — Android + iOS export formats
│   │   └── normalizer.dart          # Unicode cleanup
│   ├── domain/
│   │   ├── models/                  # RunMessage, AnalysisRun, ChatSession, MetricResult
│   │   ├── sessionizer.dart         # Groups messages into conversations
│   │   ├── metrics/                 # 25 metric implementations + runner + helpers
│   │   └── insight/                 # Top-5 narrative insight generator
│   ├── data/repository.dart         # Hive persistence layer
│   └── features/
│       ├── splash/                  # Animated intro screen
│       ├── import_flow/             # File picker → parse progress → group pick
│       ├── home_timeline/           # List of imported chats
│       ├── analysis_detail/         # Main stats screen with all metric cards
│       └── metric_detail/           # Drill-down with evidence messages
└── android/
    └── app/
        ├── build.gradle.kts
        └── src/main/AndroidManifest.xml
```

---

## License

MIT
