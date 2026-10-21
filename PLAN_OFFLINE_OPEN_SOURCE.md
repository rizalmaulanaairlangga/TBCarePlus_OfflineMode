# PLAN: TBCare+ Offline Open-Source (Local-First, Tanpa Supabase/Backend)

> Dibuat: 2026-09-18 | Diperbarui: 2026-09-18 (build mode) | Lokasi root: `TBCare+/`
> Status: Plan final — siap eksekusi bertahap. Keputusan 18 Sep: Hive, risiko HIGH >75%, tanpa shared_preferences, detail Supabase dari backend/.env.
> Tujuan: `tbcare-plus-mobile` menjadi aplikasi offline 100% open-source, data analisis TBC simpan di device (hive_ce), tanpa login/registrasi/guest, tanpa backend, tanpa Supabase, tanpa internet. Maps dihapus.

---

## 1) Konteks & Keputusan Final

### 1.1 Gambar awal
`Image 1` = `tbcare-plus-mobile/lib/features/auth/pages/cover_page.dart:399-554` (state login sheet terbuka, form blur + overlay). Badge `Login & Registrasi Dinonaktifkan`, card kuning retensi 12 jam, tombol `Masuk sebagai Tamu` → `AuthApiService.createGuestSession()` → `StorageService.saveTokens()`. Ini gate terakhir sebelum `HomePage`. Pivot menghapus total gate ini → app langsung `Home`.

### 1.2 Keputusan user (final 18 Sep 2026)
1. **Storage: `hive_ce` (~400KB) full, tanpa `shared_preferences`** → `hive_ce` + `hive_ce_flutter` untuk `histories` (List<Map>) + `meta`. `shared_preferences` dihapus total (tidak ada cache kecil offline). `drift` (~2-3 MB + build_runner) ditolak — lebih berat & overkill untuk data flat.
2. **Riwayat hapus manual** → auto 12 jam (`SUPABASE_MIGRATION/guest_cleanup_12h.sql`) dicabut, ganti tombol `Hapus Riwayat` di `history_page.dart` / `profile_page.dart` (`box.clear()` + confirm dialog).
3. **Risiko Tinggi >75%** → ubah `risk_levels` high dari `73.01-100` menjadi `75.01-100` (medium jadi `58.01-75.00`) untuk ke-4 `tb_types`. Berlaku di `Data/init.sql:269-283` + regenerate `assets/config/*.json`.
4. **Mobile handle service → backend tidak perlu** → hapus `tbcare-plus-backend/` + `SUPABASE_MIGRATION/` + `.dest-db-pass.txt` setelah port scoring ke Dart sukses.
5. **Hapus maps** → hapus `url_launcher`, `core/utils/url_utils.dart`, `UrlUtils.launchNearestClinicMap` di `home_page.dart:1033` + `1016-1065`.
6. **Tanpa `shared_preferences` offline** → `pubspec.yaml:38` hapus, `StorageService` token methods dihapus total, tidak ada fallback cache kecil.

### 1.3 Supabase detail (sumber: `tbcare-plus-backend/.env:10-19` + `.dest-db-pass.txt:1`)
- Project: `pyjitfncykvdfdellszh` — `SUPABASE_URL=https://pyjitfncykvdfdellszh.supabase.co` (ap-south-1, schema `tbcare_plus`)
- Keys: `SUPABASE_KEY` (anon) + `SUPABASE_SERVICE_ROLE_KEY` (service_role) — `Dashboard → Settings → API`
- DB pooler: `aws-0-ap-south-1.pooler.supabase.com:6543` (Transaction) / `:5432` (Session) — `DATABASE_URL` di `.env:19-20`, password `le1juE0r5TLyId2G!A1bX9!`
- Token user `sbp_v0_...` = PAT Management API → pakai `GET /v1/projects` untuk resolve `service_role`, lalu `REST /rest/v1/*` atau `psql` direct. Token tidak di-commit, hanya env var sementara `SUPABASE_ACCESS_TOKEN` lalu `unset` + rotasi di Dashboard.
- **Tidak leak di git history mobile** (`git ls-files` hanya `.env.example`, `.env` di `.gitignore:52`). Leak hanya filesystem lokal (akan terhapus + rotasi).

---

## 2) Inventaris Cloud Saat Ini

