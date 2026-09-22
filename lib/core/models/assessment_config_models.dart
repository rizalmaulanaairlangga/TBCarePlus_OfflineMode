import 'dart:convert';
import '../l10n/app_strings.dart';
import '../l10n/tb_content_l10n.dart';

class QuickCheckConfig {
  final List<QuickCheckQuestion> questions;
  final List<RiskLevelConfig> riskLevels;
  final String scoringMethod;
  final double saturationK;

  const QuickCheckConfig({
    required this.questions,
    required this.riskLevels,
    this.scoringMethod = 'soft_saturation_cf',
    this.saturationK = 0.35,
  });

  factory QuickCheckConfig.fromJson(Map<String, dynamic> json) {
    return QuickCheckConfig(
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map(
                (q) => QuickCheckQuestion.fromJson(q as Map<String, dynamic>),
              )
              .toList() ??
          [],
      riskLevels:
          (json['riskLevels'] as List<dynamic>?)
              ?.map((r) => RiskLevelConfig.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      scoringMethod: json['scoringMethod'] as String? ?? 'soft_saturation_cf',
      saturationK: (json['saturationK'] as num?)?.toDouble() ?? 0.35,
    );
  }

  Map<String, dynamic> toJson() => {
    'questions': questions.map((q) => q.toJson()).toList(),
    'riskLevels': riskLevels.map((r) => r.toJson()).toList(),
    'scoringMethod': scoringMethod,
    'saturationK': saturationK,
  };

  String toJsonString() => jsonEncode(toJson());

  static QuickCheckConfig fromJsonString(String s) =>
      QuickCheckConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Finds the risk band for a score within a TB type. Mirrors the backend's
  /// `FindMatchedRiskLevel`: if the score falls outside every band, clamp to the
  /// lowest band (below range) or highest band (above range) instead of
  /// returning null, so a result always resolves to a level.
  RiskLevelConfig? findRiskLevel(double totalScore, int tbTypeId) {
    final levels =
        riskLevels.where((r) => r.tbTypeId == tbTypeId).toList()
          ..sort((a, b) => a.minScore.compareTo(b.minScore));
    if (levels.isEmpty) return null;
    for (final r in levels) {
      if (totalScore >= r.minScore && totalScore <= r.maxScore) return r;
    }
    return totalScore < levels.first.minScore ? levels.first : levels.last;
  }
}

class TbTypeWeight {
  final int tbTypeId;
  final String tbTypeName;
  final double weight;

  const TbTypeWeight({
    required this.tbTypeId,
    required this.tbTypeName,
    required this.weight,
  });

  factory TbTypeWeight.fromJson(Map<String, dynamic> json) {
    return TbTypeWeight(
      tbTypeId: (json['tbTypeId'] as num).toInt(),
      tbTypeName: json['tbTypeName'] as String? ?? '',
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tbTypeId': tbTypeId,
    'tbTypeName': tbTypeName,
    'weight': weight,
  };

  String localizedName(AppLocale locale) => TbContentL10n.tbType(tbTypeName, locale);
}

class QuickCheckQuestion {
  final int questionId;
  final int symptomId;
  final String symptomCode;
  final String symptomName;
  final String? symptomDescription;
  final String questionText;
  final int sortOrder;
  final bool isRequired;
  final double weight;
  final int tbTypeId;
  final String? tbTypeName;
  final List<TbTypeWeight> applicableTbTypes;

  const QuickCheckQuestion({
    required this.questionId,
    required this.symptomId,
    required this.symptomCode,
    required this.symptomName,
    this.symptomDescription,
    required this.questionText,
    required this.sortOrder,
    this.isRequired = true,
    required this.weight,
    required this.tbTypeId,
    this.tbTypeName,
    this.applicableTbTypes = const [],
  });

  bool get isGeneral {
    if (!symptomCode.startsWith('G')) return false;
    final digits = symptomCode.replaceAll(RegExp(r'[^0-9]'), '');
    final numPart = int.tryParse(digits);
    if (numPart == null) return false;
    return numPart >= 1 &&
        numPart <= 8 &&
        !symptomCode.contains(RegExp(r'[a-z]'));
  }

  String localizedSymptomName(AppLocale locale) => TbContentL10n.symptomName(symptomName, locale);
  String localizedSymptomDescription(AppLocale locale) => TbContentL10n.symptomDesc(symptomDescription, locale);
  String localizedQuestionText(AppLocale locale) => TbContentL10n.questionText(questionText, locale);
  String localizedTbTypeName(AppLocale locale) => tbTypeName == null ? '' : TbContentL10n.tbType(tbTypeName!, locale);

  factory QuickCheckQuestion.fromJson(Map<String, dynamic> json) {
    return QuickCheckQuestion(
      questionId: (json['questionId'] as num).toInt(),
      symptomId: (json['symptomId'] as num).toInt(),
      symptomCode: json['symptomCode'] as String? ?? '',
      symptomName: json['symptomName'] as String? ?? '',
      symptomDescription: json['symptomDescription'] as String?,
      questionText: json['questionText'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isRequired: json['isRequired'] as bool? ?? true,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      tbTypeId: (json['tbTypeId'] as num?)?.toInt() ?? 0,
      tbTypeName: json['tbTypeName'] as String?,
      applicableTbTypes:
          (json['applicableTbTypes'] as List<dynamic>?)
              ?.map((e) => TbTypeWeight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'symptomId': symptomId,
    'symptomCode': symptomCode,
    'symptomName': symptomName,
    'symptomDescription': symptomDescription,
    'questionText': questionText,
    'sortOrder': sortOrder,
    'isRequired': isRequired,
    'weight': weight,
    'tbTypeId': tbTypeId,
    'tbTypeName': tbTypeName,
    'applicableTbTypes': applicableTbTypes.map((e) => e.toJson()).toList(),
  };
}

class RiskLevelConfig {
  final int id;
  final int tbTypeId;
  final String code;
  final String title;
  final double minScore;
  final double maxScore;
  final String? description;
  final String? recommendation;

  const RiskLevelConfig({
    required this.id,
    required this.tbTypeId,
    required this.code,
    required this.title,
    required this.minScore,
    required this.maxScore,
    this.description,
    this.recommendation,
  });

  factory RiskLevelConfig.fromJson(Map<String, dynamic> json) {
    return RiskLevelConfig(
      id: (json['id'] as num).toInt(),
      tbTypeId: (json['tbTypeId'] as num).toInt(),
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      minScore: (json['minScore'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      description: json['description'] as String?,
      recommendation: json['recommendation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tbTypeId': tbTypeId,
    'code': code,
    'title': title,
    'minScore': minScore,
    'maxScore': maxScore,
    'description': description,
    'recommendation': recommendation,
  };

  String localizedTitle(AppLocale locale) => TbContentL10n.riskTitle(title, locale);
  String localizedDescription(AppLocale locale) => TbContentL10n.riskDesc(description, locale);
  String localizedRecommendation(AppLocale locale) => TbContentL10n.riskReco(recommendation, locale);
}
