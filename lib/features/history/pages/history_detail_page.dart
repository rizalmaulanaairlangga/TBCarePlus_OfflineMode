import 'package:flutter/material.dart';
import '../../../core/services/local_assessment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/tb_content_l10n.dart';
import '../../../core/settings/app_settings.dart';

class HistoryDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? detail;

  const HistoryDetailPage({super.key, required this.item, this.detail});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onLocaleChanged);
    _loadDetail();
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
  Map<String, dynamic>? _detail;
  String? _loadError;
  final Map<String, bool> _tbTypeExpanded = {};

  Future<void> _loadDetail() async {
    if (widget.detail != null) {
      setState(() {_detail = widget.detail; _loading = false;});
      return;
    }
    final sessionKey = widget.item['sessionKey'] as String?;
    if (sessionKey == null || sessionKey.isEmpty) {
      setState(() {_detail = null; _loading = false;});
      return;
    }
    try {
      final d = await LocalAssessmentService.fetchHistorySessionDetail(sessionKey);
      if (!mounted) return;
      setState(() {_detail = d; _loading = false;});
    } catch (e) {
      if (!mounted) return;
      setState(() {_loadError = e.toString(); _loading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final color = widget.item['color'] as Color;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final items = (_detail?['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    int riskWeight(String? code) { final c = (code ?? '').toUpperCase(); if (c.contains('HIGH')) return 3; if (c.contains('MEDIUM') || c.contains('MODERATE')) return 2; return 1; }
    items.sort((a, b) { final r1 = riskWeight(a['riskLevelCode'] as String?); final r2 = riskWeight(b['riskLevelCode'] as String?); if (r1 != r2) return r2.compareTo(r1); return ((b['totalScore'] as num?)?.toDouble() ?? 0).compareTo((a['totalScore'] as num?)?.toDouble() ?? 0); });
    String recommendation = context.tr('historyRecommendation');
    if (items.isNotEmpty) {
      for (final it in items) {
        final breakdown = it['scoreBreakdown'];
        if (breakdown is Map && breakdown['results'] is List && (breakdown['results'] as List).isNotEmpty) {
          final primaryResult = (breakdown['results'] as List).first;
          if (primaryResult is Map && primaryResult['riskLevel'] is Map) {
            final rec = (primaryResult['riskLevel'] as Map)['recommendation'];
            if (rec is String && rec.isNotEmpty) { recommendation = TbContentL10n.riskReco(rec, AppSettings.instance.locale); break; }
          }
        }
      }
    }
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        _buildScatteredAuras(screenWidth, screenHeight, color, isDark),
        SafeArea(child: Column(children: [
          ResponsiveCenter(maxWidth: 720, child: _buildHeader(context, color, isDark)),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _loadError != null ? Center(child: ResponsiveCenter(maxWidth: 720, padding: const EdgeInsets.symmetric(horizontal: 16), child: ErrorState(message: _loadError!, type: 'offline', onRetry: _loadDetail))) : SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ResponsiveCenter(maxWidth: 720, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSummaryCard(color, isDark), const SizedBox(height: 18), if (items.isNotEmpty) ...[Text(context.tr('historyDetailType'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkForeground : AppColors.foreground, letterSpacing: -0.3)), const SizedBox(height: 12), ...items.map((it) => _buildTbTypeSection(context, it, color, isDark)), const SizedBox(height: 24)], _buildRecommendationCard(color, recommendation, isDark), const SizedBox(height: 18), _buildDeleteButton(isDark), const SizedBox(height: 32)])))),
        ])),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context, Color color, bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: card.withValues(alpha: 0.9), shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: Icon(Icons.arrow_back, color: fg, size: 18))), const SizedBox(width: 12), Expanded(child: Text(context.tr('historyDetailTitle'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.3))), const SizedBox(width: 36)]));
  }

  Widget _buildSummaryCard(Color color, bool isDark) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5)), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.item['date'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.8))), const SizedBox(height: 3), Text(widget.item['type'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 1.0))]), Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(widget.item['icon'], color: color, size: 22))]),
      const SizedBox(height: 18),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [SizedBox(width: 90, child: Column(mainAxisSize: MainAxisSize.min, children: [Text(widget.item['percentage'], style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, height: 1.0)), const SizedBox(height: 3), Text((widget.item['tbType'] as String?)?.isNotEmpty == true ? (widget.item['tbType'] as String) : context.tr('historyDetailType'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.6)))])), const SizedBox(width: 14), Container(width: 2, height: 50, color: color.withValues(alpha: 0.1)), const SizedBox(width: 14), Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(widget.item['riskLevel'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.1)), const SizedBox(height: 3), Text(widget.item['riskLevelCode'] == 'HIGH' ? context.tr('historyNeedAttention') : context.tr('historyMonitor'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.7)))]))]),
    ]));
  }

  Widget _buildTbTypeSection(BuildContext context, Map<String, dynamic> item, Color themeColor, bool isDark) {
    final rawTbName = (item['primaryTbTypeName'] ?? '').toString();
    final tbTypeName = TbContentL10n.tbType(rawTbName, AppSettings.instance.locale);
    final score = (item['totalScore'] is num) ? (item['totalScore'] as num).round() : 0;
    final rawRiskTitle = (item['riskLevelTitle'] ?? 'Low Risk').toString();
    final riskTitle = TbContentL10n.riskTitle(rawRiskTitle, AppSettings.instance.locale);
    final riskCode = (item['riskLevelCode'] ?? 'LOW').toString().toUpperCase();
    Color resolvedColor; if (riskCode.contains('HIGH')) resolvedColor = isDark ? AppColors.darkDestructive : const Color(0xFFEF4444); else if (riskCode.contains('MEDIUM') || riskCode.contains('MODERATE')) resolvedColor = isDark ? AppColors.darkWarning : const Color(0xFFF59E0B); else resolvedColor = isDark ? AppColors.darkPrimary : const Color(0xFF10B981);
    final locale = AppSettings.instance.locale;
    final selectedSymptomsRaw = item['selectedSymptoms']; final selectedSymptoms = selectedSymptomsRaw is List ? selectedSymptomsRaw : <dynamic>[];
    final symptoms = selectedSymptoms.where((s) => s is Map && (s['cfValue'] is num) && (s['cfValue'] as num) > 0).map((s) { final m = s as Map; final desc = m['symptomDescription'] as String?; final rawCode = (m['symptomCode'] ?? m['code'] ?? '').toString(); final rawTypeId = m['tbTypeId'] ?? m['originTbTypeId'] ?? 0; final rawName = (m['symptomName'] ?? m['name'] ?? '-').toString(); return {'name': TbContentL10n.symptomName(rawName, locale), 'code': rawCode, 'desc': (desc != null && desc.isNotEmpty) ? TbContentL10n.symptomDesc(desc, locale) : context.tr('commonNoDescription'), 'cfValue': m['cfValue'] ?? 0, 'tbTypeId': (rawTypeId is num) ? rawTypeId.toInt() : int.tryParse(rawTypeId.toString()) ?? 0}; }).toList();
    final currentTbTypeId = (item['primaryTbTypeId'] as num?)?.toInt() ?? 0;
    final isExpanded = _tbTypeExpanded[rawTbName] ?? true;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: resolvedColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: resolvedColor.withValues(alpha: 0.12), width: 1.2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _tbTypeExpanded[rawTbName] = !isExpanded), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tbTypeName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: fg)), const SizedBox(height: 3), Text('$riskTitle ($riskCode)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: resolvedColor.withValues(alpha: 0.75)))])), Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: resolvedColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(100)), child: Text('$score%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: resolvedColor))), const SizedBox(width: 6), Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: resolvedColor, size: 20)])]))),
      ClipRect(child: AnimatedAlign(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, alignment: Alignment.topCenter, heightFactor: isExpanded ? 1.0 : 0.0, child: AnimatedOpacity(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, opacity: isExpanded ? 1.0 : 0.0, child: Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [if (symptoms.isNotEmpty) _buildSymptomGroups(symptoms, resolvedColor, currentTbTypeId, isDark)]))))),
    ]));
  }

  Widget _buildSymptomGroups(List<Map<String, dynamic>> symptoms, Color color, int currentTbTypeId, bool isDark) {
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final umum = symptoms.where((s) { final code = (s['code'] as String?) ?? ''; if (!code.startsWith('G')) return false; final digits = code.replaceAll(RegExp(r'[^0-9]'), ''); final numPart = int.tryParse(digits); return numPart != null && numPart >= 1 && numPart <= 8 && !code.contains(RegExp(r'[a-z]')); }).toList();
    final khusus = symptoms.where((s) { final code = (s['code'] as String?) ?? ''; if (!code.startsWith('G')) return true; final digits = code.replaceAll(RegExp(r'[^0-9]'), ''); final numPart = int.tryParse(digits); return numPart == null || numPart > 8 || code.contains(RegExp(r'[a-z]')); }).toList();
    final isTbType1 = currentTbTypeId == 1;
    if (isTbType1) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('historySymptomSelected', {'count': '${symptoms.length}'}), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: mutedFg.withValues(alpha: 0.9))), const SizedBox(height: 8), ...symptoms.map((s) => _buildSymptomChip(s, color, isDark))]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (umum.isNotEmpty) ...[Text(context.tr('historyCommonSymptom', {'count': '${umum.length}'}), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: mutedFg.withValues(alpha: 0.9))), const SizedBox(height: 8), ...umum.map((s) => _buildSymptomChip(s, color, isDark)), if (khusus.isNotEmpty) const SizedBox(height: 12)], if (khusus.isNotEmpty) ...[Text(context.tr('historySpecificSymptom', {'count': '${khusus.length}'}), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: mutedFg.withValues(alpha: 0.9))), const SizedBox(height: 8), ...khusus.map((s) => _buildSymptomChip(s, color, isDark))]]);
  }

  Widget _buildSymptomChip(Map<String, dynamic> symptom, Color themeColor, bool isDark) {
    final controller = ExpansibleController();
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.foreground;
    return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14), border: Border.all(color: themeColor.withValues(alpha: 0.12))), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Theme(data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent, hoverColor: Colors.transparent, focusColor: Colors.transparent, splashFactory: NoSplash.splashFactory, dividerColor: Colors.transparent), child: ExpansionTile(controller: controller, backgroundColor: Colors.transparent, collapsedBackgroundColor: Colors.transparent, shape: const Border(), collapsedShape: const Border(), tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), leading: Container(width: 40, height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withValues(alpha: 0.15), themeColor.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.check_circle_rounded, color: themeColor, size: 20)), title: Text(symptom['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkForeground : AppColors.foreground)), children: [Align(alignment: Alignment.centerLeft, child: Text(symptom['desc'], style: TextStyle(fontSize: 12, color: (isDark ? AppColors.darkForeground : AppColors.foreground).withValues(alpha: 0.8), height: 1.5)))]))));
  }

  Future<void> _confirmDeleteHistory() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: isDark ? AppColors.darkSurface : Colors.white, title: Text(context.tr('historyDeleteThisTitle')), content: Text(context.tr('historyDeleteThisContent')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))), FilledButton(style: FilledButton.styleFrom(backgroundColor: isDark ? AppColors.darkDestructive : AppColors.destructive), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete')))]));
    if (confirmed != true) return;
    String? sessionKey = widget.item['sessionKey'] as String?;
    if (sessionKey == null || sessionKey.isEmpty) sessionKey = _detail?['sessionKey'] as String?;
    if (sessionKey == null || sessionKey.isEmpty) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('historyDeleteFailNotFound')))); return; }
    final ok = await LocalAssessmentService.deleteHistorySession(sessionKey);
    if (!mounted) return;
    if (!ok) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('historyDeleteFail')))); return; }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('historyDeleteSuccess'))));
    Navigator.pop(context, true);
  }

  Widget _buildDeleteButton(bool isDark) => SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _confirmDeleteHistory, icon: const Icon(Icons.delete_outline_rounded, size: 18), label: Text(context.tr('historyDeleteThis'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), style: OutlinedButton.styleFrom(foregroundColor: isDark ? AppColors.darkDestructive : AppColors.destructive, side: BorderSide(color: (isDark ? AppColors.darkDestructive : AppColors.destructive).withValues(alpha: 0.35)), backgroundColor: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.9), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))));
  Widget _buildRecommendationCard(Color color, String recommendation, bool isDark) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withBlue(100)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]), child: Row(children: [const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 28), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('resultRecommendation'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)), const SizedBox(height: 4), Text(recommendation, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white, height: 1.4))]))]));
  Widget _buildScatteredAuras(double sw, double sh, Color color, bool isDark) => Stack(children: [Positioned(top: -sh * 0.1, right: -sw * 0.2, child: _buildAura(160, color.withValues(alpha: 0.1))), Positioned(bottom: sh * 0.1, left: -sw * 0.3, child: _buildAura(200, color.withValues(alpha: 0.05)))]);
  Widget _buildAura(double size, Color color) => Container(width: size * 2, height: size * 2, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2)]));
}
