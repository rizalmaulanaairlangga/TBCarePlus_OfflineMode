import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/services/local_assessment_service.dart';
import '../../../core/models/assessment_config_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/home_header.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/url_utils.dart';

enum RiskLevel { low, medium, high }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  QuickCheckConfig? _config;
  Map<int, bool> _symptomStates = {};
  bool _loadingConfig = true;
  Map<String, dynamic>? _mostRecentAssessment;
  bool _loadingMostRecent = true;
  Map<String, dynamic>? _storedResult;
  bool get _hasStoredResult => _storedResult != null;
  bool _submittingQuick = false;

  int get _answeredCount => _symptomStates.values.where((v) => v).length;

  double get _combinedCF {
    if (_config == null || _answeredCount == 0) return 0;
    double selectedWeight = 0;
    double totalWeight = 0;
    for (final q in _config!.questions) {
      totalWeight += q.weight;
      if (_symptomStates[q.symptomId] == true) selectedWeight += q.weight;
    }
    if (totalWeight <= 0) return 0;
    return selectedWeight / totalWeight;
  }

  int get _percentage => (_combinedCF * 100).round();

  RiskLevelConfig? get _matchedRiskLevel {
    if (_config == null) return null;
    return _config!.findRiskLevel(_percentage.toDouble(), 1);
  }

  RiskLevel get _risk {
    final rl = _matchedRiskLevel;
    if (rl == null) return RiskLevel.low;
    switch (rl.code.toUpperCase()) {
      case 'HIGH':
        return RiskLevel.high;
      case 'MEDIUM':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadMostRecent();
    // Rebuild when language changes so TBC questions update
    // ignore: invalid_use_of_protected_member
    // AppSettings is ChangeNotifier; listen via instance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppSettings.instance.addListener(_onLocaleChanged);
    });
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      AppSettings.instance.removeListener(_onLocaleChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await LocalAssessmentService.getQuickCheckConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _symptomStates = {for (final q in config.questions) q.symptomId: false};
        _loadingConfig = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingConfig = false);
    }
  }

  Future<void> _loadMostRecent() async {
    try {
      final recent = await LocalAssessmentService.fetchMostRecentAssessment();
      if (!mounted) return;
      setState(() {
        _mostRecentAssessment = recent;
        _loadingMostRecent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMostRecent = false);
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loadingConfig = true;
      _loadingMostRecent = true;
    });
    await Future.wait([_loadConfig(), _loadMostRecent()]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _buildScatteredAuras(screenWidth, screenHeight, isDark),
          SafeArea(
            child: Column(
              children: [
                const ResponsiveCenter(
                  maxWidth: 720,
                  child: HomeHeader(isGuest: false),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ResponsiveCenter(
                        maxWidth: 720,
                        child: Column(
                          children: [
                            if (_loadingConfig || _loadingMostRecent)
                              _buildLoadingCard(isDark)
                            else if (_mostRecentAssessment != null)
                              _buildRecentResultCard(isDark)
                            else if (_hasStoredResult)
                              _buildStoredResultCard(isDark)
                            else
                              _buildAssessmentCard(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          final routes = [AppRoutes.home, AppRoutes.history, AppRoutes.profile];
          if (i < routes.length) {
            Navigator.pushNamedAndRemoveUntil(context, routes[i], (route) => false);
          }
        },
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240,
        decoration: BoxDecoration(color: card.withValues(alpha: isDark ? 1.0 : 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: (isDark ? AppColors.darkBorder : Colors.white).withValues(alpha: 0.5))),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildAssessmentCard(bool isDark) {
    final config = _config!;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: card.withValues(alpha: isDark ? 1.0 : 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: (isDark ? AppColors.darkBorder : Colors.white).withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('homeQuickTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
                    Text(context.tr('homeSymptomCount', {'count': '${config.questions.length}'}), style: TextStyle(fontSize: 12, color: mutedFg, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...config.questions.map((q) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildSymptomItem(q, isDark))),
            const SizedBox(height: 18),
            _buildCheckButton(isDark),
            const SizedBox(height: 10),
            _buildAcrylicOutlineButton(label: context.tr('homeContinueFull'), icon: Icons.assignment_outlined, onPressed: () => Navigator.pushNamed(context, AppRoutes.fullAssessment), isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAcrylicOutlineButton({required String label, required IconData icon, required VoidCallback onPressed, required bool isDark}) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: card.withValues(alpha: 0.88),
        border: Border.all(color: primary.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: primary),
        label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primary)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  final Map<int, IconData> _symptomIcons = {
    1: Icons.air_outlined,
    2: Icons.water_drop_outlined,
    3: Icons.thermostat_outlined,
    4: Icons.waves_outlined,
    5: Icons.no_meals_outlined,
    6: Icons.monitor_weight_outlined,
    7: Icons.battery_alert_outlined,
    8: Icons.nightlight_outlined,
  };

  Widget _buildSymptomItem(QuickCheckQuestion q, bool isDark) {
    final isSelected = _symptomStates[q.symptomId] ?? false;
    final icon = _symptomIcons[q.symptomId] ?? Icons.help_outline;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return GestureDetector(
      onTap: () => setState(() => _symptomStates[q.symptomId] = !isSelected),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.12) : card.withValues(alpha: isDark ? 1.0 : 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? primary.withValues(alpha: 0.3) : (isDark ? AppColors.darkBorder : Colors.white), width: 1.2),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isSelected ? primary.withValues(alpha: 0.1) : (isDark ? AppColors.darkMuted : Colors.white).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: isSelected ? primary : mutedFg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(q.localizedQuestionText(AppSettings.instance.locale), style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? fg : mutedFg))),
            Switch(
              value: isSelected,
              onChanged: (val) => setState(() => _symptomStates[q.symptomId] = val),
              activeThumbColor: primary,
              activeTrackColor: primary.withValues(alpha: 0.2),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: (isDark ? AppColors.darkMuted : Colors.grey).withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckButton(bool isDark) {
    final hasSelection = _answeredCount > 0;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondary = isDark ? AppColors.darkSecondary : AppColors.secondary;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: hasSelection ? [primary, secondary] : [muted, muted.withValues(alpha: 0.6)]),
        border: Border.all(color: hasSelection ? Colors.white.withValues(alpha: 0.9) : muted.withValues(alpha: 0.35), width: 1.2),
        boxShadow: hasSelection ? [BoxShadow(color: primary.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 8)), BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ElevatedButton(
        onPressed: (hasSelection && !_submittingQuick) ? _onCheckRisk : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(context.tr('homeCheckRisk'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Future<void> _onCheckRisk() async {
    if (_answeredCount == 0 || _config == null) return;
    if (_submittingQuick) return;
    setState(() => _submittingQuick = true);
    try {
      if (_config == null || _config!.questions.isEmpty) {
        _showSnack(context.tr('homeLoadFailed'));
        return;
      }
      final cf = _combinedCF;
      final pct = _percentage;
      final risk = _risk;
      final matchedLevel = _matchedRiskLevel;
      final selectedSymptoms = <String, bool>{};
      _symptomStates.forEach((k, v) => selectedSymptoms[k.toString()] = v);
      final assessmentData = {'riskLevel': risk.name, 'combinedCF': cf, 'percentage': pct, 'riskCode': matchedLevel?.code ?? 'LOW', 'riskTitle': matchedLevel?.title ?? '', 'description': matchedLevel?.description ?? '', 'type': 'QUICK CHECK', 'symptoms': selectedSymptoms};
      final answers = <Map<String, dynamic>>[];
      for (final q in _config!.questions) {
        final selected = _symptomStates[q.symptomId] ?? false;
        if (!selected) continue;
        answers.add({'questionId': q.questionId, 'cfValue': 1.0});
      }
      if (answers.isEmpty) return;
      await LocalAssessmentService.submitAssessment(assessmentTypeId: 1, answers: answers);
      await _loadMostRecent();
      _storedResult = assessmentData;
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.result, arguments: {'riskLevel': risk.name, 'percentage': pct, 'assessmentData': assessmentData});
    } finally {
      if (mounted) setState(() => _submittingQuick = false);
    }
  }

  void _showSnack(String message, {Color? background}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message), backgroundColor: background ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkDestructive : AppColors.destructive), behavior: SnackBarBehavior.floating));
  }

  Widget _buildStoredResultCard(bool isDark) {
    final result = _storedResult!;
    final pct = (result['percentage'] as int?) ?? 0;
    final riskCode = (result['riskCode'] as String?) ?? 'LOW';
    final riskTitle = (result['riskTitle'] as String?) ?? context.tr('homeRiskLowTitle');
    final color = _colorForRisk(riskCode, isDark);
    final icon = _iconForRisk(riskCode);
    final subtitle = _subtitleForRisk(riskCode);
    final description = _descriptionForRisk(riskCode);
    final isFullAssessment = (result['type'] as String?) == 'FULL ASSESSMENT';
    return _buildResultContainer(isDark, pct, riskCode, riskTitle, color, icon, subtitle, description, isFullAssessment);
  }

  Widget _buildResultContainer(bool isDark, int pct, String riskCode, String riskTitle, Color color, IconData icon, String subtitle, String description, bool isFullAssessment) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(color: card.withValues(alpha: isDark ? 1.0 : 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: (isDark ? AppColors.darkBorder : Colors.white).withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 12))]),
        child: Column(
          children: [
            Text(context.tr('homeLastResult'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
              child: Text(isFullAssessment ? context.tr('homeFullCheck') : context.tr('homeQuickCheck'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: 220,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CustomPaint(size: const Size(220, 110), painter: GaugePainter(percentage: pct / 100, color: color)),
                  Positioned(bottom: 0, child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$pct%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: fg, height: 1)), const SizedBox(height: 10)])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 24), const SizedBox(width: 8), Text(riskTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fg))]),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 18),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.1))), child: Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg, height: 1.5))),
            const SizedBox(height: 20),
            if (!isFullAssessment) ...[
              _buildResultButton(context.tr('homeContinueFullResult'), color, Colors.white, true, borderColor: Colors.white.withValues(alpha: 0.9), onPressed: () => Navigator.pushNamed(context, AppRoutes.fullAssessment), isDark: isDark),
              const SizedBox(height: 10),
            ],
            if (riskCode.toUpperCase() != 'LOW') ...[_buildInfoCard(color, isDark), const SizedBox(height: 10)],
            if (_isMediumRisk(riskCode)) ...[_buildNearestClinicButton(isDark), const SizedBox(height: 10)],
            _buildResultButton(context.tr('homeViewSymptomInsight'), card.withValues(alpha: 0.88), color, false, borderColor: color.withValues(alpha: 0.42), onPressed: () => _openSymptomInsight(color, riskCode, riskTitle, pct, isFullAssessment, icon), isDark: isDark),
            const SizedBox(height: 10),
            _buildResultButton(isFullAssessment ? context.tr('homeRetakeFull') : context.tr('homeRetakeQuick'), card, isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground, false, borderColor: (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.3), onPressed: () => _onRetakeAssessment(isFullAssessment), isDark: isDark),
          ],
        ),
      ),
    );
  }

  bool _isMediumRisk(String code) {
    final c = code.toUpperCase();
    return c.contains('MEDIUM') || c.contains('MODERATE') || c.contains('SEDANG');
  }

  Widget _buildNearestClinicButton(bool isDark) {
    final warning = isDark ? AppColors.darkWarning : AppColors.warning;
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: warning,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.1),
        boxShadow: [BoxShadow(color: warning.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 6)), BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => UrlUtils.launchNearestClinicMap(context),
        icon: const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
        label: Text(context.tr('clinicNearestButton'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Future<void> _openSymptomInsight(Color color, String riskCode, String riskTitle, int pct, bool isFullAssessment, IconData icon, {String? sessionKey}) async {
    Map<String, dynamic>? detail;
    final stored = _storedResult;
    if (stored != null && _config != null) {
      detail = isFullAssessment ? _buildGuestFullDetail(stored, pct, riskTitle, riskCode) : _buildGuestQuickDetail(stored, pct, riskTitle, riskCode);
    }
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.historyDetail, arguments: {'sessionKey': sessionKey ?? '', 'date': context.tr('historyDateNow'), 'riskLevel': riskTitle, 'riskLevelCode': riskCode, 'percentage': '$pct%', 'tbType': '', 'type': isFullAssessment ? context.tr('homeFullCheck') : context.tr('homeQuickCheck'), 'color': color, 'icon': icon, 'detailData': detail});
  }

  Map<String, dynamic>? _buildGuestFullDetail(Map<String, dynamic> stored, int pct, String riskTitle, String riskCode) {
    final results = stored['fullResults'] as List<dynamic>?;
    if (results == null) return null;
    final items = <Map<String, dynamic>>[];
    for (final r in results) {
      if (r is! Map) continue;
      final rl = r['riskLevel'] as Map<String, dynamic>?;
      final symptomDetails = (r['symptomDetails'] as List<dynamic>?) ?? [];
      final selected = symptomDetails.where((s) => s is Map && ((s['cfValue'] as num?)?.toDouble() ?? 0) > 0).map((s) {
        final m = s as Map;
        return {'symptomName': m['symptomName'] ?? '-', 'symptomCode': m['symptomCode'] ?? '', 'symptomDescription': m['symptomDescription'], 'cfValue': 1.0, 'tbTypeId': (m['originTbTypeId'] as num?)?.toInt() ?? (r['tbTypeId'] as num?)?.toInt() ?? 0};
      }).toList();
      if (selected.isEmpty) continue;
      items.add({'primaryTbTypeId': (r['tbTypeId'] as num?)?.toInt() ?? 0, 'primaryTbTypeName': r['tbTypeName'] ?? 'Unknown', 'totalScore': (r['totalScore'] as num?)?.toDouble() ?? 0, 'riskLevelTitle': rl?['title'] ?? riskTitle, 'riskLevelCode': rl?['code'] ?? riskCode, 'selectedSymptoms': selected, 'scoreBreakdown': {'results': [{'riskLevel': {'recommendation': rl?['recommendation'] ?? ''}}]}});
    }
    return {'items': items, 'createdAt': DateTime.now().toIso8601String(), 'assessmentTypeName': 'Full Assessment'};
  }

  Map<String, dynamic>? _buildGuestQuickDetail(Map<String, dynamic> stored, int pct, String riskTitle, String riskCode) {
    if (_config == null) return null;
    final symptoms = stored['symptoms'] as Map<String, dynamic>? ?? {};
    final selected = <Map<String, dynamic>>[];
    for (final q in _config!.questions) {
      if (symptoms[q.symptomId.toString()] != true) continue;
      selected.add({'symptomName': q.symptomName, 'symptomCode': q.symptomCode, 'symptomDescription': q.symptomDescription, 'cfValue': 1.0, 'tbTypeId': q.tbTypeId});
    }
    if (selected.isEmpty) return null;
    return {
      'items': [{'primaryTbTypeId': 1, 'primaryTbTypeName': _config!.questions.first.tbTypeName ?? 'TBC Paru', 'totalScore': pct.toDouble(), 'riskLevelTitle': riskTitle, 'riskLevelCode': riskCode, 'selectedSymptoms': selected, 'scoreBreakdown': {'results': [{'riskLevel': {'recommendation': stored['description'] ?? ''}}]}}],
      'createdAt': DateTime.now().toIso8601String(),
      'assessmentTypeName': 'Quick Assessment'
    };
  }

  Widget _buildInfoCard(Color color, bool isDark) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))), child: Row(children: [Icon(Icons.info_outline_rounded, color: color, size: 20), const SizedBox(width: 10), Expanded(child: Text(context.tr('homeInfoIfRisk'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, height: 1.4)))]));
  }

  Widget _buildResultButton(String text, Color bgColor, Color textColor, bool hasShadow, {Color? borderColor, VoidCallback? onPressed, required bool isDark}) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: bgColor, border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1), boxShadow: hasShadow ? [BoxShadow(color: bgColor.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 6)), BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: ElevatedButton(onPressed: onPressed ?? () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor))),
    );
  }

  Widget _buildRecentResultCard(bool isDark) {
    if (_mostRecentAssessment == null) return _buildAssessmentCard(isDark);
    final assessment = _mostRecentAssessment!;
    final assessmentTypeId = assessment['assessmentTypeId'] as int? ?? 1;
    final riskLevelCode = assessment['riskLevelCode'] as String? ?? 'LOW';
    final riskLevelTitle = assessment['riskLevelTitle'] as String? ?? context.tr('homeRiskLowTitle');
    final totalScore = assessment['totalScore'] as num? ?? 0;
    final pct = totalScore.toInt();
    final color = _colorForRisk(riskLevelCode, isDark);
    final subtitle = _subtitleForRisk(riskLevelCode);
    final description = _descriptionForRisk(riskLevelCode);
    final isFullAssessment = assessmentTypeId == 2;
    final assessmentBadge = isFullAssessment ? context.tr('homeFullCheck') : context.tr('homeQuickCheck');
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(color: card.withValues(alpha: isDark ? 1.0 : 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: (isDark ? AppColors.darkBorder : Colors.white).withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 12))]),
        child: Column(
          children: [
            Text(context.tr('homeLastResult'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))), child: Text(assessmentBadge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
            const SizedBox(height: 20),
            SizedBox(height: 120, width: 220, child: Stack(alignment: Alignment.bottomCenter, children: [CustomPaint(size: const Size(220, 110), painter: GaugePainter(percentage: pct / 100, color: color)), Positioned(bottom: 0, child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$pct%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: fg, height: 1)), const SizedBox(height: 10)]))])),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_iconForRisk(riskLevelCode), color: color, size: 24), const SizedBox(width: 8), Text(riskLevelTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fg))]),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 18),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.1))), child: Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg, height: 1.5))),
            const SizedBox(height: 20),
            if (!isFullAssessment) ...[_buildResultButton(context.tr('homeContinueFullResult'), color, Colors.white, true, borderColor: Colors.white.withValues(alpha: 0.9), onPressed: () => Navigator.pushNamed(context, AppRoutes.fullAssessment), isDark: isDark), const SizedBox(height: 10)],
            if (riskLevelCode.toUpperCase() != 'LOW') ...[_buildInfoCard(color, isDark), const SizedBox(height: 10)],
            if (_isMediumRisk(riskLevelCode)) ...[_buildNearestClinicButton(isDark), const SizedBox(height: 10)],
            _buildResultButton(context.tr('homeViewSymptomInsight'), card.withValues(alpha: 0.88), color, false, borderColor: color.withValues(alpha: 0.42), onPressed: () => _openSymptomInsight(color, riskLevelCode, riskLevelTitle, pct, isFullAssessment, _iconForRisk(riskLevelCode), sessionKey: assessment['sessionKey'] as String?), isDark: isDark),
            const SizedBox(height: 10),
            _buildResultButton(isFullAssessment ? context.tr('homeRetakeFull') : context.tr('homeRetakeQuick'), card, isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground, false, borderColor: (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.3), onPressed: () => _onRetakeAssessment(isFullAssessment), isDark: isDark),
          ],
        ),
      ),
    );
  }

  Future<void> _onRetakeAssessment(bool isFullAssessment) async {
    if (isFullAssessment) Navigator.pushNamed(context, AppRoutes.fullAssessment);
    else setState(() {_storedResult = null; if (_config != null) _symptomStates = {for (final q in _config!.questions) q.symptomId: false}; _mostRecentAssessment = null;});
  }

  Color _colorForRisk(String code, bool isDark) {
    switch (code.toUpperCase()) {
      case 'HIGH':
        return isDark ? AppColors.darkDestructive : AppColors.destructive;
      case 'MEDIUM':
        return isDark ? AppColors.darkWarning : AppColors.warning;
      default:
        return isDark ? AppColors.darkPrimary : AppColors.primary;
    }
  }

  IconData _iconForRisk(String code) {
    switch (code.toUpperCase()) {
      case 'HIGH':
        return Icons.report_problem_outlined;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _subtitleForRisk(String code) {
    switch (code.toUpperCase()) {
      case 'HIGH':
        return context.tr('homeHighSubtitle');
      case 'MEDIUM':
        return context.tr('homeMediumSubtitle');
      default:
        return context.tr('homeLowSubtitle');
    }
  }

  String _descriptionForRisk(String code) {
    switch (code.toUpperCase()) {
      case 'HIGH':
        return context.tr('homeHighDesc');
      case 'MEDIUM':
        return context.tr('homeMediumDesc');
      default:
        return context.tr('homeLowDesc');
    }
  }

  Widget _buildScatteredAuras(double sw, double sh, bool isDark) {
    return Stack(children: [
      Positioned(top: -50, right: -50, child: _buildAura(130, (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1))),
      Positioned(top: sh * 0.2, left: -80, child: _buildAura(150, (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(alpha: 0.05))),
      Positioned(bottom: 80, right: 20, child: _buildAura(90, (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.1))),
    ]);
  }

  Widget _buildAura(double size, Color color) => Container(width: size * 2, height: size * 2, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2)]));
}

class GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  GaugePainter({required this.percentage, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    paint.color = color.withValues(alpha: 0.15);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, paint);
    paint.color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi * percentage.clamp(0.0, 1.0), false, paint);
    final angle = math.pi + math.pi * percentage.clamp(0.0, 1.0);
    final dot = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
    canvas.drawCircle(dot, 6, Paint()..color = Colors.white);
    canvas.drawCircle(dot, 4, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