| Domain | File sumber | Status offline |
|---|---|---|
| Config pengetahuan | `tbcare-plus-backend/Controllers/AssessmentController.cs:89-257` GET config → `tbcare-plus-mobile/lib/core/services/assessment_api_service.dart:37-97` fetch http + fallback `assets/config/*.json` | Fallback sudah 1:1 dengan `tbcare-plus-backend/Data/init.sql:109-291` (4 tb_types, 41 symptoms, 12 risk_levels, weights -0.6..1.0). Perlu regenerate dengan threshold baru >75% |
| Scoring | Backend `AssessmentController.cs:260-563` POST submit (variantMap `G01a`, `sumByTbType`, `k=0.35`, `quick = sumSelected/totalWeight`, `full = 1-exp(-k*sum)`, `findMatchedRiskLevel`); frontend duplikat parsial `home_page.dart:48-71` (quick) + `full_assessment_page.dart:209-277` (full) | Harus port 100% ke Dart |
| Riwayat | `AssessmentController.cs:566-731` history-sessions group by second + `core/services/storage_service.dart` token-gated | Ganti query Hive lokal (box `histories`) |
| Auth | `AuthController.cs:49-156` guest JWT 12j + `cover_page.dart:_onGuestLogin` | Hapus total |
| Routing | `routes/app_routes.dart:19` cover:'/' + `main.dart:initialRoute=cover` + `cover_page.dart:_checkAuth` | Ganti '/' → Home |
| Deps | `pubspec.yaml:37-45` http, flutter_dotenv, connectivity_plus, shared_preferences, url_launcher | Semua bisa hapus: http/flutter_dotenv/connectivity_plus/shared_preferences/url_launcher |

---

## 3) Arsitektur Target

```
BEFORE: Flutter --http+JWT--> ASP.NET Core (5181) --Npgsql:6543--> Supabase (auth + tbcare_plus)
AFTER:  Flutter (offline) -- hive_ce (device) --> assets/config/*.json (bundle) | tidak ada backend/Supabase/internet
```

- Seed knowledge base sekali saat first install dari `assets/config/quick_check_config.json` + `full_assessment_config.json` (parse via `QuickCheckConfig.fromJson` di `core/models/assessment_config_models.dart`). Load via `rootBundle.loadString` — tidak via Hive, tidak via shared_preferences.
- Histories lokal: `hive_ce` box `histories` key=autoInc int, value=json `{assessmentTypeId, primaryTbTypeId, riskLevelId, totalScore, selectedSymptoms, scoreBreakdown, createdAtIso, sessionKey}`. Group by second untuk kompat `history-sessions`.

---

## 4) Rencana Eksekusi Bertahap (Update Final)

### Fase 0 — Extract Data TBC dari Supabase (1 sesi) — BARU
- [ ] Resolve `project_ref=pyjitfncykvdfdellszh` dari `.env:10`, pakai PAT `sbp_` via env var sementara `SUPABASE_ACCESS_TOKEN` (jangan tulis ke file).
- [ ] Dump 6 tabel `tbcare_plus.*` via `psql "Host=aws-0-ap-south-1.pooler.supabase.com;Port=6543;... Password=le1ju...;SSL Mode=Require"` **atau** REST `https://pyjitfncykvdfdellszh.supabase.co/rest/v1/<table>?select=*` dengan `apikey + Bearer <service_role>`:
  - `tb_types` (4), `symptoms` (41), `assessment_types` (2, k=0.35), `assessment_questions` (8 quick + 41 full), `risk_rules` (weights `init.sql:251-257`), `risk_levels` (12)
- [ ] Simpan mentah ke `C:\Temp\opencode\tbcare_dump\*.json` (bukan ke repo), buat `tbcare_snapshot.json` gabungan untuk fixture test.
- [ ] Setelah selesai: `unset SUPABASE_ACCESS_TOKEN`, rotasi token di Dashboard.

### Fase 1 — Update Threshold & Regenerate Bundle (0.5 sesi) — BARU
- [ ] Edit `tbcare-plus-backend/Data/init.sql:271-283` ubah `high 73.01-100 → 75.01-100`, `medium 58.01-73.00 → 58.01-75.00` untuk ke-4 tb_type (pulmonary_tb, lymph_node_tb, breast_tb, spinal_tb).
- [ ] Transform dump → `assets/config/quick_check_config.json` (typeId=1) + `full_assessment_config.json` (typeId=2) via logic `variantMap` `GetBaseCode/IsVariantCode` tiru `AssessmentController.cs:178-227`. Backup file lama, diff, overwrite jika beda.
- [ ] Verifikasi `QuickCheckConfig.findRiskLevel` (`assessment_config_models.dart:51-60`) otomatis pakai band baru tanpa hardcode.

