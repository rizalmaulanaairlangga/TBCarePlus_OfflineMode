import 'package:flutter/material.dart';
import '../../../core/services/local_assessment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_header.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../routes/app_routes.dart';
import '../../../core/l10n/l10n.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _historyItems = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await LocalAssessmentService.fetchHistorySessions();
      if (!mounted) return;
      setState(() {
        _historyItems = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: Text(context.tr('historyDeleteAllTitle')),
          content: Text(context.tr('historyDeleteAllContent')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: isDark ? AppColors.darkDestructive : AppColors.destructive), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
          ],
        );
      },
    );
    if (confirmed == true) {
      await LocalAssessmentService.clearHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('historyDeleteAllSuccess'))));
      await _fetchHistory();
    }
  }

  String _translateAssessmentType(String? dbValue) {
    if (dbValue == null) return context.tr('historyDetailType');
    switch (dbValue.toLowerCase()) {
      case 'quick assessment':
      case 'quick check':
        return context.tr('homeQuickCheck');
      case 'full assessment':
      case 'pemeriksaan lengkap':
        return context.tr('homeFullCheck');
      default:
        return dbValue;
    }
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
                const ResponsiveCenter(maxWidth: 720, child: HomeHeader(isGuest: false)),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchHistory,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ResponsiveCenter(
                        maxWidth: 720,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('historyTitle'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkForeground : AppColors.foreground, letterSpacing: -0.8)),
                            Text(context.tr('historySubtitle'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkPrimary : AppColors.primary)),
                            const SizedBox(height: 18),
                            _loading
                                ? const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()))
                                : _error != null
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 40),
                                          child: Column(
                                            children: [
                                              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.darkDestructive : AppColors.destructive)),
                                              const SizedBox(height: 12),
                                              ElevatedButton(onPressed: _fetchHistory, child: Text('Coba Lagi')),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _historyItems.isEmpty
                                        ? _buildEmptyState(isDark)
                                        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildDeleteAllBar(isDark), const SizedBox(height: 14), _buildTimelineList(isDark)]),
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
        currentIndex: 1,
        onTap: (i) {
          final routes = [AppRoutes.home, AppRoutes.history, AppRoutes.profile];
          if (i < routes.length) Navigator.pushNamedAndRemoveUntil(context, routes[i], (route) => false);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 64, color: (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(context.tr('historyEmptyTitle'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: muted)),
            const SizedBox(height: 6),
            Text(context.tr('historyEmptySubtitle'), style: TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAllBar(bool isDark) {
    final destructive = isDark ? AppColors.darkDestructive : AppColors.destructive;
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _confirmClearAll,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(100), border: Border.all(color: destructive.withValues(alpha: 0.25)), boxShadow: [BoxShadow(color: destructive.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_sweep_rounded, size: 16, color: destructive), const SizedBox(width: 6), Text(context.tr('historyDeleteAll'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: destructive, letterSpacing: -0.2))]),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineList(bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        final raw = _historyItems[index];
        DateTime createdAt;
        try {
          createdAt = DateTime.parse(raw['createdAt']);
        } catch (_) {
          createdAt = DateTime.now();
        }
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        final dateStr = '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
        final riskLevelCode = (raw['riskLevelCode'] ?? 'LOW').toString().toUpperCase();
        Color color = isDark ? AppColors.darkPrimary : AppColors.primary;
        IconData icon = Icons.check_circle_outline_rounded;
        String riskTitle = (raw['riskLevelTitle'] ?? 'Low Risk').toString();
        if (riskLevelCode.contains('HIGH')) {
          color = isDark ? AppColors.darkDestructive : const Color(0xFFEF4444);
          icon = Icons.error_outline_rounded;
        } else if (riskLevelCode.contains('MEDIUM') || riskLevelCode.contains('MODERATE')) {
          color = isDark ? AppColors.darkWarning : const Color(0xFFF59E0B);
          icon = Icons.warning_amber_rounded;
        } else {
          color = isDark ? AppColors.darkPrimary : const Color(0xFF10B981);
          icon = Icons.check_circle_outline_rounded;
        }
        final assessmentType = _translateAssessmentType(raw['assessmentTypeName'] as String?);
        final tbType = (raw['primaryTbTypeName'] ?? '').toString();
        final percentage = '${(raw['totalScore'] as num).round()}%';
        final item = {'sessionKey': raw['sessionKey'], 'date': dateStr, 'riskLevel': riskTitle, 'riskLevelCode': riskLevelCode, 'percentage': percentage, 'tbType': tbType, 'type': assessmentType, 'color': color, 'icon': icon};
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 2), boxShadow: [BoxShadow(color: (item['color'] as Color).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))])), Expanded(child: Container(width: 2, color: (item['color'] as Color).withValues(alpha: 0.2)))]),
              const SizedBox(width: 14),
              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: GestureDetector(onTap: () async { final result = await Navigator.pushNamed(context, AppRoutes.historyDetail, arguments: item); if (result == true && mounted) await _fetchHistory(); }, child: _buildHistoryCard(item, isDark)))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, bool isDark) {
    final color = item['color'] as Color;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: isDark ? 1.0 : 0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.calendar_today_rounded, size: 11, color: mutedFg.withValues(alpha: 0.7)), const SizedBox(width: 6), Text(item['date'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedFg))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)), child: Text(item['type'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['riskLevel'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.1)), const SizedBox(height: 4), Row(children: [Text(item['percentage'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.8))), if ((item['tbType'] as String).isNotEmpty) ...[const SizedBox(width: 6), Text('• ${item['tbType']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.6)))]])] )), Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(item['icon'] as IconData, color: color, size: 20))]),
        ],
      ),
    );
  }

  Widget _buildScatteredAuras(double sw, double sh, bool isDark) {
    return Stack(children: [Positioned(top: -sh * 0.05, right: -sw * 0.1, child: _buildAura(150, (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1))), Positioned(top: sh * 0.4, left: -sw * 0.2, child: _buildAura(130, (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(alpha: 0.05))), Positioned(bottom: sh * 0.1, right: -sw * 0.1, child: _buildAura(110, (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.05)))]);
  }

  Widget _buildAura(double size, Color color) => Container(width: size * 2, height: size * 2, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2)]));
}
