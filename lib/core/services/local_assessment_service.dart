import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../db/hive_init.dart';
import '../models/assessment_config_models.dart';

class LocalAssessmentService {
  static const String _quickAsset = 'assets/config/quick_check_config.json';
  static const String _fullAsset = 'assets/config/full_assessment_config.json';

  // ── Config ─────────────────────────────────────────────────────────
  static QuickCheckConfig? _quickCache;
  static QuickCheckConfig? _fullCache;

  static Future<QuickCheckConfig> getQuickCheckConfig() async {
    if (_quickCache != null) return _quickCache!;
    final raw = await rootBundle.loadString(_quickAsset);
    _quickCache = QuickCheckConfig.fromJsonString(raw);
    return _quickCache!;
  }

  static Future<QuickCheckConfig> getFullAssessmentConfig() async {
    if (_fullCache != null) return _fullCache!;
    final raw = await rootBundle.loadString(_fullAsset);
    _fullCache = QuickCheckConfig.fromJsonString(raw);
    return _fullCache!;
  }

  // Keep compatibility with old AssessmentApiService names
  static Future<QuickCheckConfig> fetchQuickCheckConfig() => getQuickCheckConfig();
  static Future<QuickCheckConfig> fetchFullAssessmentConfig() => getFullAssessmentConfig();

  // ── Helpers (mirror AssessmentController.cs) ───────────────────────
  static String _getBaseCode(String code) {
    var c = code;
    while (c.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(c[c.length - 1])) {
      c = c.substring(0, c.length - 1);
    }
    return c;
  }

  static bool _isVariantCode(String code) {
    if (code.isEmpty) return false;
    return RegExp(r'[A-Za-z]').hasMatch(code[code.length - 1]);
  }

  static int _riskRank(String? code) {
    final c = (code ?? '').toUpperCase();
    if (c.contains('HIGH')) return 3;
    if (c.contains('MEDIUM') || c.contains('MODERATE')) return 2;
    return 1;
  }