### Fase 2 — Cabut Gate Login (1 sesi)
- [ ] `lib/main.dart` ganti `initialRoute: AppRoutes.home`, ganti `await dotenv.load()` → `await HiveInit.init()` (buka box `histories` + `meta`)
- [ ] `lib/routes/app_routes.dart` hapus `cover/login/register` route, hapus `cover_page.dart`, `login_page.dart`, `register_page.dart`
- [ ] Hapus `core/services/auth_api_service.dart`, `authorized_client.dart`, `token_service.dart`, `session_service.dart`, `connectivity_service.dart`
- [ ] **Hapus total** `core/services/storage_service.dart` token methods (`saveTokens/getAccessToken/isLoggedIn` :14-106) — ganti dengan Hive, atau hapus file jika tidak dipakai lagi
- [ ] Bersihkan `core/constants/app_constants.dart` (hapus `API_BASE_URL/USE_LOCAL` :10-28, hanya simpan keys lokal jika perlu — atau kosongkan)
- [ ] `pubspec.yaml` hapus `http`, `flutter_dotenv`, `connectivity_plus`, **`shared_preferences`**, `flutter.assets` hapus `.env`
- [ ] Hapus `tbcare-plus-mobile/.env` + `.env.example` (atau ubah jadi docs lokal offline)

### Fase 3 — Local Assessment Service (inti, 1-2 sesi)
- [ ] Tambah deps: `hive_ce`, `hive_ce_flutter` (`hive_ce: ^2.8.x`), `path_provider` (transitif) — `shared_preferences` sudah dihapus
- [ ] Buat `lib/core/db/hive_init.dart`:
  - `Future<void> init() async { await Hive.initFlutter(); await Hive.openBox('histories'); await Hive.openBox('meta'); }`
- [ ] Buat `lib/core/services/local_assessment_service.dart`:
  - `Future<QuickCheckConfig> getQuickCheckConfig()` → `rootBundle.loadString('assets/config/quick_check_config.json')`
  - `Future<QuickCheckConfig> getFullAssessmentConfig()`
  - `Future<Map> submitAssessment(int typeId, List answers)` → port persis `AssessmentController.cs:298-563` (variantMap `GetBaseCode/IsVariantCode`, `weightBySymptomAndTb`, `sumByTbType`, `totalWeightByTbType`, `combinedCF`, `findMatchedRiskLevel`, `RiskRank`, buat `historyRecord` single untuk quick, per-TbType untuk full; threshold high >75)
  - `Future<List<Map>> fetchHistorySessions()` + `fetchHistoryDetail(sessionKey)` → baca box Hive + group by second (tiruan `EncodeSessionKey` base64Url `typeId|iso`)
  - `Future<void> clearHistory()` → `box.clear()`
  - `Future<Map?> fetchMostRecentAssessment()` → Hive query best riskRank→score
- [ ] Tulis unit test `test/local_assessment_service_test.dart` — 3 fixture vs `tbcare_snapshot.json` (quick, full, varian G01a). Harus identik (mitigasi "scoring tidak identik").
- [ ] Ganti `assessment_api_service.dart` jadi facade ke `local_assessment_service` atau hapus & ganti import di `home_page.dart`, `full_assessment_page.dart`

### Fase 4 — Migrasi Riwayat & UI Offline
- [ ] `lib/features/home/pages/home_page.dart:159-244,536-652` hapus `_isGuest`, `_loadUser`, `ConnectivityService` guard, `AssessmentApiService.submitAssessment` → `LocalAssessmentService.submit`; `fetchMostRecentAssessment` → Hive query
- [ ] `lib/features/assessment/pages/full_assessment_page.dart:32-41,192-362` hapus `_isLoggedIn` guard, offline snackbar `Anda sedang offline` → hapus (karena selalu offline)
- [ ] `lib/features/history/pages/history_page.dart`, `history_detail_page.dart` hapus `sessionKey` base64 & `requiresOnline`, hapus redirect guest→cover `:53`, tambah appBar action `Hapus Semua`
- [ ] `lib/features/profile/pages/*` hapus `change_password`, `edit_profile` berbasis auth, ganti jadi `Hapus Data Lokal` + `Tentang`

### Fase 5 — Hapus Maps
- [ ] `pubspec.yaml` hapus `url_launcher`
- [ ] Hapus `lib/core/utils/url_utils.dart`
- [ ] Hapus `home_page.dart:1016-1065 _buildClinicFinderButton` + pemanggilan `UrlUtils.launchNearestClinicMap` di result cards

