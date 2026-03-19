class RiskClause {
  const RiskClause({
    required this.title,
    required this.summary,
    required this.severity,
  });

  final String title;
  final String summary;
  final String severity; // Low/Medium/High

  factory RiskClause.fromJson(Map<String, dynamic> json) {
    return RiskClause(
      title: (json['title'] ?? json['clause'] ?? 'Clause').toString(),
      summary: (json['summary'] ?? json['details'] ?? '').toString(),
      severity: (json['severity'] ?? json['risk'] ?? 'Medium').toString(),
    );
  }
}

