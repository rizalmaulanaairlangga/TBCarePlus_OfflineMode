# TBCare+ (Offline Open-Source)

> **📲 Download APK siap instal — tidak perlu build!** Langsung unduh di [**Releases v1.3.3**](https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode/releases/tag/v1.3.3)

[![Release](https://img.shields.io/github/v/release/rizalmaulanaairlangga/TBCarePlus_OfflineMode?label=download&color=10B981)](https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode/releases/tag/v1.3.3)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-blue)](https://flutter.dev)
[![Offline](https://img.shields.io/badge/offline-100%25-success)](https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

TBCare+ is an offline-first tuberculosis early-detection expert system built with **Flutter**. All screening, scoring, and history are stored locally on-device with `hive_ce` — no backend, no Supabase, no internet required.

## 📲 Download & Instal (Android)

**Tidak perlu clone/build — download langsung jadi:**

| File | Ukuran | Cocok untuk | Link |
|------|--------|-------------|------|
| **Universal (Recommended)** | 46.9 MB | Semua device | [**TBCare-v1.3.3-release-universal.apk**](https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode/releases/download/v1.3.3/TBCare-v1.3.3-release-universal.apk) |
| **arm64-v8a** | 16.7 MB | HP baru 64-bit | [**TBCare-v1.3.3-arm64.apk**](https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode/releases/download/v1.3.3/TBCare-v1.3.3-arm64.apk) |
| **armeabi-v7a** | 14.3 MB | HP lama 32-bit | [**TBCare-v1.3.3-armeabi-v7a.apk**](https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode/releases/download/v1.3.3/TBCare-v1.3.3-armeabi-v7a.apk) |

> **Cara instal:** Download → Buka file APK → Izinkan *Instal dari sumber tidak dikenal* jika diminta → Instal → Buka TBCare+.
> 
> **Tips:** Jika ragu, pilih **Universal**.

<details>
<summary>📸 Cara download dari HP</summary>

1. Buka link Release di atas lewat HP
2. Tap file `.apk` → Download akan mulai
3. Notifikasi download selesai → Tap untuk instal

</details>

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
git clone https://github.com/rizalmaulanaairlangga/TBCarePlus_OfflineMode.git
cd TBCarePlus_OfflineMode
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
