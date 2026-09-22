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
import '../../../core/l10n/tb_content_l10n.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/url_utils.dart';

enum RiskLevel { low, medium, high }

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  RiskLevel _currentRisk = RiskLevel.low;
  int _percentage = 0;
  Map<String, dynamic>? _assessmentData;
  bool _isFullAssessment = false;
  Map<String, dynamic>? _fullResultData;
  bool _loaded = false;
  bool _argumentsLoaded = false;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onLocaleChanged);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsLoaded) {
      _argumentsLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final raw = ModalRoute.of(context)?.settings.arguments;
      if (raw is Map) {
        _isFullAssessment = (raw['isFullAssessment'] as bool?) ?? false;
        if (_isFullAssessment) {
          _fullResultData = raw['result'] as Map<String, dynamic>?;
        } else {
          final rl = raw['riskLevel'];
          if (rl is RiskLevel) _currentRisk = rl;
          else if (rl is String) {
            switch (rl.toLowerCase()) {
              case 'high':
                _currentRisk = RiskLevel.high;
                break;
              case 'medium':
                _currentRisk = RiskLevel.medium;
                break;
              default:
                _currentRisk = RiskLevel.low;
            }
          }
          _percentage = (raw['percentage'] as int?) ?? _percentage;
          _assessmentData = raw['assessmentData'] as Map<String, dynamic>?;
        }
      } else if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }
      if (!mounted) return;
      setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _openSymptomInsight(Color mainColor, IconData riskIcon) async {
    if (_assessmentData == null) return;
    final symptoms = _assessmentData!['symptoms'] as Map<String, dynamic>? ?? {};
    QuickCheckConfig config;
    try {
      config = await LocalAssessmentService.getQuickCheckConfig();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('resultFailedSymptom'))));
      return;
    }
    final Map<int, List<Map<String, dynamic>>> byTbType = {};
    final Map<int, String> tbTypeNames = {};
    for (final q in config.questions) {
      final selected = symptoms[q.symptomId.toString()] == true;
      if (!selected) continue;
      final targets = q.applicableTbTypes.isNotEmpty ? q.applicableTbTypes : [TbTypeWeight(tbTypeId: q.tbTypeId, tbTypeName: q.tbTypeName ?? '', weight: q.weight)];
      for (final t in targets) {
        tbTypeNames[t.tbTypeId] = t.tbTypeName;
        byTbType.putIfAbsent(t.tbTypeId, () => []).add({'symptomName': q.symptomName, 'symptomCode': q.symptomCode, 'symptomDescription': q.symptomDescription, 'cfValue': 1.0, 'tbTypeId': q.tbTypeId});
      }
    }
    Map<String, dynamic>? detail;
    if (byTbType.isNotEmpty) {
      final items = <Map<String, dynamic>>[];
      for (final entry in byTbType.entries) {
        final typeId = entry.key;
        items.add({'primaryTbTypeId': typeId, 'primaryTbTypeName': tbTypeNames[typeId] ?? 'Unknown', 'totalScore': _percentage, 'riskLevelTitle': _assessmentData!['riskTitle'] ?? context.tr('homeRiskLowTitle'), 'riskLevelCode': _assessmentData!['riskCode'] ?? 'LOW', 'selectedSymptoms': entry.value, 'scoreBreakdown': {'results': [{'riskLevel': {'recommendation': _assessmentData!['description'] ?? ''}}]}});
      }
      detail = {'items': items, 'createdAt': DateTime.now().toIso8601String(), 'assessmentTypeName': 'Quick Assessment'};
    }
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.historyDetail, arguments: {'sessionKey': '', 'date': context.tr('historyDateNow'), 'riskLevel': _assessmentData!['riskTitle'] ?? context.tr('homeRiskLowTitle'), 'riskLevelCode': _assessmentData!['riskCode'] ?? 'LOW', 'percentage': '$_percentage%', 'tbType': '', 'type': context.tr('homeQuickCheck'), 'color': mainColor, 'icon': riskIcon, 'detailData': detail});
  }

  Map<String, dynamic> _getRiskData() {
    final dbTitle = _assessmentData?['riskTitle'] as String?;
    final dbDescription = _assessmentData?['description'] as String?;
    String title;
    String subtitle;
    String description;
    Color color;
    IconData icon;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_currentRisk) {
      case RiskLevel.low:
        title = dbTitle ?? context.tr('homeRiskLowTitle');
        subtitle = context.tr('homeLowSubtitle');
        description = dbDescription ?? context.tr('homeLowDesc');
        color = isDark ? AppColors.darkPrimary : AppColors.primary;
        icon = Icons.check_circle_outline;
        break;
      case RiskLevel.medium:
        title = dbTitle ?? context.tr('homeRiskMediumTitle');
        subtitle = context.tr('homeMediumSubtitle');
        description = dbDescription ?? context.tr('homeMediumDesc');
        color = isDark ? AppColors.darkWarning : AppColors.warning;
        icon = Icons.info_outline;
        break;
      case RiskLevel.high:
        title = dbTitle ?? context.tr('homeRiskHighTitle');
        subtitle = context.tr('homeHighSubtitle');
        description = dbDescription ?? context.tr('homeHighDesc');
        color = isDark ? AppColors.darkDestructive : AppColors.destructive;
        icon = Icons.report_problem_outlined;
        break;
    }
    return {'percentage': _percentage, 'title': title, 'subtitle': subtitle, 'description': description, 'color': color, 'icon': icon, 'auraColor': color.withValues(alpha: 0.1)};
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(backgroundColor: isDark ? AppColors.darkBackground : AppColors.background, body: const Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [_buildScatteredAuras(sw, sh, isDark), _isFullAssessment && _fullResultData != null ? _buildFullResultView(isDark) : _buildQuickResultView(isDark)]),
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (i) { final routes = [AppRoutes.home, AppRoutes.history, AppRoutes.profile]; if (i < routes.length) Navigator.pushNamedAndRemoveUntil(context, routes[i], (route) => false); }),
    );
  }

  Widget _buildQuickResultView(bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(children: [
          const ResponsiveCenter(maxWidth: 720, child: HomeHeader(isGuest: false)),
          ResponsiveCenter(maxWidth: 720, padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [Text(context.tr('resultTitle'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fg, letterSpacing: -0.5)), const SizedBox(height: 6), Text(context.tr('resultSubtitle'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mutedFg))])),
          const SizedBox(height: 18),
          ResponsiveCenter(maxWidth: 720, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _buildResultCard(_getRiskData(), isDark)),
        ]),
      ),
    );
  }

  Widget _buildFullResultView(bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return SafeArea(
      child: CustomScrollView(slivers: [
        const SliverToBoxAdapter(child: ResponsiveCenter(maxWidth: 720, child: HomeHeader(isGuest: false))),
        SliverToBoxAdapter(child: ResponsiveCenter(maxWidth: 720, padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('resultFullTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: fg, letterSpacing: -0.6)), const SizedBox(height: 6), Text(context.tr('resultFullSubtitle'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mutedFg))]))),
        SliverList(delegate: SliverChildBuilderDelegate((context, index) {
          final sortedResults = List<Map<String, dynamic>>.from((_fullResultData!['results'] as List).cast<Map<String, dynamic>>());
          sortedResults.sort((a, b) {
            String? codeOf(Map<String, dynamic> m) => (m['riskLevel'] as Map<String, dynamic>?)?['code'] as String?;
            final ra = _riskRank(codeOf(a));
            final rb = _riskRank(codeOf(b));
            if (ra != rb) return rb.compareTo(ra);
            return ((b['totalScore'] as num?)?.toDouble() ?? 0).compareTo((a['totalScore'] as num?)?.toDouble() ?? 0);
          });
          final result = sortedResults[index];
          return ResponsiveCenter(maxWidth: 720, padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: _buildCategoryResultCard(result, isDark));
        }, childCount: (_fullResultData!['results'] as List).length)),
        SliverToBoxAdapter(child: ResponsiveCenter(maxWidth: 720, padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), child: Column(children: [SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: _goHome, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18), label: Text(context.tr('resultBackHome'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary, foregroundColor: Colors.white, elevation: 4, shadowColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))))]))),
      ]),
    );
  }

  void _goHome() => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  int _riskRank(String? code) { final c = (code ?? '').toUpperCase(); if (c.contains('HIGH')) return 3; if (c.contains('MEDIUM') || c.contains('MODERATE')) return 2; return 1; }

  Widget _buildCategoryResultCard(Map<String, dynamic> result, bool isDark) {
    final rawTitle = result['tbTypeName'] ?? context.tr('resultCategoryUnknown');
    final title = TbContentL10n.tbType(rawTitle.toString(), AppSettings.instance.locale);
    final score = (result['totalScore'] as num?)?.toInt() ?? 0;
    final riskLevel = result['riskLevel'] as Map<String, dynamic>?;
    final rawRiskTitle = riskLevel?['title'] ?? context.tr('homeRiskLowTitle');
    final riskTitle = TbContentL10n.riskTitle(rawRiskTitle.toString(), AppSettings.instance.locale);
    final riskCode = (riskLevel?['code'] ?? 'LOW').toString().toUpperCase();
    Color color;
    IconData riskIcon;
    if (riskCode.contains('HIGH')) { color = isDark ? AppColors.darkDestructive : AppColors.destructive; riskIcon = Icons.error_outline_rounded; } else if (riskCode.contains('MEDIUM') || riskCode.contains('MODERATE')) { color = isDark ? AppColors.darkWarning : AppColors.warning; riskIcon = Icons.warning_amber_rounded; } else { color = isDark ? AppColors.darkPrimary : AppColors.primary; riskIcon = Icons.check_circle_outline_rounded; }
    final symptoms = (result['symptomDetails'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final selectedSymptoms = symptoms.where((s) => (s['cfValue'] as num?)?.toDouble() == 1.0).toList();
    final containerColor = color.withValues(alpha: 0.06);
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Container(
      decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)), const SizedBox(height: 3), Text('$riskTitle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))])), Column(children: [Text('$score%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, height: 1)), const SizedBox(height: 4), Icon(riskIcon, color: color, size: 22)])]),
        if (selectedSymptoms.isNotEmpty) ...[const SizedBox(height: 14), _buildSymptomGroups(selectedSymptoms, color, result['tbTypeId'] as int? ?? 0, isDark)],
        if (riskCode.contains('MEDIUM') || riskCode.contains('MODERATE')) ...[const SizedBox(height: 14), _buildNearestClinicButton(isDark)],
      ]),
    );
  }

  Widget _buildSymptomGroups(List<Map<String, dynamic>> symptoms, Color color, int currentTbTypeId, bool isDark) {
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final umum = symptoms.where((s) { final code = (s['symptomCode'] as String?) ?? ''; if (!code.startsWith('G')) return false; final digits = code.replaceAll(RegExp(r'[^0-9]'), ''); final numPart = int.tryParse(digits); return numPart != null && numPart >= 1 && numPart <= 8 && !code.contains(RegExp(r'[a-z]')); }).toList();
    final khusus = symptoms.where((s) { final code = (s['symptomCode'] as String?) ?? ''; if (!code.startsWith('G')) return true; final digits = code.replaceAll(RegExp(r'[^0-9]'), ''); final numPart = int.tryParse(digits); return numPart == null || numPart > 8 || code.contains(RegExp(r'[a-z]')); }).toList();
    final isTbType1 = currentTbTypeId == 1;
    if (isTbType1) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('resultSymptomSelected', {'count': '${symptoms.length}'}), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: mutedFg.withValues(alpha: 0.9))), const SizedBox(height: 8), ...symptoms.map((s) => _buildSymptomChip(s, color, isDark))]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (umum.isNotEmpty) ...[Text(context.tr('resultCommonSymptom', {'count': '${umum.length}'}), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: mutedFg.withValues(alpha: 0.9))), const SizedBox(height: 8), ...umum.map((s) => _buildSymptomChip(s, color, isDark)), if (khusus.isNotEmpty) const SizedBox(height: 12)], if (khusus.isNotEmpty) ...[Text(context.tr('resultSpecificSymptom', {'count': '${khusus.length}'}), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: mutedFg.withValues(alpha: 0.9))), const SizedBox(height: 8), ...khusus.map((s) => _buildSymptomChip(s, color, isDark))]]);
  }

  Widget _buildSymptomChip(Map<String, dynamic> s, Color color, bool isDark) {
    final locale = AppSettings.instance.locale;
    final name = TbContentL10n.symptomName((s['symptomName'] ?? '-').toString(), locale);
    return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.08))), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: color, size: 14)), const SizedBox(width: 10), Expanded(child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkForeground : AppColors.foreground)))]));
  }
  Widget _buildResultCard(Map<String, dynamic> data, bool isDark) {
    Color mainColor = data['color'];
    final pct = data['percentage'] as int;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return Container(
      decoration: BoxDecoration(color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(24), border: Border.all(color: mainColor.withValues(alpha: 0.2))),
      child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
        const SizedBox(height: 8),
        SizedBox(height: 130, width: 230, child: Stack(alignment: Alignment.bottomCenter, children: [CustomPaint(size: const Size(230, 115), painter: GaugePainter(percentage: pct / 100, color: mainColor)), Positioned(bottom: 0, child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$pct%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: fg, height: 1)), const SizedBox(height: 10)]))])),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(data['icon'] as IconData, color: mainColor, size: 22), const SizedBox(width: 6), Text(data['title'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg))]),
        const SizedBox(height: 4),
        Text(data['subtitle'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mainColor)),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: mainColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: mainColor.withValues(alpha: 0.1))), child: Text(data['description'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg, height: 1.4))),
        const SizedBox(height: 16),
        _buildButton(context.tr('homeContinueFullResult'), mainColor, Colors.white, true, isDark: isDark, onPressed: () => Navigator.pushNamed(context, AppRoutes.fullAssessment)),
        const SizedBox(height: 8),
        if (_currentRisk != RiskLevel.low) ...[_buildInfoCard(mainColor, isDark), const SizedBox(height: 8)],
        if (_currentRisk == RiskLevel.medium) ...[_buildNearestClinicButton(isDark), const SizedBox(height: 8)],
        _buildButton(context.tr('homeViewSymptomInsight'), (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.88), mainColor, false, isDark: isDark, borderColor: mainColor.withValues(alpha: 0.42), onPressed: () => _openSymptomInsight(mainColor, data['icon'] as IconData)),
        const SizedBox(height: 8),
        _buildButton(context.tr('resultBackHome'), _currentRisk == RiskLevel.low ? (isDark ? AppColors.darkSurface : Colors.white) : Colors.transparent, _currentRisk == RiskLevel.low ? mainColor : (isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground), false, isDark: isDark, borderColor: _currentRisk == RiskLevel.low ? mainColor.withValues(alpha: 0.2) : (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.3), onPressed: _goHome),
      ])),
    );
  }

  Widget _buildInfoCard(Color color, bool isDark) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))), child: Row(children: [Icon(Icons.info_outline_rounded, color: color, size: 18), const SizedBox(width: 8), Expanded(child: Text(context.tr('homeInfoIfRisk'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)))]));
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

  Widget _buildButton(String text, Color bgColor, Color textColor, bool hasShadow, {Color? borderColor, VoidCallback? onPressed, required bool isDark}) => Container(width: double.infinity, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: bgColor == Colors.transparent ? (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.88) : bgColor, border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1), boxShadow: hasShadow ? [BoxShadow(color: bgColor.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 6)), BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]), child: ElevatedButton(onPressed: onPressed ?? () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor))));
  Widget _buildScatteredAuras(double sw, double sh, bool isDark) => Stack(children: [Positioned(top: -sw * 0.05, right: -sw * 0.2, child: _buildAura(160, (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.08))), Positioned(top: sh * 0.25, left: -sw * 0.15, child: _buildAura(140, (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(alpha: 0.05)))]);
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
