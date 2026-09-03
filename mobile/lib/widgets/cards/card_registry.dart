import 'package:flutter/material.dart';

import '../../models/home_card.dart';
import 'activity_window_card_widget.dart';
import 'alerts_card_widget.dart';
import 'aqi_card_widget.dart';
import 'destination_card_widget.dart';
import 'fallback_card_widget.dart';
import 'heat_card_widget.dart';
import 'packing_card_widget.dart';
import 'rain_card_widget.dart';
import 'ranked_card_shell.dart';
import 'uv_card_widget.dart';
import 'weather_card_widget.dart';
import 'wind_card_widget.dart';

class CardRegistry {
  static Widget buildCardWidget({
    required RankedHomeCard card,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    bool showRankBadge = true,
  }) {
    final Widget content = _getCardContent(card);

    return RankedCardShell(
      card: card,
      onTap: onTap,
      onDismiss: onDismiss,
      showRankBadge: showRankBadge,
      child: content,
    );
  }

  static Widget _getCardContent(RankedHomeCard card) {
    switch (card.cardType.toLowerCase()) {
      case 'weather':
        return WeatherCardWidget(card: card);
      case 'aqi':
        return AqiCardWidget(card: card);
      case 'heat':
        return HeatCardWidget(card: card);
      case 'uv':
        return UvCardWidget(card: card);
      case 'wind':
        return WindCardWidget(card: card);
      case 'rain':
        return RainCardWidget(card: card);
      case 'activity_window':
        return ActivityWindowCardWidget(card: card);
      case 'destination':
        return DestinationCardWidget(card: card);
      case 'packing':
      case 'packing_tips':
        return PackingCardWidget(card: card);
      case 'alerts':
        return AlertsCardWidget(card: card);
      case 'health_caution':
      case 'travel_suitability':
        return FallbackCardWidget(card: card);
      default:
        return FallbackCardWidget(card: card);
    }
  }
}
