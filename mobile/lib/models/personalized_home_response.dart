import 'home_card.dart';

class PersonalizedHomeResponse {
  final String persona;
  final String? greeting;
  final String? summaryInsight;
  final String? generatedAt;
  final String? locationName;
  final bool degradedContext;
  final String ranker;
  final Map<String, dynamic>? baselineDelta;
  final List<RankedHomeCard> cards;

  const PersonalizedHomeResponse({
    required this.persona,
    this.greeting,
    this.summaryInsight,
    this.generatedAt,
    this.locationName,
    this.degradedContext = false,
    this.ranker = 'rules',
    this.baselineDelta,
    this.cards = const [],
  });

  factory PersonalizedHomeResponse.fromJson(Map<String, dynamic> json) {
    List<RankedHomeCard> cardList = [];
    if (json['cards'] is List) {
      cardList = (json['cards'] as List)
          .whereType<Map<String, dynamic>>()
          .map((cardJson) => RankedHomeCard.fromJson(cardJson))
          .toList();

      // Ensure sorted by API rank (score DESC, rank ASC)
      cardList.sort((a, b) {
        final rankCompare = a.rank.compareTo(b.rank);
        if (rankCompare != 0) return rankCompare;
        return b.score.compareTo(a.score);
      });
    }

    String? locName;
    if (json['location'] is String) {
      locName = json['location'] as String;
    } else if (json['location'] is Map<String, dynamic>) {
      locName = (json['location'] as Map<String, dynamic>)['name'] as String?;
    }

    Map<String, dynamic>? deltaMap;
    if (json['baseline_delta'] is Map<String, dynamic>) {
      deltaMap = json['baseline_delta'] as Map<String, dynamic>;
    }

    return PersonalizedHomeResponse(
      persona: (json['persona'] ?? 'Fitness').toString(),
      greeting: json['greeting'] as String?,
      summaryInsight: (json['summary_insight'] ?? json['summary']) as String?,
      generatedAt: json['generated_at'] as String?,
      locationName: locName,
      degradedContext: (json['degraded_context'] as bool?) ?? false,
      ranker: (json['ranker'] ?? 'rules').toString(),
      baselineDelta: deltaMap,
      cards: cardList,
    );
  }
}