  static String _encodeSessionKey(int assessmentTypeId, DateTime createdAtUtc) {
    final raw = '$assessmentTypeId|${createdAtUtc.toIso8601String()}';
    final bytes = utf8.encode(raw);
    // base64Url without padding, like WebEncoders.Base64UrlEncode
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static bool _tryDecodeSessionKey(String sessionKey, List out) {
    // out[0]=assessmentTypeId int, out[1]=DateTime
    try {
      var padded = sessionKey;
      final mod = padded.length % 4;
      if (mod != 0) padded += '=' * (4 - mod);
      final raw = utf8.decode(base64Url.decode(padded));
      final parts = raw.split('|');
      if (parts.length != 2) return false;
      final typeId = int.parse(parts[0]);
      final dt = DateTime.parse(parts[1]).toUtc();
      out[0] = typeId;
      out[1] = dt;
      return true;
    } catch (_) {
      return false;
    }
  }

  static DateTime _roundToSecondUtc(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  }

  // ── Submit ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> submitAssessment({
    required int assessmentTypeId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final isQuick = assessmentTypeId == 1;
    final config = isQuick ? await getQuickCheckConfig() : await getFullAssessmentConfig();
    final k = config.saturationK <= 0 ? 0.35 : config.saturationK;

    // question lookup not needed separately

    // answerByQuestionId: questionId -> cfValue (1.0 if selected, 0.0 else)
    // For offline, answers may contain all questions with cfValue, or only selected.
    // Normalize: if answer cfValue >0 => selected
    final answerByQuestionId = <int, double>{};
    for (final a in answers) {
      final qid = (a['questionId'] as num).toInt();
      final cf = (a['cfValue'] as num?)?.toDouble() ?? 0.0;
      answerByQuestionId[qid] = cf;
    }
    // If answers only contains selected (cf 1.0) and misses unselected, fill 0 for remaining
    for (final q in config.questions) {
      answerByQuestionId.putIfAbsent(q.questionId, () => 0.0);
    }

    // Build variantMap: baseCode -> List<(symptomId, tbTypeId)>
    // For offline we use questions' applicableTbTypes + tbTypeId
    final variantMap = <String, List<({int symptomId, int tbTypeId})>>{};
    for (final q in config.questions) {
      final base = _getBaseCode(q.symptomCode);
      variantMap.putIfAbsent(base, () => []);
      // Add this question's own tbType
      variantMap[base]!.add((symptomId: q.symptomId, tbTypeId: q.tbTypeId));
      // Also add its applicableTbTypes entries (for full assessment they expand)
      for (final tw in q.applicableTbTypes) {
        if (!variantMap[base]!.any((e) => e.symptomId == q.symptomId && e.tbTypeId == tw.tbTypeId)) {
          // For full assessment, applicableTbTypes already includes variant symptomIds mapping
          // But we need to handle generic G01 -> G01a etc mapping via weight
        }
      }
    }
    // For full assessment, variant expansion needs weight per (symptomId, tbTypeId)
    // Build weight lookup: (symptomId, tbTypeId) -> weight
    // For quick, weight is q.weight directly; for full, use applicableTbTypes weight or fallback
    final weightBySymptomAndTb = <String, double>{};
    String wKey(int sid, int tid) => '$sid|$tid';
    for (final q in config.questions) {
      weightBySymptomAndTb[wKey(q.symptomId, q.tbTypeId)] = q.weight;
      for (final tw in q.applicableTbTypes) {
        // applicableTbTypes weight is for this symptom's contribution to that tbType
        // But for full, the variant's own question holds the correct weight for its tbType
        // We still store it for fan-out
        weightBySymptomAndTb.putIfAbsent(wKey(q.symptomId, tw.tbTypeId), () => tw.weight);
        // Also need weight for variant symptomIds: we expand later via baseCode
      }
    }
    // Full assessment: need to fan-out selected symptom to all variant tbTypes
    // Build baseCode -> list of (symptomId, tbTypeId, weight)
    final baseVariantWeights = <String, List<({int symptomId, int tbTypeId, double weight})>>{};
    for (final q in config.questions) {
      final base = _getBaseCode(q.symptomCode);
      baseVariantWeights.putIfAbsent(base, () => []);
      // For each applicableTbType, register its weight for that base
      if (q.applicableTbTypes.isNotEmpty) {
        for (final tw in q.applicableTbTypes) {
          if (!baseVariantWeights[base]!.any((e) => e.symptomId == q.symptomId && e.tbTypeId == tw.tbTypeId)) {
            baseVariantWeights[base]!.add((symptomId: q.symptomId, tbTypeId: tw.tbTypeId, weight: tw.weight));
          }
        }
      } else {
        baseVariantWeights[base]!.add((symptomId: q.symptomId, tbTypeId: q.tbTypeId, weight: q.weight));
      }
    }
    // Also ensure cross-variant: for base G01, we need entries for G01a/b/c symptomIds
    // The above loop already added each variant's own weight via its question.
    // For fan-out we need: when G01 is selected, contribute to all tbTypes using respective variant weights
    // So baseVariantWeights['G01'] should contain 4 entries (G01->1, G01a->2, G01b->3, G01c->4)
    // Our loop does that because each variant question has symptomCode G01a etc but base is G01.

    // tbType names
    final tbTypeNames = <int, String>{};
    for (final q in config.questions) {
      tbTypeNames[q.tbTypeId] = q.tbTypeName ?? 'Kategori ${q.tbTypeId}';
      for (final tw in q.applicableTbTypes) {
        tbTypeNames[tw.tbTypeId] = tw.tbTypeName;
      }
    }

    // Selected symptoms list for history (mirror backend)
    final selectedSymptoms = <Map<String, dynamic>>[];
    final sumByTbType = <int, double>{};

    for (final q in config.questions) {
      final cfValue = answerByQuestionId[q.questionId] ?? 0.0;
      final isSelected = cfValue > 0;
      // Build selectedSymptoms entry (always, with cfValue)
      selectedSymptoms.add({
        'questionId': q.questionId,
        'symptomId': q.symptomId,
        'symptomCode': q.symptomCode,
        'symptomName': q.symptomName,
        'symptomDescription': q.symptomDescription,
        'tbTypeId': q.tbTypeId,
        'tbTypeName': q.tbTypeName,
        'cfValue': cfValue,
        'weight': q.weight,
      });

      if (!isSelected) continue;

      final base = _getBaseCode(q.symptomCode);
      final variants = baseVariantWeights[base];
      if (variants != null && variants.isNotEmpty) {
        for (final v in variants) {
          final key = wKey(v.symptomId, v.tbTypeId);
          final w = weightBySymptomAndTb[key] ?? v.weight;
          final contrib = w * cfValue;
          sumByTbType[v.tbTypeId] = (sumByTbType[v.tbTypeId] ?? 0) + contrib;
        }
      } else {
        // fallback single
        final contrib = q.weight * cfValue;
        sumByTbType[q.tbTypeId] = (sumByTbType[q.tbTypeId] ?? 0) + contrib;
      }
    }

    // totalWeight for quick
    final totalWeightByTbType = <int, double>{};
    if (isQuick) {
      for (final q in config.questions) {
        totalWeightByTbType[q.tbTypeId] = (totalWeightByTbType[q.tbTypeId] ?? 0) + q.weight;
      }
    }

    // All tbTypeIds
    final allTbTypeIds = tbTypeNames.keys.toList();

    RiskLevelConfig? findMatched(int tbTypeId, double score) {
      return config.findRiskLevel(score, tbTypeId);
    }

    final breakdown = <Map<String, dynamic>>[];
    final perTbResults = <Map<String, dynamic>>[];

    for (final tbTypeId in allTbTypeIds) {
      final sum = sumByTbType[tbTypeId] ?? 0;
      double combinedCF;
      double score;
      if (isQuick) {
        final totalW = totalWeightByTbType[tbTypeId] ?? 0;
        if (totalW <= 0) {
          combinedCF = 0;
          score = 0;
        } else {
          combinedCF = sum / totalW;
          score = (combinedCF * 100).roundToDouble();
        }
      } else {
        combinedCF = 1.0 - exp(-k * sum);
        score = (combinedCF * 100).roundToDouble();
      }
      final matched = findMatched(tbTypeId, score);
      final payload = {
        'tbTypeId': tbTypeId,
        'tbTypeName': tbTypeNames[tbTypeId] ?? 'Kategori $tbTypeId',
        'combinedCF': combinedCF,
        'totalScore': score,
        'riskLevel': matched != null
            ? {
                'id': matched.id,
                'code': matched.code,
                'title': matched.title,
                'minScore': matched.minScore,
                'maxScore': matched.maxScore,
                'description': matched.description ?? '',
                'recommendation': matched.recommendation ?? '',
              }
            : {'id': 0, 'code': 'LOW', 'title': 'Low Risk', 'minScore': 0.0, 'maxScore': 100.0, 'description': '', 'recommendation': ''},
      };
      breakdown.add(payload);
      perTbResults.add(payload);
    }

    final submissionAt = DateTime.now().toUtc();
    final box = HiveInit.historiesBox;
    final historyIds = <int>[];

    if (isQuick) {
      // Single record best
      perTbResults.sort((a, b) {
        final ra = _riskRank((a['riskLevel'] as Map)['code'] as String?);
        final rb = _riskRank((b['riskLevel'] as Map)['code'] as String?);
        if (ra != rb) return rb.compareTo(ra);
        return (b['totalScore'] as num).compareTo(a['totalScore'] as num);
      });
      final best = perTbResults.first;
      final rl = best['riskLevel'] as Map;
      final nextId = box.isEmpty ? 1 : (box.keys.cast<int>().reduce((a, b) => a > b ? a : b) + 1);
      final record = {
        'id': nextId,
        'assessmentTypeId': assessmentTypeId,
        'primaryTbTypeId': best['tbTypeId'],
        'primaryTbTypeName': best['tbTypeName'],
        'riskLevelId': rl['id'],
        'riskLevelCode': rl['code'],
        'riskLevelTitle': rl['title'],
        'totalScore': best['totalScore'],
        'selectedSymptoms': selectedSymptoms,
        'scoreBreakdown': {'results': breakdown},
        'createdAt': submissionAt.toIso8601String(),
        'assessmentTypeName': 'Quick Assessment',
      };
      await box.put(nextId, record);
      historyIds.add(nextId);
    } else {
      // Full: one per tbType, shared symptoms filtered per tbType
      // symptomTbTypes: symptomId of base non-variant -> set of tbTypeIds it contributes to
      final symptomTbTypes = <int, Set<int>>{};
      for (final entry in baseVariantWeights.entries) {
        final allTids = entry.value.map((e) => e.tbTypeId).toSet();
        for (final v in entry.value) {
          if (!_isVariantCode(config.questions.firstWhere((q) => q.symptomId == v.symptomId, orElse: () => config.questions.first).symptomCode)) {
            symptomTbTypes[v.symptomId] = allTids;
          }
        }
      }
      int nextIdBase = box.isEmpty ? 1 : (box.keys.cast<int>().reduce((a, b) => a > b ? a : b) + 1);
      int idx = 0;
      for (final payload in perTbResults) {
        final tbTypeId = payload['tbTypeId'] as int;
        final rl = payload['riskLevel'] as Map;
        // Filter selectedSymptoms per tbType
        final filtered = selectedSymptoms.where((s) {
          final tid = s['tbTypeId'] as int;
          if (tid == tbTypeId) return true;
          final sid = s['symptomId'] as int;
          final set = symptomTbTypes[sid];
          if (set != null && set.contains(tbTypeId)) return true;
          return false;
        }).toList();
        final id = nextIdBase + idx;
        final record = {
          'id': id,
          'assessmentTypeId': assessmentTypeId,
          'primaryTbTypeId': tbTypeId,
          'primaryTbTypeName': payload['tbTypeName'],
          'riskLevelId': rl['id'],
          'riskLevelCode': rl['code'],
          'riskLevelTitle': rl['title'],
          'totalScore': payload['totalScore'],
          'selectedSymptoms': filtered,
          'scoreBreakdown': {'results': [payload]},
          'createdAt': submissionAt.toIso8601String(),
          'assessmentTypeName': 'Full Assessment',
        };
        await box.put(id, record);
        historyIds.add(id);
        idx++;
      }
    }

    // Return last: mimic backend historyIds
    return {'historyIds': historyIds};
  }

