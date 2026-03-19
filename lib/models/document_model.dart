import 'risk_model.dart';

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.fileName,
    required this.language,
  });

  final String id;
  final String fileName;
  final String language;
}

class DocumentAnalysis {
  const DocumentAnalysis({
    required this.safetyScore,
    required this.riskLevel,
    required this.detectedClauses,
    required this.riskAlerts,
    required this.translatedText,
    required this.simplifiedExplanation,
  });

  final double safetyScore; // 0..100
  final String riskLevel; // Low/Medium/High
  final List<RiskClause> detectedClauses;
  final List<String> riskAlerts;
  final String translatedText;
  final String simplifiedExplanation;

  factory DocumentAnalysis.empty() => const DocumentAnalysis(
        safetyScore: 0,
        riskLevel: 'Unknown',
        detectedClauses: [],
        riskAlerts: [],
        translatedText: '',
        simplifiedExplanation: '',
      );

  factory DocumentAnalysis.fromJson(Map<String, dynamic> json) {
    final clauses = (json['clauses'] ?? json['detected_clauses'] ?? []) as List;
    final alerts = (json['alerts'] ?? json['risk_alerts'] ?? []) as List;

    final rawScore = json['score'] ?? json['safety_score'] ?? 0;
    final score = rawScore is num ? rawScore.toDouble() : 0.0;

    return DocumentAnalysis(
      safetyScore: score.clamp(0, 100).toDouble(),
      riskLevel: (json['risk_level'] ?? json['riskLevel'] ?? 'Unknown')
          .toString(),
      detectedClauses: clauses
          .whereType<Map>()
          .map((e) => RiskClause.fromJson(e.cast<String, dynamic>()))
          .toList(),
      riskAlerts: alerts.map((e) => e.toString()).toList(),
      translatedText:
          (json['translated'] ?? json['translated_text'] ?? '').toString(),
      simplifiedExplanation:
          (json['explanation'] ?? json['simplified_explanation'] ?? '')
              .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'safety_score': safetyScore,
        'risk_level': riskLevel,
        'clauses': detectedClauses
            .map(
              (c) => {
                'title': c.title,
                'summary': c.summary,
                'severity': c.severity,
              },
            )
            .toList(),
        'risk_alerts': riskAlerts,
        'translated_text': translatedText,
        'simplified_explanation': simplifiedExplanation,
      };
}