### Fase 6 — Bersih Cloud & Open-Source
- [ ] Hapus folder `tbcare-plus-backend/` (setelah port verified), `SUPABASE_MIGRATION/`, file `.dest-db-pass.txt` di root
- [ ] Hapus `tbcare-plus-mobile/.env`, update `README.md` (cara run offline: `flutter pub get && flutter run` tanpa `dotnet run`/`DATABASE_URL`)
- [ ] Pastikan `LICENSE` (MIT — default), `CONTRIBUTING.md`, update `.gitignore` (pastikan tidak ada `.env` dengan secret)
- [ ] Rotasi di Supabase Dashboard: reset DB password & service_role (karena pernah plaintext lokal) — lakukan sebelum publish
- [ ] (Opsional) `git filter-repo` jika pernah commit secret, atau squash history bersih

### Fase 7 — Verifikasi
- [ ] `flutter pub get` + `flutter analyze` (0 error) + `flutter test` (scoring snapshot 3 fixture, threshold >75)
- [ ] Manual airplane mode: `Home quick check` → `Full assessment` → `History` → restart app → data tetap (tidak hilang 12 jam) → `Hapus Riwayat` berfungsi
- [ ] `flutter build apk --release` cek ukuran (<50 MB) + cek tidak ada `http` permission internet yang tidak perlu (optional `android:usesCleartextTraffic`)

---

## 5) Dampak File-Level (checklist hapus/edit/tambah) — Final

**Hapus:**
- `tbcare-plus-backend/**`
- `SUPABASE_MIGRATION/**`
- `.dest-db-pass.txt`
- `tbcare-plus-mobile/lib/features/auth/pages/cover_page.dart`, `login_page.dart`, `register_page.dart`
- `tbcare-plus-mobile/lib/core/services/auth_api_service.dart`, `authorized_client.dart`, `token_service.dart`, `session_service.dart`, `connectivity_service.dart`
- `tbcare-plus-mobile/lib/core/services/storage_service.dart` (atau kosongkan — diganti Hive)
- `tbcare-plus-mobile/lib/core/utils/url_utils.dart`, `network_exception.dart` (jika tidak dipakai lokal)
- `tbcare-plus-mobile/.env`

**Edit:**
- `tbcare-plus-backend/Data/init.sql:271-283` (threshold high 75.01)
- `tbcare-plus-mobile/lib/main.dart` (Hive init + initialRoute home)
- `lib/routes/app_routes.dart` (hapus cover/login/register)
- `lib/features/home/pages/home_page.dart` (hapus Maps + guest guard)
- `lib/features/assessment/pages/full_assessment_page.dart` (hapus offline guard)
- `lib/features/history/pages/*.dart` (hapus sessionKey online + tambah Hapus Semua)
- `lib/core/services/storage_service.dart` & `app_constants.dart` (hapus API URLs)
- `pubspec.yaml` (hapus http/flutter_dotenv/connectivity_plus/shared_preferences/url_launcher, tambah hive_ce) & `README.md`
- `assets/config/*.json` (regenerate threshold >75)

**Tambah:**
- `lib/core/db/hive_init.dart`
- `lib/core/services/local_assessment_service.dart`
- `test/local_assessment_service_test.dart` (3 fixture vs tbcare_snapshot.json)
- `C:\Temp\opencode\tbcare_dump\*.json` (sementara, tidak di-commit)
- `LICENSE` (cek existing `tbcare-plus-mobile/LICENSE`)

---

## 6) Risiko & Mitigasi

- **Konsistensi skor**: backend variant fan-out harus 100% duplikat — mitigasi snapshot test 3 fixture dengan threshold baru >75.
- **Ukuran APK**: Hive ~400KB vs Drift ~2MB — pilih Hive (keputusan final).
- **Secret history**: rotasi password/service_role + PAT `sbp_` sebelum publish.
- **Threshold 75**: band `medium` melebar 58.01-75, `high` menyempit 75.01-100 — hasil `score=74` yang dulu HIGH sekarang MEDIUM. Perlu komunikasi di release notes.

---

## 7) Keputusan Final (terkunci 2026-09-18)

- [x] Storage: `hive_ce` full, tanpa `shared_preferences` offline
- [x] Risiko HIGH: `>75%` (75.01-100) untuk ke-4 tb_types
- [x] Supabase source: `pyjitfncykvdfdellszh` via `tbcare-plus-backend/.env:10-19` + pooler `ap-south-1:6543`
- [x] PAT `sbp_` hanya env var sementara, tidak disimpan ke repo
- [x] Lisensi: MIT (default `tbcare-plus-mobile/LICENSE`)
- [x] Box Hive: `histories` + `meta`, retensi permanen hingga `Hapus Riwayat` manual
- [x] `supabase` folder sudah terhapus di sesi 2026-09-18 — tidak perlu aksi lagi.

---

*Plan final, siap eksekusi. Mulai Fase 0 (extract) di sesi build berikutnya.*
