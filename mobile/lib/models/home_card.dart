class RankedHomeCard {
  final String id;
  final String cardType;
  final double score;
  final int rank;
  final List<String> reasonCodes;
  final String? reason;
  final String? humanReadableReason;
  final String? title;
  final String? subtitle;
  final String? category;
  final String? actionLabel;
  final Map<String, dynamic>? data;

  const RankedHomeCard({
    required this.id,
    required this.cardType,
    required this.score,
    required this.rank,
    this.reasonCodes = const [],
    this.reason,
    this.humanReadableReason,
    this.title,
    this.subtitle,
    this.category,
    this.actionLabel,
    this.data,
  });

  String get effectiveReason =>
      (humanReadableReason != null && humanReadableReason!.isNotEmpty)
          ? humanReadableReason!
          : (reason ?? '');

  factory RankedHomeCard.fromJson(Map<String, dynamic> json) {
    final rawType = (json['card_type'] ?? json['type'] ?? 'fallback').toString();

    List<String> codes = [];
    if (json['reason_codes'] is List) {
      codes = (json['reason_codes'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return RankedHomeCard(
      id: (json['id'] ?? json['card_id'] ?? rawType).toString(),
      cardType: rawType,
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : 0.0,
      rank: (json['rank'] is num) ? (json['rank'] as num).toInt() : 99,
      reasonCodes: codes,
      reason: json['reason'] as String?,
      humanReadableReason: (json['human_readable_reason'] ?? json['human_reason']) as String?,
      title: json['title'] as String?,
      subtitle: (json['subtitle'] ?? json['summary']) as String?,
      category: json['category'] as String?,
      actionLabel: (json['action_label'] ?? json['action_title']) as String?,
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_type': cardType,
      'score': score,
      'rank': rank,
      'reason_codes': reasonCodes,
      'reason': reason,
      'human_readable_reason': humanReadableReason,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'action_label': actionLabel,
      'data': data,
    };
  }
}
