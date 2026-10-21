import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../core/services/local_assessment_service.dart';
import '../../../core/models/assessment_config_models.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/tb_content_l10n.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/settings/app_settings.dart';

class FullAssessmentPage extends StatefulWidget {
  const FullAssessmentPage({super.key});
  @override
  State<FullAssessmentPage> createState() => _FullAssessmentPageState();
}

class _FullAssessmentPageState extends State<FullAssessmentPage> {
  QuickCheckConfig? _config;
  bool _loading = true;
  String? _error;
  final Map<int, bool> _answerStates = {};
  int _currentStep = 0;
  bool _submitting = false;

  static const String _kDraftAnswers = 'full_draft_answers';
  static const String _kDraftStep = 'full_draft_step';

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onLocaleChanged);
    _loadConfig();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _persistDraft() {
    try {
      final box = Hive.box('meta');
      final map = _answerStates.map((k, v) => MapEntry(k.toString(), v));
      box.put(_kDraftAnswers, map);
      box.put(_kDraftStep, _currentStep);
    } catch (_) {}
  }

  void _loadDraft() {
    try {
      final box = Hive.box('meta');
      final raw = box.get(_kDraftAnswers);
      if (raw is Map) {
        for (final e in raw.entries) {
          final qid = int.tryParse(e.key.toString());
          if (qid != null && _answerStates.containsKey(qid)) {
            _answerStates[qid] = e.value == true;
          }
        }
      }
      final step = box.get(_kDraftStep);
      if (step is int && step >= 0 && step < _totalSteps) {
        _currentStep = step;
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final box = Hive.box('meta');
      await box.delete(_kDraftAnswers);
      await box.delete(_kDraftStep);
    } catch (_) {}
  }

  Future<void> _resetForm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: Text(context.tr('fullResetConfirmTitle')),
          content: Text(context.tr('fullResetConfirmDesc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkDestructive
                    : AppColors.destructive,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr('delete')),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() {
      for (final k in _answerStates.keys.toList()) {
        _answerStates[k] = false;
      }
      _currentStep = 0;
    });
    await _clearDraft();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('fullResetSuccess')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exitToHome() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await LocalAssessmentService.getFullAssessmentConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        for (final q in config.questions) {
          _answerStates[q.questionId] = false;
        }
        _loading = false;
      });
      _loadDraft();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<int, List<QuickCheckQuestion>> get _questionsByTbType {
    if (_config == null) return {};
    final map = <int, List<QuickCheckQuestion>>{};
    for (final q in _config!.questions) {
      map.putIfAbsent(q.tbTypeId, () => []).add(q);
    }
    return map;
  }

  List<int> get _tbTypeIds => _questionsByTbType.keys.toList();
  int get _totalSteps => _tbTypeIds.length;
  bool get _isFirstStep => _currentStep == 0;
  bool get _isLastStep => _currentStep == _totalSteps - 1;
  int _currentTbTypeId() => _tbTypeIds[_currentStep];
  List<QuickCheckQuestion> _currentQuestions() =>
      _questionsByTbType[_currentTbTypeId()] ?? [];

  String _categoryName(int tbTypeId) {
    if (_config == null) return '';
    final first = _config!.questions.firstWhere(
      (q) => q.tbTypeId == tbTypeId,
      orElse: () => _config!.questions.first,
    );
    final raw =
        first.tbTypeName ??
        context.tr('fullCategoryFallback', {'id': '$tbTypeId'});
    final locale = AppSettings.instance.locale;
    return TbContentL10n.tbType(raw, locale);
  }

  IconData _iconForTbType(int tbTypeId) {
    final name = _categoryName(tbTypeId).toLowerCase();
    if (name.contains('paru') ||
        name.contains('pulmonary') ||
        name.contains('pernapasan') ||
        name.contains('respiratory') ||
        name.contains('lung') ||
        name.contains('dada') ||
        name.contains('thorax'))
      return Icons.air_outlined;
    if (name.contains('kelenjar') ||
        name.contains('lymph') ||
        name.contains('getah'))
      return Icons.medication_liquid_outlined;
    if (name.contains('tulang') ||
        name.contains('bone') ||
        name.contains('skeletal') ||
        name.contains('sendi') ||
        name.contains('joint'))
      return Icons.accessibility_new_rounded;
    if (name.contains('otak') ||
        name.contains('brain') ||
        name.contains('saraf') ||
        name.contains('nerve') ||
        name.contains('neuro'))
      return Icons.psychology_outlined;
    if (name.contains('usus') ||
        name.contains('intestine') ||
        name.contains('perut') ||
        name.contains('abdomen') ||
        name.contains('pencernaan') ||
        name.contains('gastro'))
      return Icons.restaurant_outlined;
    if (name.contains('hati') ||
        name.contains('liver') ||
        name.contains('hepar'))
      return Icons.favorite_border_outlined;
    if (name.contains('ginjal') ||
        name.contains('kidney') ||
        name.contains('renal') ||
        name.contains('urinary'))
      return Icons.water_drop_outlined;
    if (name.contains('kulit') ||
        name.contains('skin') ||
        name.contains('dermal'))
      return Icons.waves_outlined;
    if (name.contains('mata') ||
        name.contains('eye') ||
        name.contains('ocular'))
      return Icons.visibility_outlined;
    if (name.contains('jantung') ||
        name.contains('heart') ||
        name.contains('cardiac'))
      return Icons.favorite_outlined;
    return Icons.coronavirus_outlined;
  }

  int get _totalAnsweredAll => _answerStates.values.where((v) => v).length;
  int get _totalQuestionsAll => _config?.questions.length ?? 0;

  /// Returns indexes of pages where **no** question is answered Ya (all OFF / Tidak).
  /// Ini dipakai sebagai peringatan saat kirim: hanya halaman yang kosong total yang ditandai,
  /// bukan tiap soal yang belum dijawab satu per satu — karena desain toggle Ya/Tidak default Tidak.
  List<int> _getEmptyPageIndexes() {
    if (_config == null) return [];
    final empty = <int>[];
    for (int i = 0; i < _tbTypeIds.length; i++) {
      final tbId = _tbTypeIds[i];
      final qs = _questionsByTbType[tbId] ?? [];
      final answeredCount = qs
          .where((q) => _answerStates[q.questionId] == true)
          .length;
      if (answeredCount == 0) empty.add(i);
    }
    return empty;
  }

  void _goToNextStep() {
    if (_isLastStep) {
      _onSubmit();
    } else {
      setState(() => _currentStep++);
      _persistDraft();
    }
  }

  void _goToPrevStep() {
    if (!_isFirstStep) {
      setState(() => _currentStep--);
      _persistDraft();
    }
  }

  void _onAnswerToggle(int qid, bool value) {
    setState(() => _answerStates[qid] = value);
    _persistDraft();
  }

  Future<void> _onSubmit() async {
    if (_config == null) return;

    // Hanya hal. yang kosong total (tidak ada satu pun Ya) yang memicu peringatan.
    // Toggle default Tidak (OFF) tidak dihitung sebagai "belum dijawab" per soal.
    final emptyIndexes = _getEmptyPageIndexes();
    if (emptyIndexes.isNotEmpty) {
      final shouldProceed = await _showEmptyPagesDialog(emptyIndexes);
      if (shouldProceed != true) {
        // tombol kiri → redirect ke halaman kosong pertama
        setState(() => _currentStep = emptyIndexes.first);
        _persistDraft();
        return;
      }
      // tombol kanan → tetap lanjut kirim meski ada halaman kosong
      await _performSubmit();
      return;
    }

    await _performSubmit();
  }

  /// Popup merah di tengah: halaman TBC yang kosong total (tidak ada Ya) — hanya per halaman, bukan per soal
  Future<bool?> _showEmptyPagesDialog(List<int> emptyIndexes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final destructive = isDark
        ? AppColors.darkDestructive
        : AppColors.destructive;

    final emptyNames = emptyIndexes
        .map((idx) => _categoryName(_tbTypeIds[idx]))
        .toList();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxWidth: 340),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: destructive.withValues(alpha: 0.35),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: destructive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: destructive.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: destructive,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('fullEmptyDialogTitle'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: destructive,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('fullEmptyDialogDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Daftar halaman kosong — dengan border merah seperti coretan di screenshot
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: destructive.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: destructive.withValues(alpha: 0.55),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      children: emptyNames.map((name) {
                        final idx = emptyNames.indexOf(name);
                        final pageNum = emptyIndexes[idx] + 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: idx < emptyNames.length - 1 ? 8 : 0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: destructive.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: destructive.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  size: 14,
                                  color: destructive,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('fullPageLabel', {
                                        'num': '$pageNum',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: destructive,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: fg,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.circle_outlined,
                                size: 14,
                                color: destructive.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('fullEmptyDialogQuestion'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: mutedFg, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: destructive,
                          ),
                          label: Text(
                            context.tr('fullEmptyGoToForm'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: destructive,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: destructive,
                            side: BorderSide(
                              color: destructive.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                            backgroundColor: card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            context.tr('fullEmptySendAnyway'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: destructive,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // hint kecil: tombol kiri redirect ke halaman kosong pertama
                  Text(
                    context.tr('fullEmptyHintRedirect'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: mutedFg.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final Map<int, double> sumByTbType = {};
      final Map<int, String> tbTypeNames = {};
      final Map<int, List<Map<String, dynamic>>> symptomsByTbType = {};

      for (final q in _config!.questions) {
        final isSelected = _answerStates[q.questionId] ?? false;
        final cfValue = isSelected ? 1.0 : 0.0;
        for (final tw in q.applicableTbTypes) {
          tbTypeNames[tw.tbTypeId] = tw.tbTypeName;
        }
        tbTypeNames[q.tbTypeId] = q.tbTypeName ?? 'Kategori ${q.tbTypeId}';
        if (!isSelected) continue;
        final targets = q.applicableTbTypes.isNotEmpty
            ? q.applicableTbTypes
            : [
                TbTypeWeight(
                  tbTypeId: q.tbTypeId,
                  tbTypeName: q.tbTypeName ?? '',
                  weight: q.weight,
                ),
              ];
        for (final tw in targets) {
          sumByTbType[tw.tbTypeId] =
              (sumByTbType[tw.tbTypeId] ?? 0) + tw.weight;
          symptomsByTbType.putIfAbsent(tw.tbTypeId, () => []).add({
            'symptomName': q.symptomName,
            'symptomCode': q.symptomCode,
            'symptomDescription': q.symptomDescription,
            'cfValue': cfValue,
            'originTbTypeId': q.tbTypeId,
          });
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final entry in sumByTbType.entries) {
        final tbTypeId = entry.key;
        final sum = entry.value;
        final combinedCF = 1.0 - exp(-_config!.saturationK * sum);
        final percentage = (combinedCF * 100).round().toDouble();
        final matchedLevel = _config!.findRiskLevel(percentage, tbTypeId);
        results.add({
          'tbTypeId': tbTypeId,
          'tbTypeName': tbTypeNames[tbTypeId] ?? 'Kategori $tbTypeId',
          'tbTypeCode': 'TB$tbTypeId',
          'totalScore': percentage,
          'riskLevel': matchedLevel != null
              ? {
                  'title': matchedLevel.title,
                  'code': matchedLevel.code,
                  'description': matchedLevel.description ?? '',
                  'recommendation': matchedLevel.recommendation ?? '',
                }
              : {
                  'title': context.tr('homeRiskLowTitle'),
                  'code': 'LOW',
                  'description': '',
                  'recommendation': '',
                },
          'symptomDetails': symptomsByTbType[tbTypeId] ?? [],
        });
      }
      final result = {'results': results};
      final answers = _config!.questions
          .map(
            (q) => {
              'questionId': q.questionId,
              'cfValue': (_answerStates[q.questionId] ?? false) ? 1.0 : 0.0,
            },
          )
          .toList();
      await LocalAssessmentService.submitAssessment(
        assessmentTypeId: 2,
        answers: answers,
      );
      await _clearDraft();
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.result,
        arguments: {'isFullAssessment': true, 'result': result},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.isDark(context)
                ? AppColors.darkDestructive
                : AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isShort = sh < 500;
    final isLandscapePhone = isLandscape && isShort;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _buildScatteredAuras(sw, sh, isDark),
          SafeArea(
            child: Column(
              children: [
                if (isLandscapePhone)
                  ResponsiveCenter(
                    maxWidth: 720,
                    child: _buildLandscapeCompactHeader(context, isDark),
                  )
                else ...[
                  ResponsiveCenter(
                    maxWidth: 720,
                    child: _buildHeader(context, isDark),
                  ),
                  if (!_loading && _error == null)
                    ResponsiveCenter(
                      maxWidth: 720,
                      child: _buildProgressBar(isDark),
                    ),
                  if (!_loading && _error == null)
                    ResponsiveCenter(
                      maxWidth: 720,
                      child: _buildCurrentTbTypeLabel(isDark),
                    ),
                ],
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? ResponsiveCenter(
                          maxWidth: 720,
                          child: _buildErrorContent(isDark),
                        )
                      : ResponsiveCenter(
                          maxWidth: 720,
                          child: _buildStepContent(isDark),
                        ),
                ),
              ],
            ),
          ),
          if (_submitting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLandscapeCompactHeader(BuildContext context, bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final card = isDark ? AppColors.darkSurface : Colors.white;

    final tbTypeId = _loading || _error != null ? null : _currentTbTypeId();
    final categoryName = tbTypeId != null ? _categoryName(tbTypeId) : '';
    final categoryIcon = tbTypeId != null
        ? _iconForTbType(tbTypeId)
        : Icons.folder_outlined;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary row: [Back+Home] [Title + Badge] [Reset]
          Row(
            children: [
              // Back + Home combined
              Tooltip(
                message: context.tr('fullExitHomeTooltip'),
                child: GestureDetector(
                  onTap: _exitToHome,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: card.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.white,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: fg, size: 16),
                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          color:
                              (isDark ? AppColors.darkBorder : AppColors.muted)
                                  .withValues(alpha: 0.35),
                        ),
                        Icon(Icons.home_outlined, color: primary, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Center Title & Answered Count
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('fullTitle'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        context.tr('fullAnswered', {
                          'answered': '$_totalAnsweredAll',
                          'total': '$_totalQuestionsAll',
                        }),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Reset action
              Tooltip(
                message: context.tr('fullResetTooltip'),
                child: GestureDetector(
                  onTap: _resetForm,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: card.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.white,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.restart_alt_rounded, color: fg, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Secondary row: Slim progress bar & current category badge
          if (!_loading && _error == null)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(_totalSteps, (i) {
                      final isCompleted = i <= _currentStep;
                      final primaryColor = isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary;
                      final mutedColor = isDark
                          ? AppColors.darkMuted
                          : AppColors.muted;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i > 0 ? 3 : 0,
                            right: i < _totalSteps - 1 ? 3 : 0,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? primaryColor
                                  : mutedColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 12, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentStep + 1}/$_totalSteps',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 1,
                        height: 10,
                        color: primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: isDark ? AppColors.darkDestructive : AppColors.destructive,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('failedToLoad'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? context.tr('unknownError'),
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedFg, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                context.tr('tryAgain'),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryForeground
                      : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      children: List.generate(_totalSteps, (i) {
        final isCompleted = i <= _currentStep;
        final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
        final muted = isDark ? AppColors.darkMuted : AppColors.muted;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i > 0 ? 4 : 0,
              right: i < _totalSteps - 1 ? 4 : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              decoration: BoxDecoration(
                color: isCompleted ? primary : muted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    ),
  );

  Widget _buildCurrentTbTypeLabel(bool isDark) {
    final tbTypeId = _currentTbTypeId();
    final name = _categoryName(tbTypeId);
    final icon = _iconForTbType(tbTypeId);
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 6),
            Text(
              '${_currentStep + 1}/$_totalSteps',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 1,
              height: 12,
              color: primary.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    final tbTypeId = _currentTbTypeId();
    final questions = _currentQuestions();
    final title = _categoryName(tbTypeId);
    final icon = _iconForTbType(tbTypeId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildWizardSectionCard(tbTypeId, questions, icon, title, isDark),
          const SizedBox(height: 16),
          _buildWizardBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildWizardSectionCard(
    int tbTypeId,
    List<QuickCheckQuestion> questions,
    IconData icon,
    String title,
    bool isDark,
  ) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final locale = AppSettings.instance.locale;
    return Container(
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: ResponsiveGrid(
          spacing: 8,
          runSpacing: 6,
          children: questions.map((q) {
            final isSelected = _answerStates[q.questionId] ?? false;
            final sIcon = getSymptomIcon(q.symptomCode);
            final label = q.localizedQuestionText(locale);
            return _buildToggleItem(
              q.questionId,
              sIcon,
              label,
              isSelected,
              isDark,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back + Home combined — back arrow with home indicator
          Tooltip(
            message: context.tr('fullExitHomeTooltip'),
            child: GestureDetector(
              onTap: _exitToHome,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: card.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: fg, size: 18),
                    Container(
                      width: 1,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: (isDark ? AppColors.darkBorder : AppColors.muted)
                          .withValues(alpha: 0.35),
                    ),
                    Icon(Icons.home_outlined, color: primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  context.tr('fullTitle'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    context.tr('fullAnswered', {
                      'answered': '$_totalAnsweredAll',
                      'total': '$_totalQuestionsAll',
                    }),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Reset button top-right
          Tooltip(
            message: context.tr('fullResetTooltip'),
            child: GestureDetector(
              onTap: _resetForm,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: card.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.restart_alt_rounded, color: fg, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardBottomBar(bool isDark) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isFirstStep ? null : _goToPrevStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(
                  context.tr('back'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  backgroundColor: card,
                  side: BorderSide(
                    color: _isFirstStep
                        ? muted.withValues(alpha: 0.35)
                        : primary.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _goToNextStep,
                icon: Icon(
                  _isLastStep
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkPrimaryForeground
                      : Colors.white,
                ),
                label: Text(
                  _isLastStep ? context.tr('send') : context.tr('next'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkPrimaryForeground
                        : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark
                      ? AppColors.darkPrimaryForeground
                      : Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    int questionId,
    IconData icon,
    String label,
    bool isSelected,
    bool isDark,
  ) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    return GestureDetector(
      onTap: () => _onAnswerToggle(questionId, !isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.2)
                    : muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: isSelected ? primary : mutedFg,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : fg,
                  height: 1.35,
                ),
              ),
            ),
            Switch(
              value: isSelected,
              onChanged: (val) => _onAnswerToggle(questionId, val),
              activeThumbColor: primary,
              activeTrackColor: primary.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScatteredAuras(double sw, double sh, bool isDark) => Stack(
    children: [
      Positioned(
        top: -sw * 0.05,
        right: -sw * 0.1,
        child: _buildAura(
          150,
          (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(
            alpha: 0.08,
          ),
        ),
      ),
      Positioned(
        top: sh * 0.3,
        left: -sw * 0.2,
        child: _buildAura(
          130,
          (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(
            alpha: 0.04,
          ),
        ),
      ),
      Positioned(
        bottom: sh * 0.2,
        right: sw * 0.1,
        child: _buildAura(
          110,
          (isDark ? AppColors.darkMuted : AppColors.muted).withValues(
            alpha: isDark ? 0.08 : 0.15,
          ),
        ),
      ),
    ],
  );

  Widget _buildAura(double size, Color color) => Container(
    width: size * 2,
    height: size * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2),
      ],
    ),
  );
}

IconData getSymptomIcon(String code) {
  final c = code.toUpperCase();
  if (c.startsWith('G01')) return Icons.air_outlined;
  if (c.startsWith('G02')) return Icons.water_drop_outlined;
  if (c.startsWith('G03')) return Icons.thermostat_outlined;
  if (c.startsWith('G04')) return Icons.waves_outlined;
  if (c.startsWith('G05')) return Icons.no_food_outlined;
  if (c.startsWith('G06')) return Icons.monitor_weight_outlined;
  if (c.startsWith('G07')) return Icons.battery_alert_outlined;
  if (c.startsWith('G08')) return Icons.nightlight_outlined;
  if (c.startsWith('G09')) return Icons.commit_rounded;
  if (c.startsWith('G10')) return Icons.local_fire_department_outlined;
  if (c.startsWith('G11')) return Icons.open_with_rounded;
  if (c.startsWith('G12')) return Icons.fingerprint_rounded;
  if (c.startsWith('G13')) return Icons.zoom_in_rounded;
  if (c.startsWith('G14')) return Icons.opacity_rounded;
  if (c.startsWith('G15')) return Icons.healing_rounded;
  if (c.startsWith('G16')) return Icons.adjust_rounded;
  if (c.startsWith('G17')) return Icons.sensors_off_rounded;
  if (c.startsWith('G18')) return Icons.local_fire_department_outlined;
  if (c.startsWith('G19')) return Icons.accessibility_new_rounded;
  if (c.startsWith('G20')) return Icons.directions_walk_rounded;
  if (c.startsWith('G21')) return Icons.do_not_disturb_on_rounded;
  if (c.startsWith('G22')) return Icons.bedtime_outlined;
  if (c.startsWith('G23')) return Icons.blur_on_rounded;
  return Icons.help_outline;
}
