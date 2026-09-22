# TBCare+ (Offline Open-Source)

TBCare+ is an offline-first tuberculosis early-detection expert system built with **Flutter**. All screening, scoring, and history are stored locally on-device with `hive_ce` — no backend, no Supabase, no internet required.

## Features

- **Quick Check & Full Assessment** — Two-tier TB screening with wizard-guided forms (8 + 41 questions)
- **Expert System Scoring** — Local certainty-factor calculation: `quick = sumSelected/totalWeight`, `full = 1 - exp(-0.35 * sum)`, threshold HIGH `>75%` (medium `58.01-75`, low `0-58`), variant fan-out `G01a` → all TB types
- **Assessment History** — Hive box `histories` grouped by second, sessionKey `base64Url(typeId|iso)`, with `Hapus Riwayat` (clear) support
- **100% Offline** — Knowledge base bundled in `assets/config/*.json`, no login/guest, no `shared_preferences`, no maps
- **Open-Source** — MIT, no secrets, `flutter pub get && flutter run` is enough

## Tech Stack

- **Framework**: Flutter (Dart 3.12+)
- **Local Storage**: `hive_ce` + `hive_ce_flutter` + `path_provider` (box `histories` + `meta`)
- **Bundle**: `assets/config/quick_check_config.json` + `full_assessment_config.json` (captured from `tbcare_plus` DB, 4 tb_types, 41 symptoms, 12 risk_levels)
- **Files & Images**: `file_picker`, `image`
- **Misc**: `intl` (date formatting), `package_info_plus`

## Getting Started

### Prerequisites

- Flutter SDK 3.22+

### Setup & Run (no backend, no .env)

```bash
git clone https://github.com/rizalmaulanaairlangga/tbcare-plus-mobile.git
cd tbcare-plus-mobile
flutter pub get
flutter run
```

No `.env` needed. No `dotnet run`. Works in airplane mode.

## Scoring

- Config loaded via `rootBundle` → `QuickCheckConfig.fromJson` (`lib/core/models/assessment_config_models.dart`)
- Submit via `LocalAssessmentService.submitAssessment` (`lib/core/services/local_assessment_service.dart`) — port of `AssessmentController.cs:298-563`
- History via Hive — `fetchHistorySessions` / `fetchHistorySessionDetail` / `clearHistory`

## Build Release

```bash
flutter build apk --split-per-abi
```

APKs output to `build/app/outputs/flutter-apk/` (<50 MB, no internet permission required).

## Project Structure

```
lib/
├── core/
│   ├── constants/    # Hive box names
│   ├── db/           # HiveInit (init + boxes)
│   ├── models/       # assessment_config_models, auth_models (legacy)
│   ├── services/     # local_assessment_service (offline scoring + history)
│   ├── theme/        # Colors, text styles, theme
│   └── widgets/      # Shared widgets (HomeHeader, AppTopBar, AppBottomNav)
├── features/
│   ├── home/         # Home dashboard (offline)
│   ├── assessment/   # Full assessment wizard (offline)
│   ├── result/       # Assessment results with scoring
│   ├── history/      # History list, detail + Hapus Semua
│   ├── profile/      # Tentang + Hapus Data Lokal
│   └── about/        # About & help page
└── routes/           # Named routes (home '/' → HomePage)
```

## Data Source

Offline bundle generated from Supabase `tbcare_plus` schema (`tbcare-plus-backend/Data/init.sql`): `tb_types`, `symptoms`, `risk_rules`, `risk_levels` (HIGH >75%). Regenerate `assets/config/*.json` when DB changes.
