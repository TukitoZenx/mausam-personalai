import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_card.dart';
import '../models/personalized_home_response.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';

class HomepageState {
  final bool isLoading;
  final bool isStale;
  final String? errorMessage;
  final PersonalizedHomeResponse? data;
  final Set<String> loggedViewCardTypes;

  const HomepageState({
    this.isLoading = false,
    this.isStale = false,
    this.errorMessage,
    this.data,
    this.loggedViewCardTypes = const {},
  });

  HomepageState copyWith({
    bool? isLoading,
    bool? isStale,
    String? errorMessage,
    PersonalizedHomeResponse? data,
    Set<String>? loggedViewCardTypes,
    bool clearError = false,
  }) {
    return HomepageState(
      isLoading: isLoading ?? this.isLoading,
      isStale: isStale ?? this.isStale,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
      loggedViewCardTypes: loggedViewCardTypes ?? this.loggedViewCardTypes,
    );
  }

  /// Composed greeting if API response doesn't provide one
  String get effectiveGreeting {
    if (data?.greeting != null && data!.greeting!.isNotEmpty) {
      return data!.greeting!;
    }
    final hour = DateTime.now().hour;
    final timeStr = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final persona = data?.persona ?? 'Fitness';
    return '$timeStr! Here is your $persona focus.';
  }

  /// Composed summary insight if API response doesn't provide one
  String get effectiveSummaryInsight {
    if (data?.summaryInsight != null && data!.summaryInsight!.isNotEmpty) {
      return data!.summaryInsight!;
    }
    final topCard = data?.cards.firstOrNull;
    if (topCard != null && topCard.effectiveReason.isNotEmpty) {
      return topCard.effectiveReason;
    }
    return 'Conditions are monitored live for optimal daily planning.';
  }
}

class HomepageNotifier extends Notifier<HomepageState> {
  @override
  HomepageState build() {
    // Listen to persona changes from userProvider
    ref.listen(userProvider.select((u) => u.selectedPersona), (prev, next) {
      if (prev != next && next != null) {
        fetchHomeFeed();
      }
    });

    // Listen to active location changes from locationProvider
    ref.listen(
      locationProvider.select((l) => '${l.activeLatitude},${l.activeLongitude},${l.isCustomSelected}'),
      (prev, next) {
        if (prev != next) {
          fetchHomeFeed();
        }
      },
    );

    return const HomepageState();
  }

  Future<void> fetchHomeFeed({bool forceRefresh = false}) async {
    final locationState = ref.read(locationProvider);
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    if (state.data == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      String? savedLocationId;
      if (locationState.isCustomSelected) {
        final activeMatch = locationState.savedLocations.where(
          (loc) =>
              loc.latitude == locationState.activeLatitude &&
              loc.longitude == locationState.activeLongitude,
        );
        if (activeMatch.isNotEmpty) {
          savedLocationId = activeMatch.first.id;
        }
      }

      final response = await apiClient.fetchPersonalizedHome(
        lat: locationState.activeLatitude,
        lon: locationState.activeLongitude,
        savedLocationId: savedLocationId,
        hour: DateTime.now().hour,
        tz: DateTime.now().timeZoneName,
        persona: userState.selectedPersona,
        idToken: idToken,
      );

      // Successfully fetched response
      state = state.copyWith(
        isLoading: false,
        isStale: response.degradedContext,
        data: response,
        clearError: true,
      );

      // Log view events for visible cards asynchronously
      _logCardViews(response.cards, idToken);
    } catch (e) {
      debugPrint('Error fetching homepage feed: $e');
      // PRESERVE last successful data on error so screen never blanks out
      state = state.copyWith(
        isLoading: false,
        isStale: true,
        errorMessage: 'Unable to refresh live insights. ${e.toString()}',
      );
    }
  }

  void _logCardViews(List<RankedHomeCard> cards, String idToken) {
    final apiClient = ref.read(apiClientProvider);
    final updatedLogged = Set<String>.from(state.loggedViewCardTypes);

    for (final card in cards) {
      if (!updatedLogged.contains(card.cardType)) {
        updatedLogged.add(card.cardType);
        apiClient.recordInteraction(
          cardType: card.cardType,
          action: 'view',
          cardId: card.id,
          idToken: idToken,
        );
      }
    }

    state = state.copyWith(loggedViewCardTypes: updatedLogged);
  }

  void logCardClick(RankedHomeCard card) {
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    apiClient.recordInteraction(
      cardType: card.cardType,
      action: 'click',
      cardId: card.id,
      idToken: idToken,
    );
  }

  void logCardDismiss(RankedHomeCard card) {
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    apiClient.recordInteraction(
      cardType: card.cardType,
      action: 'dismiss',
      cardId: card.id,
      idToken: idToken,
    );
  }
}

final homepageProvider = NotifierProvider<HomepageNotifier, HomepageState>(HomepageNotifier.new);