  // ── History ────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchHistorySessions() async {
    final box = HiveInit.historiesBox;
    if (box.isEmpty) return [];
    final all = box.values.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    // Group by assessmentTypeId + rounded second
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final h in all) {
      final typeId = h['assessmentTypeId'] as int;
      final createdAt = DateTime.parse(h['createdAt'] as String);
      final rounded = _roundToSecondUtc(createdAt);
      final key = '$typeId|${rounded.toIso8601String()}';
      groups.putIfAbsent(key, () => []).add(h);
    }

    final sessions = <Map<String, dynamic>>[];
    for (final entry in groups.entries) {
      final g = entry.value;
      // best per group
      g.sort((a, b) {
        final ra = _riskRank(a['riskLevelCode'] as String?);
        final rb = _riskRank(b['riskLevelCode'] as String?);
        if (ra != rb) return rb.compareTo(ra);
        return (b['totalScore'] as num).compareTo(a['totalScore'] as num);
      });
      final best = g.first;
      final parts = entry.key.split('|');
      final typeId = int.parse(parts[0]);
      final rounded = DateTime.parse(parts[1]);
      final sessionKey = _encodeSessionKey(typeId, rounded);
      sessions.add({
        'sessionKey': sessionKey,
        'createdAt': rounded.toIso8601String(),
        'assessmentTypeId': typeId,
        'assessmentTypeName': best['assessmentTypeName'] ?? (typeId == 1 ? 'Quick Assessment' : 'Full Assessment'),
        'riskLevelId': best['riskLevelId'],
        'riskLevelTitle': best['riskLevelTitle'],
        'riskLevelCode': best['riskLevelCode'],
        'primaryTbTypeId': best['primaryTbTypeId'],
        'primaryTbTypeName': best['primaryTbTypeName'],
        'totalScore': best['totalScore'],
        'historyIds': g.map((e) => e['id']).toList(),
      });
    }
    sessions.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return sessions;
  }

  static Future<Map<String, dynamic>?> fetchHistorySessionDetail(String sessionKey) async {
    final out = <dynamic>[null, null];
    if (!_tryDecodeSessionKey(sessionKey, out)) return null;
    final typeId = out[0] as int;
    final createdAtUtc = out[1] as DateTime;
    final rounded = _roundToSecondUtc(createdAtUtc);
    final next = rounded.add(const Duration(seconds: 1));

    final box = HiveInit.historiesBox;
    final items = box.values
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((h) {
          if (h['assessmentTypeId'] != typeId) return false;
          final dt = DateTime.parse(h['createdAt'] as String).toUtc();
          return !dt.isBefore(rounded) && dt.isBefore(next);
        })
        .toList();
    if (items.isEmpty) return null;
    items.sort((a, b) => (a['primaryTbTypeId'] as int).compareTo(b['primaryTbTypeId'] as int));
    final displayItems = items.map((h) {
      return {
        'id': h['id'],
        'assessmentTypeId': h['assessmentTypeId'],
        'assessmentTypeName': h['assessmentTypeName'],
        'primaryTbTypeId': h['primaryTbTypeId'],
        'primaryTbTypeName': h['primaryTbTypeName'],
        'riskLevelId': h['riskLevelId'],
        'riskLevelTitle': h['riskLevelTitle'],
        'riskLevelCode': h['riskLevelCode'],
        'totalScore': h['totalScore'],
        'createdAt': h['createdAt'],
        'selectedSymptoms': h['selectedSymptoms'],
        'scoreBreakdown': h['scoreBreakdown'],
      };
    }).toList();
    return {
      'sessionKey': sessionKey,
      'createdAt': rounded.toIso8601String(),
      'assessmentTypeId': typeId,
      'assessmentTypeName': displayItems.first['assessmentTypeName'],
      'items': displayItems,
    };
  }

  static Future<Map<String, dynamic>?> fetchMostRecentAssessment() async {
    final sessions = await fetchHistorySessions();
    if (sessions.isEmpty) return null;
    final mostRecent = sessions.first;
    final detail = await fetchHistorySessionDetail(mostRecent['sessionKey'] as String);
    if (detail == null) return null;
    final items = detail['items'] as List;
    if (items.isEmpty) return null;
    // Pick best
    Map<String, dynamic>? best;
    for (final it in items) {
      final m = Map<String, dynamic>.from(it as Map);
      if (best == null) { best = m; continue; }
      final r1 = _riskRank(m['riskLevelCode'] as String?);
      final r2 = _riskRank(best['riskLevelCode'] as String?);
      final s1 = (m['totalScore'] as num).toDouble();
      final s2 = (best['totalScore'] as num).toDouble();
      if (r1 > r2 || (r1 == r2 && s1 > s2)) best = m;
    }
    final first = best ?? Map<String, dynamic>.from(items.first as Map);
    return {
      'sessionKey': detail['sessionKey'],
      'createdAt': detail['createdAt'],
      'assessmentTypeId': detail['assessmentTypeId'],
      'assessmentTypeName': detail['assessmentTypeName'],
      'riskLevelCode': first['riskLevelCode'] ?? 'LOW',
      'riskLevelTitle': first['riskLevelTitle'] ?? 'Low Risk',
      'totalScore': first['totalScore'] ?? 0,
      'primaryTbTypeId': first['primaryTbTypeId'],
      'primaryTbTypeName': first['primaryTbTypeName'],
      'detailItem': first,
    };
  }

  static Future<bool> hasCompletedFullAssessment() async {
    final sessions = await fetchHistorySessions();
    return sessions.any((s) => (s['assessmentTypeId'] as int) == 2);
  }

  static Future<bool> isMostRecentQuickAssessment() async {
    final sessions = await fetchHistorySessions();
    if (sessions.isEmpty) return false;
    return (sessions.first['assessmentTypeId'] as int) == 1;
  }

  static Future<void> clearHistory() async {
    await HiveInit.historiesBox.clear();
  }

  static Future<bool> deleteHistorySession(String sessionKey) async {
    final out = <dynamic>[null, null];
    if (!_tryDecodeSessionKey(sessionKey, out)) return false;
    final typeId = out[0] as int;
    final createdAtUtc = out[1] as DateTime;
    final rounded = _roundToSecondUtc(createdAtUtc);
    final next = rounded.add(const Duration(seconds: 1));
    final box = HiveInit.historiesBox;
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is! Map) continue;
      final m = Map<String, dynamic>.from(v);
      if (m['assessmentTypeId'] != typeId) continue;
      try {
        final dt = DateTime.parse(m['createdAt'] as String).toUtc();
        if (!dt.isBefore(rounded) && dt.isBefore(next)) {
          keysToDelete.add(key);
        }
      } catch (_) {}
    }
    if (keysToDelete.isEmpty) return false;
    for (final k in keysToDelete) {
      await box.delete(k);
    }
    return true;
  }

  // compat with old fetchHistory etc
  static Future<List<Map<String, dynamic>>> fetchHistory() async {
    final box = HiveInit.historiesBox;
    final list = box.values.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return list;
  }

  static Future<Map<String, dynamic>?> fetchHistoryDetail(int id) async {
    final box = HiveInit.historiesBox;
    final v = box.get(id);
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }
}
